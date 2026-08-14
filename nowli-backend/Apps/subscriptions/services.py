"""
Pure lifecycle logic: given a subscription's start date, derive the current billing month,
the active price phase, and the lifetime-free transition. Store-agnostic — the same engine
serves mock (Phase 1) and real IAP/Play billing (Phase 2).

Access has two independent sources: the **free trial** (granted once, on first contact with
the API) and a **paid/lifetime-free subscription**. ``user_has_pro`` is the single entitlement
check other apps should use — it covers both.
"""
from datetime import date, timedelta

from django.utils import timezone

from . import config


def _months_elapsed(start: date, ref: date) -> int:
    """Whole calendar-months from ``start`` to ``ref`` (0 on/within the first month)."""
    months = (ref.year - start.year) * 12 + (ref.month - start.month)
    if ref.day < start.day:
        months -= 1
    return max(0, months)


def current_month_index(start: date, ref: date = None) -> int:
    """1-based billing month: month 1 is the first month starting at ``start``."""
    ref = ref or timezone.localdate()
    return _months_elapsed(start, ref) + 1


def phase_for_month(month_index: int) -> dict:
    """Return ``{phase, price, is_free, google_base_plan, apple_product}`` for a 1-based
    billing-month index. The product ids are empty for the free stage, which no store sells.
    """
    if month_index > config.FREE_AFTER_MONTH:
        return {"phase": "free", "price": 0.0, "is_free": True,
                "stage": config.GRADUATED_STAGE,
                "google_base_plan": "", "apple_product": ""}
    for p in config.PHASES:
        if p["from_month"] <= month_index <= p["to_month"]:
            return {
                "phase": f"{p['from_month']}-{p['to_month']}",
                "price": float(p["price"]),
                "is_free": False,
                "stage": p.get("stage", ""),
                "google_base_plan": p.get("google_base_plan", ""),
                "apple_product": p.get("apple_product", ""),
            }
    # Outside the defined ranges → treat as free (defensive; shouldn't normally happen).
    return {"phase": "free", "price": 0.0, "is_free": True,
            "stage": config.GRADUATED_STAGE,
            "google_base_plan": "", "apple_product": ""}


def store_product_for_month(month_index: int, platform: str) -> str:
    """The store product that should be billing a subscriber in ``month_index``.

    Empty string once the schedule reaches the free stage — there is no product to move to,
    the subscription is cancelled instead.
    """
    phase = phase_for_month(month_index)
    if platform == "apple":
        return phase["apple_product"]
    if platform == "google":
        return phase["google_base_plan"]
    return ""


def step_down_due(subscription, ref: date = None) -> dict:
    """Is this subscriber being billed more than the schedule says they should be?

    This exists because **neither store lets a server move a subscriber to a cheaper plan**.
    The price ladder is four separate store products, and the change from one to the next can
    only be initiated from the device. So the backend's job is to notice the gap and the
    app's job is to close it the next time the user opens it.

    ``cancel`` is the end of the ladder: past the last paid month there is nothing to move to
    and the store subscription should simply be cancelled, after which access comes from
    ``lifetime_free`` alone.

    Returns ``due=False`` for anyone the question does not apply to — trial-only, mock
    platform, lifetime-free, or already on the right product.
    """
    ref = ref or timezone.localdate()
    if subscription is None or subscription.started_at is None:
        return {"due": False, "cancel": False, "from_product": "", "to_product": "",
                "to_price": 0.0}
    if subscription.platform not in ("apple", "google"):
        return {"due": False, "cancel": False, "from_product": "", "to_product": "",
                "to_price": 0.0}

    idx = current_month_index(subscription.started_at, ref)
    expected = store_product_for_month(idx, subscription.platform)
    billed = subscription.store_product_id

    # Past the ladder: cancel rather than switch. Only meaningful while a store subscription
    # is still on file — once it is cancelled there is nothing left to ask the app to do.
    if idx > config.FREE_AFTER_MONTH:
        return {
            "due": False,
            "cancel": bool(billed),
            "from_product": billed,
            "to_product": "",
            "to_price": 0.0,
        }

    if not billed or billed == expected:
        return {"due": False, "cancel": False, "from_product": billed,
                "to_product": "", "to_price": 0.0}

    return {
        "due": True,
        "cancel": False,
        "from_product": billed,
        "to_product": expected,
        "to_price": phase_for_month(idx)["price"],
    }


def phase_schedule() -> dict:
    """The full public pricing schedule (for the paywall UI)."""
    return {
        "currency": config.CURRENCY,
        "free_after_month": config.FREE_AFTER_MONTH,
        "graduated_stage": config.GRADUATED_STAGE,
        "phases": [
            {
                "from_month": p["from_month"],
                "to_month": p["to_month"],
                "price": float(p["price"]),
                # The paywall labels each step; serving the names keeps the app from
                # keeping its own copy that can drift from the schedule.
                "stage": p.get("stage", ""),
            }
            for p in config.PHASES
        ],
    }


def sync_step_down_state(subscription, ref: date = None):
    """Record when a subscriber first fell behind the price ladder, and clear it when they
    catch up. Idempotent; the date is the *first* day the gap was seen, not the latest.

    Kept separate from ``step_down_due`` so the read stays pure — this is the one that
    writes, and it is called from the status endpoint the app hits anyway.
    """
    ref = ref or timezone.localdate()
    if subscription is None:
        return subscription

    due = step_down_due(subscription, ref)["due"]
    if due and subscription.step_down_pending_since is None:
        subscription.step_down_pending_since = ref
        subscription.save(update_fields=["step_down_pending_since", "updated_at"])
    elif not due and subscription.step_down_pending_since is not None:
        subscription.step_down_pending_since = None
        subscription.save(update_fields=["step_down_pending_since", "updated_at"])
    return subscription


