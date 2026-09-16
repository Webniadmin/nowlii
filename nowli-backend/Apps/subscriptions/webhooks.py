"""Turning Stripe's account of what was paid into this app's account of who has access.

One handler per event, all of them idempotent, all of them driven by the ``Subscription``
row rather than replacing it. Stripe knows what was charged; it does not know about trials,
lifetime-free users, or the month index — those stay here.

**Order is not guaranteed.** Stripe delivers events concurrently and retries failures, so
``invoice.paid`` can arrive before ``checkout.session.completed``, and any event can arrive
twice. Every handler is written to be safe under both: they look the subscription up by the
ids Stripe carries, they never assume a previous event already ran, and ``StripeEvent``
drops a replay before a handler ever sees it.
"""

import logging
from datetime import datetime, timezone as dt_timezone

from django.contrib.auth import get_user_model
from django.db import IntegrityError, transaction
from django.utils import timezone

from . import services, stripe_gateway
from .models import StripeEvent, Subscription

log = logging.getLogger(__name__)
User = get_user_model()


# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────

def _as_date(epoch):
    """A Stripe unix timestamp as a date, or None.

    Stripe timestamps are UTC instants. This is a billing date, not a wall-clock moment in
    the user's day, so it is read in UTC deliberately — unlike quest dates, which belong to
    the user's own timezone (see Apps/users/timezones.py).
    """
    if not epoch:
        return None
    try:
        return datetime.fromtimestamp(int(epoch), tz=dt_timezone.utc).date()
    except (TypeError, ValueError, OSError):
        return None


def _period_end(stripe_subscription) -> int:
    """``current_period_end`` from a subscription object, wherever Stripe is keeping it.

    Recent API versions moved the field off the subscription and onto its items. Reading both
    means this keeps working across an API version bump instead of silently recording None.
    """
    if not stripe_subscription:
        return 0
    direct = stripe_subscription.get("current_period_end")
    if direct:
        return direct
    items = (stripe_subscription.get("items") or {}).get("data") or []
    for item in items:
        if item.get("current_period_end"):
            return item["current_period_end"]
    return 0


def _subscription_for(customer_id="", subscription_id="", user_id=""):
    """Find the local row this event is about, by the strongest identifier available.

    Tried in order of confidence: the Stripe subscription id (one purchase), the customer id
    (one person), then the user id Checkout echoed back. Returns None when the event is about
    somebody this backend has never heard of, which is normal on a shared Stripe account.
    """
    if subscription_id:
        found = Subscription.objects.filter(stripe_subscription_id=subscription_id).first()
        if found:
            return found
    if customer_id:
        found = Subscription.objects.filter(stripe_customer_id=customer_id).first()
        if found:
            return found
    if user_id:
        return Subscription.objects.filter(user_id=user_id).first()
    return None


# ─────────────────────────────────────────────
#  Handlers
# ─────────────────────────────────────────────

def handle_checkout_completed(obj):
    """A purchase went through: this is where a user becomes a paying subscriber.

    Sets the local row to ACTIVE, records the Stripe ids, and — for someone who has never
    paid — anchors ``started_at`` to today, which is what the whole price ladder is measured
    from. A returning subscriber keeps their original ``started_at``: they already earned
    their way down the ladder and must not be sold those months again.

    Then the rest of the ladder is attached as a schedule. If that call fails the purchase is
    still honoured — the user has access and has been charged — and the failure is logged
    loudly, because what is missing is the automatic step down to the cheaper price.
    """
    user_id = obj.get("client_reference_id") or ""
    customer_id = obj.get("customer") or ""
    stripe_sub_id = obj.get("subscription") or ""

    sub = _subscription_for(customer_id, stripe_sub_id, user_id)
    if sub is None and user_id:
        user = User.objects.filter(pk=user_id).first()
        if user is None:
            log.error("stripe webhook: checkout for unknown user %r", user_id)
            return
        sub, _ = Subscription.objects.get_or_create(user=user)
    if sub is None:
        log.error("stripe webhook: checkout %s matched no local subscription", obj.get("id"))
        return

    today = timezone.localdate()
    fields = []

    if customer_id and sub.stripe_customer_id != customer_id:
        sub.stripe_customer_id = customer_id
        fields.append("stripe_customer_id")
    if stripe_sub_id and sub.stripe_subscription_id != stripe_sub_id:
        sub.stripe_subscription_id = stripe_sub_id
        fields.append("stripe_subscription_id")
    if sub.platform != Subscription.Platform.STRIPE:
        sub.platform = Subscription.Platform.STRIPE
        fields.append("platform")
    # The paid year starts the day they actually pay, not the day their trial began.
    if sub.started_at is None:
        sub.started_at = today
        fields.append("started_at")
    # A lifetime-free user is left alone: they finished the year and must never be flipped
    # back to paying, whatever arrives from Stripe.
    if not sub.lifetime_free and sub.status != Subscription.Status.ACTIVE:
        sub.status = Subscription.Status.ACTIVE
        sub.cancelled_at = None
        fields += ["status", "cancelled_at"]

    if fields:
        sub.save(update_fields=fields + ["updated_at"])

    if stripe_sub_id and not sub.stripe_schedule_id:
        try:
            start_month = services.current_month_index(sub.started_at)
            schedule_id = stripe_gateway.attach_schedule(stripe_sub_id, start_month)
            sub.stripe_schedule_id = schedule_id
            sub.save(update_fields=["stripe_schedule_id", "updated_at"])
        except Exception:
            # Deliberately swallowed. The user paid and has access; what is lost is the
            # automatic step down, which is recoverable by hand from the schedule id in the
            # Stripe dashboard. Failing the webhook here would make Stripe retry an event
            # whose paid part already succeeded.
            log.exception(
                "stripe webhook: could not attach the price ladder to %s (user %s) — "
                "they are subscribed but will NOT step down automatically",
                stripe_sub_id, sub.user_id,
            )


