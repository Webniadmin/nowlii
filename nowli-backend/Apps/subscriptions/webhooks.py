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

import json
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
    # Stripe's date for the session, not the day this webhook happened to be processed: a
    # delivery that lands after midnight UTC, or a retry hours later, would otherwise start
    # the year a day after Stripe's billing anchor.
    if sub.started_at is None:
        sub.started_at = _as_date(obj.get("created")) or today
        fields.append("started_at")
    # A lifetime-free user is left alone: they finished the year and must never be flipped
    # back to paying, whatever arrives from Stripe.
    if not sub.lifetime_free and sub.status != Subscription.Status.ACTIVE:
        sub.status = Subscription.Status.ACTIVE
        sub.cancelled_at = None
        fields += ["status", "cancelled_at"]

    if fields:
        sub.save(update_fields=fields + ["updated_at"])

    if stripe_sub_id:
        _ensure_ladder(sub, stripe_sub_id)


def _ensure_ladder(sub, stripe_sub_id):
    """Make sure this subscription is wrapped in the price ladder; heal it if not.

    Called on purchase and again on every paid invoice. ``attach_schedule`` is idempotent —
    a finished ladder costs two reads and nothing else — so a ladder that failed to attach at
    checkout (a Stripe outage, a half-built schedule) repairs itself at the next renewal
    instead of billing the first rung forever.

    Failures are swallowed on purpose. The user paid and has access; what would be lost is
    the automatic step down, and failing the webhook would roll back the access instead.
    """
    # A pending cancel released the schedule on purpose; resume() re-attaches it.
    if sub.lifetime_free or sub.started_at is None or sub.cancel_at_period_end:
        return
    try:
        start_month = services.current_month_index(sub.started_at)
        schedule_id = stripe_gateway.attach_schedule(stripe_sub_id, start_month)
    except Exception:
        log.exception(
            "stripe webhook: could not attach the price ladder to %s (user %s) — "
            "they are subscribed but will NOT step down until this succeeds",
            stripe_sub_id, sub.user_id,
        )
        return
    if sub.stripe_schedule_id != schedule_id:
        sub.stripe_schedule_id = schedule_id
        sub.save(update_fields=["stripe_schedule_id", "updated_at"])


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
    # Only an invoice that pays *past* what is already paid moves anything. Events arrive out
    # of order: a late invoice.paid for last month must neither pull the date back nor clear
    # a past_due that belongs to this month's declined charge — ACTIVE has no end date, so
    # that would have been access for good.
    newer = period_end is not None and (sub.current_period_end is None
                                        or period_end > sub.current_period_end)
    if newer:
        sub.current_period_end = period_end
        fields.append("current_period_end")
        if sub.status == Subscription.Status.PAST_DUE:
            sub.status = Subscription.Status.ACTIVE
            fields.append("status")
    if fields:
        sub.save(update_fields=fields + ["updated_at"])

    sub_id = _invoice_subscription_id(obj)
    if sub_id and sub.platform == Subscription.Platform.STRIPE:
        _ensure_ladder(sub, sub_id)


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
    # Deliberately NOT current_period_end. Stripe rolls the period forward at renewal whether
    # or not the charge succeeds, so reading it here turned a declined card into a free extra
    # month of "grace". The paid-through date comes from invoice.paid alone.
    if sub.current_period_end is None:
        period_end = _as_date(_period_end(obj))
        if period_end:
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
    ``end_behavior`` is ``cancel``, so Stripe deletes it on the last day of month 12. What
    tells them apart is **Stripe's own record**: our ladder schedule reports ``completed``.
    That user paid the whole year and earns lifetime-free access, here. Anything else is a
    cancel or a failed card, and the plan lapses.

    Not the month index. That counts calendar days from ``started_at``, so it disagrees with
    Stripe by a day whenever the webhook that set ``started_at`` was processed after midnight
    UTC — and on the anniversary a full year's customer would be cancelled instead of freed.

    A lapse is not a lockout. ``HasProAccessOrReadOnly`` keeps their history readable; what
    closes is what the subscription bought.
    """
    sub = _subscription_for(obj.get("customer") or "", obj.get("id") or "")
    if sub is None:
        return

    schedule_id = obj.get("schedule") or sub.stripe_schedule_id
    if not sub.lifetime_free and schedule_id and stripe_gateway.ladder_completed(schedule_id):
        sub.lifetime_free = True
        sub.status = Subscription.Status.LIFETIME_FREE
        sub.save(update_fields=["lifetime_free", "status", "updated_at"])
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
    # `stripe.Webhook.construct_event` hands back a `stripe.Event`, not a dict, and since
    # stripe-python 15 a StripeObject is no longer a mapping — `.get()` on one raises
    # AttributeError, which means every real delivery 500s while a hand-built dict works
    # fine. Round-tripping through JSON is what gives plain dicts all the way down;
    # `.to_dict()` is shallow and the handlers below read nested fields.
    if not isinstance(event, dict):
        event = json.loads(str(event))

    event_id = event.get("id") or ""
    event_type = event.get("type") or ""

    # The record and the handler commit together. If the handler raises, the record rolls
    # back with it and Stripe's retry is processed, not dropped as a replay — otherwise one
    # transient failure on checkout.session.completed leaves a customer charged and never
    # granted access.
    with transaction.atomic():
        try:
            # Its own savepoint, so a duplicate-key error does not break the outer
            # transaction and take down the request that was supposed to shrug it off.
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
