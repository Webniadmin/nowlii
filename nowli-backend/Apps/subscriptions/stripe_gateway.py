"""Every call this project makes to Stripe, in one place.

Nothing else in the codebase imports ``stripe``. Keeping the SDK behind this module means
the price ladder is built in exactly one function, the "is Stripe even configured" question
is answered in exactly one place, and the rest of the app deals in our own vocabulary
(phases, stages, months) rather than Stripe's.

**The ladder is a subscription schedule.** NOWLII's monthly price steps down four times over
a year and then the app is free forever. Stripe expresses that natively: a schedule is an
ordered list of phases, each with its own price and a duration in months, and when
the last phase ends the subscription simply stops. That final stop is what the backend reads
as "they finished the year" and turns into lifetime-free access.

The store path could not do this — a Google Play offer carries at most two pricing phases,
an Apple introductory offer one, and neither store has a server-side plan change, so every
step down would have depended on the user opening the app. See docs/stripe-payments.md.
"""

import json
import logging

import stripe
from django.conf import settings

from . import config, services

log = logging.getLogger(__name__)

# The product every price belongs to. Stripe groups prices under a product; one product with
# four prices is the shape that lets a schedule move between them.
PRODUCT_NAME = "NOWLII Pro"
PRODUCT_LOOKUP_KEY = "nowlii_pro"
# Set on a schedule once it holds the whole ladder — how attach_schedule tells a finished
# ladder from the one-phase schedule a failed attach leaves behind.
LADDER_MARKER = "nowlii_ladder"
# Set on a Checkout-created subscription: the ladder month that purchase was sold as.
START_MONTH_KEY = "nowlii_start_month"


class StripeNotConfigured(RuntimeError):
    """Raised when a Stripe call is attempted without keys.

    Deployments without keys are expected (a fresh checkout, CI, a dev box that never pays),
    so this is caught at the view boundary and turned into a 503 rather than a 500. The app
    shows "checkout unavailable"; nothing else about the backend is affected.
    """


def is_configured() -> bool:
    return bool(settings.STRIPE_SECRET_KEY)


def _client():
    if not is_configured():
        raise StripeNotConfigured("STRIPE_SECRET_KEY is not set.")
    stripe.api_key = settings.STRIPE_SECRET_KEY
    return stripe


# ─────────────────────────────────────────────
#  Prices
# ─────────────────────────────────────────────

def price_id_for_phase(phase: dict) -> str:
    """The Stripe price id for one rung of ``config.PHASES``.

    The id lives in settings (so test and live keys can point at different prices without a
    code change) but *which* setting is named by the phase itself, so the ladder is still
    described in one file.
    """
    name = phase.get("stripe_price_env", "")
    if not name:
        raise StripeNotConfigured(
            f"Phase {phase.get('stage')!r} has no stripe_price_env in config.PHASES."
        )
    value = getattr(settings, name, "")
    if not value:
        raise StripeNotConfigured(
            f"{name} is not set — run `manage.py sync_stripe_prices` and put the id in .env."
        )
    return value


def rung_for_month(month_index: int) -> dict:
    """The raw ``config.PHASES`` entry covering a 1-based billing month.

    Deliberately not ``services.phase_for_month``: that one returns a *derived* view shaped
    for the API (no ``stripe_price_env``, and a synthetic free stage past month 12). Pricing
    a checkout needs the real entry, price id and all.
    """
    for phase in config.PHASES:
        if phase["from_month"] <= month_index <= phase["to_month"]:
            return phase
    raise StripeNotConfigured(
        f"Month {month_index} is past the paid ladder — this user has nothing to buy."
    )


def missing_price_settings() -> list:
    """Which price settings are still blank. Empty list means checkout can run."""
    missing = []
    for phase in config.PHASES:
        name = phase.get("stripe_price_env", "")
        if not name or not getattr(settings, name, ""):
            missing.append(name or f"<unnamed:{phase.get('stage')}>")
    return missing