def handle_invoice_paid(obj):
    """A renewal succeeded — including the ones at a lower price further down the ladder.

    Mostly this just refreshes the paid-through date and lifts a past-due flag. The step down
    itself needs nothing from us: Stripe's schedule already billed the new price.
    """
    sub = _subscription_for(obj.get("customer") or "", _invoice_subscription_id(obj))
    if sub is None:
        return

    fields = []
    period_end = _as_date(_period_end_from_invoice(obj))
    if period_end and sub.current_period_end != period_end:
        sub.current_period_end = period_end
        fields.append("current_period_end")
    if sub.status == Subscription.Status.PAST_DUE:
        sub.status = Subscription.Status.ACTIVE
        fields.append("status")
    if fields:
        sub.save(update_fields=fields + ["updated_at"])


def handle_invoice_payment_failed(obj):
    """A charge failed. Access is kept; Stripe is still retrying the card.

    Cards decline for reasons that clear themselves — a bank's fraud check, an expiry the
    user updates the next day. Stripe retries on a schedule and most of these recover, so
    revoking access on the first failure would lock out paying customers over a temporary
    decline. ``past_due`` records the trouble and access continues **to the end of the period
    they already paid for** and no further; ``services.compute_status`` is what enforces that
    date, so nothing here has to decide it.
    """
    sub = _subscription_for(obj.get("customer") or "", _invoice_subscription_id(obj))
    if sub is None or sub.lifetime_free:
        return
    if sub.status == Subscription.Status.ACTIVE:
        sub.status = Subscription.Status.PAST_DUE
        sub.save(update_fields=["status", "updated_at"])
        log.warning("stripe webhook: payment failed for user %s, retrying", sub.user_id)


def handle_subscription_updated(obj):
    """Keep the paid-through date and the Stripe ids in step with whatever Stripe now holds.

    Fires on renewals, plan changes the schedule makes, card updates and cancellations
    scheduled from the billing portal. It never grants or removes access on its own —
    entitlement is decided from ``started_at`` and ``status``, and the events that genuinely
    change those have their own handlers.
    """
    sub = _subscription_for(obj.get("customer") or "", obj.get("id") or "")
    if sub is None:
        return

    fields = []
    period_end = _as_date(_period_end(obj))
    if period_end and sub.current_period_end != period_end:
        sub.current_period_end = period_end
        fields.append("current_period_end")

    schedule_id = obj.get("schedule") or ""
    if schedule_id and sub.stripe_schedule_id != schedule_id:
        sub.stripe_schedule_id = schedule_id
        fields.append("stripe_schedule_id")

    # Whether the plan is set to stop at the end of the paid period. Tracked from Stripe
    # rather than from our own cancel endpoint so a cancellation made in the billing portal
    # — or undone there — shows up in the app too.
    pending_cancel = bool(obj.get("cancel_at_period_end"))
    if sub.cancel_at_period_end != pending_cancel:
        sub.cancel_at_period_end = pending_cancel
        fields.append("cancel_at_period_end")

    # Stripe's own past_due/unpaid states, mirrored so the admin shows the truth. Access is
    # unchanged — see handle_invoice_payment_failed for why.
    stripe_status = obj.get("status") or ""
    if (stripe_status in ("past_due", "unpaid")
            and not sub.lifetime_free
            and sub.status == Subscription.Status.ACTIVE):
        sub.status = Subscription.Status.PAST_DUE
        fields.append("status")
    elif (stripe_status == "active"
            and sub.status == Subscription.Status.PAST_DUE):
        sub.status = Subscription.Status.ACTIVE
        fields.append("status")

    if fields:
        sub.save(update_fields=fields + ["updated_at"])