def sync_lifetime(subscription, ref: date = None):
    """Persist the lifetime-free transition once the user passes ``FREE_AFTER_MONTH``.

    Idempotent: only writes on the first crossing. Returns the (possibly updated) instance.
    """
    ref = ref or timezone.localdate()
    if subscription.started_at is None:
        return subscription          # trial-only: the paid year hasn't started counting
    idx = current_month_index(subscription.started_at, ref)
    if idx > config.FREE_AFTER_MONTH and not subscription.lifetime_free:
        subscription.lifetime_free = True
        subscription.status = subscription.Status.LIFETIME_FREE
        subscription.save(update_fields=["lifetime_free", "status", "updated_at"])
    return subscription


# ─────────────────────────────────────────────
#  Free trial
# ─────────────────────────────────────────────

def trial_status(subscription, ref: date = None) -> dict:
    """Derive the trial state: ``{in_trial, trial_days_left, trial_ends_at, trial_used}``.

    The trial ends at the START of day ``trial_started_at + TRIAL_DAYS`` — i.e. a 7-day trial
    begun on the 1st covers the 1st through the 7th and is over on the 8th.
    """
    ref = ref or timezone.localdate()
    start = subscription.trial_started_at if subscription else None
    if start is None:
        return {"in_trial": False, "trial_days_left": 0,
                "trial_ends_at": None, "trial_used": False}

    ends_at = start + timedelta(days=config.TRIAL_DAYS)
    days_left = (ends_at - ref).days
    return {
        "in_trial": days_left > 0,
        "trial_days_left": max(0, days_left),
        "trial_ends_at": ends_at,
        "trial_used": True,
    }


def start_trial(user, ref: date = None):
    """Grant the free trial — idempotent, and only ever once per user.

    Called lazily the first time a logged-in user touches the API, so a fresh install +
    login starts the clock with no extra step. A user who already has a subscription row
    (trial used, paid, cancelled) keeps it untouched: the trial is never re-granted.

    Returns the user's ``Subscription`` (created here when this is their first contact).
    """
    from .models import Subscription  # local import: avoids an app-registry cycle

    ref = ref or timezone.localdate()
    sub = getattr(user, "subscription", None)
    if sub is not None:
        return sub
    if config.TRIAL_DAYS <= 0:
        return None

    sub, _created = Subscription.objects.get_or_create(
        user=user,
        defaults={
            "started_at": None,                       # paid schedule hasn't begun
            "trial_started_at": ref,
            "status": Subscription.Status.TRIAL,
            "platform": Subscription.Platform.MOCK,
        },
    )
    return sub


def sync_trial_expiry(subscription, ref: date = None):
    """Flip a finished trial to EXPIRED once, so the DB reflects reality.

    Idempotent, and only touches rows still sitting in TRIAL — a user who subscribed during
    their trial is ACTIVE and must not be knocked back.
    """
    if subscription is None or subscription.status != subscription.Status.TRIAL:
        return subscription
    if not trial_status(subscription, ref)["in_trial"]:
        subscription.status = subscription.Status.EXPIRED
        subscription.save(update_fields=["status", "updated_at"])
    return subscription


# ─────────────────────────────────────────────
#  Combined status + entitlement
# ─────────────────────────────────────────────

def compute_status(subscription, ref: date = None) -> dict:
    """Derive the live status for a subscription (pure; does not save)."""
    ref = ref or timezone.localdate()
    trial = trial_status(subscription, ref)

    # A trial-only subscription has no paid start date yet, so there is no billing month to
    # report. Month 1 / the first phase price is what they'd pay if they subscribed today.
    paid_started = subscription.started_at is not None
    idx = current_month_index(subscription.started_at, ref) if paid_started else 1
    this_phase = phase_for_month(idx)
    next_phase = phase_for_month(idx + 1)

    is_free = paid_started and this_phase["is_free"]
    # Access comes from an active trial, lifetime-free/currently-free, or an active paid sub.
    has_access = (
        trial["in_trial"]
        or subscription.lifetime_free
        or is_free
        or subscription.status == subscription.Status.ACTIVE
    )
    # `in_trial` means "access is coming FROM the trial" — someone who subscribes on day 3
    # is a paying customer, so the app must stop showing them a trial countdown even though
    # the original 7-day window hasn't elapsed.
    on_trial = (
        trial["in_trial"]
        and not subscription.lifetime_free
        and subscription.status != subscription.Status.ACTIVE
    )
    return {
        "month_index": idx if paid_started else 0,
        "phase": this_phase["phase"],
        "current_price": this_phase["price"],
        "is_free": is_free,
        "next_price": next_phase["price"],
        "lifetime_free": subscription.lifetime_free or is_free,
        "status": subscription.status,
        "has_access": has_access,
        "in_trial": on_trial,
        "trial_days_left": trial["trial_days_left"] if on_trial else 0,
        "trial_ends_at": trial["trial_ends_at"],
        "trial_used": trial["trial_used"],
    }


def user_has_pro(user, ref: date = None) -> bool:
    """The single entitlement check — covers trial, paid and lifetime-free access.

    Grants (and starts) the trial on first contact, so a brand-new user is entitled without
    any explicit step. Also persists the trial→expired and paid→lifetime-free transitions.
    """
    sub = getattr(user, "subscription", None)
    if sub is None:
        sub = start_trial(user, ref)
        if sub is None:                # trials disabled and no subscription → no access
            return False
    sub = sync_trial_expiry(sub, ref)
    sub = sync_lifetime(sub, ref)
    return compute_status(sub, ref)["has_access"]