def schedule_phases(start_month: int = 1) -> list:
    """The price ladder from ``start_month`` onward, as Stripe schedule phases.

    One phase per rung, each billing monthly for as many months as the rung still has left.
    There is deliberately no phase for Graduated: Stripe has no $0 renewing subscription, and
    does not need one — the schedule ends, the subscription cancels, and access after that
    comes from our own ``lifetime_free`` flag rather than from anything Stripe holds.

    ``start_month`` is what makes a returning subscriber work. Someone who paid for five
    months, lapsed, and came back has already earned their way down to Rhythm; restarting
    them at Spark would charge them $19.99 while every screen in the app says $14.99, and
    would quietly re-sell them months they already bought. So the schedule begins at the rung
    they are actually on, with that rung's remaining months, and runs to the end as usual.
    """
    phases = []
    for phase in config.PHASES:
        last = phase["to_month"]
        if last < start_month:
            continue                       # rung already behind them
        first = max(phase["from_month"], start_month)
        months = last - first + 1
        if months <= 0:
            continue
        # `duration`, not `iterations`: the API version this SDK pins (2026-08-26.dahlia)
        # rejects `iterations` outright, and a rejected schedule means the customer is billed
        # the first rung forever. Found only against the real test API — mocks accept anything.
        phases.append({
            "items": [{"price": price_id_for_phase(phase), "quantity": 1}],
            "duration": {"interval": "month", "interval_count": months},
        })
    return phases


def start_month_for(subscription) -> int:
    """Which rung of the ladder this user should be sold next, 1-based.

    **Months paid + 1** — never months since they first paid. Someone who paid for five
    months, lapsed and came back is sold month 6 (Rhythm), however long they were away;
    counting the calendar instead sold a one-month customer the $9.99 rung half a year later.
    Mock-era rows have no paid months, so they start at 1: nothing was ever paid for.
    Clamped to the last paid rung: past that they are lifetime-free and have nothing to buy.
    """
    if subscription is None:
        return 1
    return max(1, min(services.months_paid(subscription) + 1, config.FREE_AFTER_MONTH))


def current_ladder_month(subscription) -> int:
    """The rung the *running* period belongs to — the last month paid for."""
    return max(1, min(services.months_paid(subscription), config.FREE_AFTER_MONTH))


# ─────────────────────────────────────────────
#  Customers
# ─────────────────────────────────────────────

def get_or_create_customer(user, subscription=None) -> str:
    """The user's Stripe customer id, creating one on first use.

    Reused across purchases on purpose: someone who cancels and subscribes again keeps their
    saved card and their invoice history, and support can find one customer rather than three.
    """
    client = _client()
    existing = getattr(subscription, "stripe_customer_id", "") if subscription else ""
    if existing:
        return existing

    customer = client.Customer.create(
        email=getattr(user, "email", "") or None,
        name=(getattr(user, "get_full_name", lambda: "")() or getattr(user, "username", "")),
        # The link back from a Stripe dashboard row to a row in our database. Webhooks use
        # client_reference_id instead; this is for humans reading the dashboard.
        metadata={"user_id": str(user.pk), "username": getattr(user, "username", "")},
    )
    if subscription is not None:
        subscription.stripe_customer_id = customer.id
        subscription.save(update_fields=["stripe_customer_id", "updated_at"])
    return customer.id


# ─────────────────────────────────────────────
#  Checkout
# ─────────────────────────────────────────────

def create_checkout_session(user, subscription, success_url="", cancel_url="") -> str:
    """Start a purchase and return the hosted Checkout URL for the app to open.

    Only ONE rung is sold here — the one this user is due, which is the first for a new
    subscriber and wherever they left off for a returning one. Checkout creates a plain
    subscription; the rest of the ladder is attached as a schedule when the
    ``checkout.session.completed`` webhook arrives (see ``attach_schedule``). Stripe does not
    accept a schedule directly in a Checkout Session, and doing it in the webhook has the
    useful property that the ladder is only ever built around a subscription that really
    exists and was really paid for.
    """
    client = _client()
    month = start_month_for(subscription)
    rung = rung_for_month(month)
    customer_id = get_or_create_customer(user, subscription)

    session = client.checkout.Session.create(
        mode="subscription",
        customer=customer_id,
        line_items=[{"price": price_id_for_phase(rung), "quantity": 1}],
        success_url=success_url or settings.STRIPE_SUCCESS_URL,
        cancel_url=cancel_url or settings.STRIPE_CANCEL_URL,
        # How the webhook finds the user. It is echoed on the completed session, so the
        # handler never has to guess from an email address.
        client_reference_id=str(user.pk),
        subscription_data={
            # START_MONTH_KEY travels with the subscription so the webhook attaches the
            # ladder from the rung actually sold, whatever order Stripe's events arrive in.
            "metadata": {"user_id": str(user.pk), "username": getattr(user, "username", ""),
                         START_MONTH_KEY: str(month)},
        },
        # The trial is ours, not Stripe's: it is granted on first login with no card at all,
        # and someone reaching checkout is choosing to start paying now. Handing Stripe a
        # second trial would give the same person 14 free days.
        allow_promotion_codes=True,
    )
    log.info("stripe: checkout session %s for user %s", session.id, user.pk)
    return session.url