def handle_subscription_deleted(obj):
    """The subscription ended. Which of two very different things that means is decided here.

    Finishing the ladder ends the subscription exactly like cancelling does — the schedule's
    ``end_behavior`` is ``cancel``, so Stripe deletes it on the last day of month 12. The
    difference is the month index: past ``FREE_AFTER_MONTH`` the user completed the year and
    has earned **lifetime-free access**, and this is the moment that is granted. Before it,
    they stopped paying and the plan lapses.

    A lapse is not a lockout. ``HasProAccessOrReadOnly`` keeps their history readable; what
    closes is what the subscription bought.
    """
    sub = _subscription_for(obj.get("customer") or "", obj.get("id") or "")
    if sub is None:
        return

    # Grants lifetime_free when they are past the paid year — the same rule the rest of the
    # app uses, kept in services so there is one definition of "finished".
    sub = services.sync_lifetime(sub)
    # Nothing is pending any more either way — the plan has ended.
    if sub.cancel_at_period_end:
        sub.cancel_at_period_end = False
        sub.save(update_fields=["cancel_at_period_end", "updated_at"])

    if sub.lifetime_free:
        log.info("stripe webhook: user %s finished the year — free forever", sub.user_id)
        return

    if sub.status != Subscription.Status.CANCELLED:
        sub.status = Subscription.Status.CANCELLED
        sub.cancelled_at = timezone.localdate()
        sub.save(update_fields=["status", "cancelled_at", "updated_at"])
        log.info("stripe webhook: subscription cancelled for user %s", sub.user_id)


def _invoice_subscription_id(invoice) -> str:
    """The subscription an invoice belongs to, across API versions.

    Older payloads carry it as ``subscription`` on the invoice; newer ones moved it onto the
    line items' ``parent``. Reading both keeps renewals attributable after a version bump.
    """
    direct = invoice.get("subscription")
    if isinstance(direct, str) and direct:
        return direct
    if isinstance(direct, dict) and direct.get("id"):
        return direct["id"]
    parent = invoice.get("parent") or {}
    details = parent.get("subscription_details") or {}
    if details.get("subscription"):
        return details["subscription"]
    for line in (invoice.get("lines") or {}).get("data") or []:
        line_parent = (line.get("parent") or {}).get("subscription_item_details") or {}
        if line_parent.get("subscription"):
            return line_parent["subscription"]
    return ""


def _period_end_from_invoice(invoice) -> int:
    """The end of the period an invoice paid for."""
    for line in (invoice.get("lines") or {}).get("data") or []:
        period = line.get("period") or {}
        if period.get("end"):
            return period["end"]
    return invoice.get("period_end") or 0


HANDLERS = {
    "checkout.session.completed": handle_checkout_completed,
    "invoice.paid": handle_invoice_paid,
    "invoice.payment_succeeded": handle_invoice_paid,
    "invoice.payment_failed": handle_invoice_payment_failed,
    "customer.subscription.updated": handle_subscription_updated,
    "customer.subscription.deleted": handle_subscription_deleted,
}


def dispatch(event) -> str:
    """Apply one verified Stripe event. Returns what was done, for the response body.

    The ``StripeEvent`` insert is the idempotency guard and it happens FIRST: Stripe retries
    until it gets a 2xx and is explicit that an event can be delivered more than once, and
    every handler below writes something that must not be applied twice.
    """
    event_id = event.get("id") or ""
    event_type = event.get("type") or ""

    try:
        # Wrapped in its own atomic block so the duplicate-key error is rolled back to a
        # savepoint. Without it the failed INSERT leaves the surrounding transaction broken
        # and every query after it raises — a replay would take down the request that was
        # supposed to shrug it off.
        with transaction.atomic():
            StripeEvent.objects.create(event_id=event_id, event_type=event_type)
    except IntegrityError:
        log.info("stripe webhook: %s (%s) already applied — ignoring replay",
                 event_id, event_type)
        return "duplicate"

    handler = HANDLERS.get(event_type)
    if handler is None:
        return "ignored"

    handler((event.get("data") or {}).get("object") or {})
    return "applied"