def attach_schedule(stripe_subscription_id: str, start_month: int = None) -> str:
    """Wrap a freshly bought subscription in the full price ladder. Returns the schedule id.

    ``from_subscription`` creates a schedule whose single phase mirrors what the user just
    bought; the update then replaces the phase list with the whole ladder. The first phase
    must keep the price and start date Stripe already billed, so it is taken from the
    existing schedule rather than rebuilt — changing it would re-bill the customer.

    ``end_behavior="cancel"`` is the free-forever step: when the last paid phase finishes,
    Stripe cancels the subscription, the ``customer.subscription.deleted`` webhook arrives,
    and the backend sees a user past month 12 and grants lifetime access.

    **Idempotent, and that matters.** Creating the schedule and filling it are two calls; if
    the second fails, the subscription is left owned by a one-phase schedule and a plain
    ``create(from_subscription=…)`` refuses forever after ("already attached to a schedule").
    So an existing schedule is reused and finished, and a finished one — marked in its
    metadata — is returned untouched. That is what lets a retry, a Dashboard "resend", or the
    next ``invoice.paid`` heal a ladder that failed to attach.
    """
    client = _client()
    live = _plain(client.Subscription.retrieve(stripe_subscription_id))
    if start_month is None:
        # The rung Checkout sold, recorded on the subscription when the session was made.
        start_month = int((live.get("metadata") or {}).get(START_MONTH_KEY) or 1)
    existing = live.get("schedule")
    if isinstance(existing, dict):
        existing = existing.get("id")
    if existing:
        schedule = client.SubscriptionSchedule.retrieve(existing)
        plain = _plain(schedule)
        if (plain.get("metadata") or {}).get(LADDER_MARKER) and plain.get("end_behavior") == "cancel":
            return schedule.id                      # already the full ladder
    else:
        schedule = client.SubscriptionSchedule.create(from_subscription=stripe_subscription_id)

    phases = schedule_phases(start_month)
    # SDK objects are not dicts (since stripe-python 13 `.get` raises), so read plain data.
    current = (_plain(schedule).get("phases") or [{}])[0]
    # Phase 0 is already running and billed. Keep Stripe's own start/end for it and only
    # carry over our item list, which is the same first rung anyway.
    first = dict(phases[0])
    if current.get("start_date"):
        first["start_date"] = current["start_date"]

    updated = client.SubscriptionSchedule.modify(
        schedule.id,
        end_behavior="cancel",
        phases=[first] + phases[1:],
        metadata={LADDER_MARKER: "1"},
    )
    log.info(
        "stripe: schedule %s attached to %s (%d phases)",
        updated.id, stripe_subscription_id, len(phases),
    )
    return updated.id


def ladder_completed(schedule_id: str) -> bool:
    """Did this schedule run our whole ladder to the end? The lifetime-free signal.

    ``completed`` is Stripe's word for a schedule whose last phase finished. A user who
    cancelled has a *released* or *canceled* schedule instead, so this cannot be reached by
    paying once and waiting. The marker rules out any other schedule on the account.
    """
    plain = _plain(_client().SubscriptionSchedule.retrieve(schedule_id))
    return (plain.get("status") == "completed"
            and bool((plain.get("metadata") or {}).get(LADDER_MARKER)))


# ─────────────────────────────────────────────
#  Managing an existing subscription
# ─────────────────────────────────────────────

def create_portal_session(subscription, return_url="") -> str:
    """A Stripe-hosted page where the user updates their card, sees invoices, or cancels.

    Everything in here is Stripe's own UI, which means card details never touch this backend
    and the "cancel" the user performs is the real one rather than a flag we set and hope
    matches what they are still being charged.
    """
    client = _client()
    if not subscription or not subscription.stripe_customer_id:
        raise StripeNotConfigured("This user has no Stripe customer on file.")
    session = client.billing_portal.Session.create(
        customer=subscription.stripe_customer_id,
        return_url=return_url or settings.STRIPE_SUCCESS_URL,
    )
    return session.url


def cancel_at_period_end(subscription) -> dict:
    """Stop the subscription when the paid period runs out — not this instant.

    The user has already paid for the month in progress. Taking access away the moment they
    click cancel keeps their money and removes what it bought, which is both unfair and the
    fastest route to a chargeback. So the plan runs to the end of the period and then stops.

    The schedule is released first: a schedule owns the subscription's future, so cancelling
    underneath one leaves Stripe holding a plan for a subscription that is ending.
    """
    client = _client()
    if not subscription.stripe_subscription_id:
        raise StripeNotConfigured("This user has no Stripe subscription on file.")

    if subscription.stripe_schedule_id:
        try:
            client.SubscriptionSchedule.release(subscription.stripe_schedule_id)
        except stripe.StripeError as exc:          # already released, or already ended
            log.warning("stripe: could not release schedule %s: %s",
                        subscription.stripe_schedule_id, exc)

    sub = client.Subscription.modify(
        subscription.stripe_subscription_id,
        cancel_at_period_end=True,
    )
    return {"cancel_at_period_end": True, "current_period_end": _current_period_end(sub)}


def resume(subscription) -> dict:
    """Undo a pending cancellation while the period is still running."""
    client = _client()
    if not subscription.stripe_subscription_id:
        raise StripeNotConfigured("This user has no Stripe subscription on file.")
    sub = client.Subscription.modify(
        subscription.stripe_subscription_id,
        cancel_at_period_end=False,
    )
    # cancel_at_period_end() released the ladder; without re-attaching it, someone who
    # cancels and changes their mind is billed today's rung for as long as they stay.
    try:
        schedule_id = attach_schedule(subscription.stripe_subscription_id,
                                      current_ladder_month(subscription))
        if subscription.stripe_schedule_id != schedule_id:
            subscription.stripe_schedule_id = schedule_id
            subscription.save(update_fields=["stripe_schedule_id", "updated_at"])
    except stripe.StripeError:
        log.exception("stripe: resumed %s but could not re-attach the ladder",
                      subscription.stripe_subscription_id)
    return {"cancel_at_period_end": False, "current_period_end": _current_period_end(sub)}


def _plain(obj) -> dict:
    """A Stripe SDK object as plain nested dicts; dicts (test doubles) pass through.

    JSON round-trip, not ``.to_dict()``: that one is shallow, and nested objects would
    still raise on ``.get`` (same reasoning as ``webhooks.dispatch``).
    """
    if isinstance(obj, dict):
        return obj
    return json.loads(str(obj))


def _current_period_end(stripe_subscription) -> int:
    """Paid-through timestamp, wherever this API version keeps it (see webhooks._period_end)."""
    from .webhooks import _period_end        # webhooks imports this module; avoid the cycle
    return _period_end(_plain(stripe_subscription))


def construct_event(payload: bytes, signature: str):
    """Verify a webhook's signature and return the parsed event.

    Raises ``ValueError`` on a malformed body and ``stripe.SignatureVerificationError`` when
    the signature does not match. Both must stay fatal: this endpoint grants paid access, so
    an unverified request is an attacker handing themselves a subscription.
    """
    if not settings.STRIPE_WEBHOOK_SECRET:
        raise StripeNotConfigured("STRIPE_WEBHOOK_SECRET is not set.")
    return stripe.Webhook.construct_event(
        payload, signature, settings.STRIPE_WEBHOOK_SECRET
    )
