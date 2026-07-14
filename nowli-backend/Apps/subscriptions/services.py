"""
Pure lifecycle logic: given a subscription's start date, derive the current billing month,
the active price phase, and the lifetime-free transition. Store-agnostic — the same engine
serves mock (Phase 1) and real IAP/Play billing (Phase 2).
"""
from datetime import date

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
    """Return ``{phase, price, is_free}`` for a 1-based billing-month index."""
    if month_index > config.FREE_AFTER_MONTH:
        return {"phase": "free", "price": 0.0, "is_free": True}
    for p in config.PHASES:
        if p["from_month"] <= month_index <= p["to_month"]:
            return {
                "phase": f"{p['from_month']}-{p['to_month']}",
                "price": float(p["price"]),
                "is_free": False,
            }
    # Outside the defined ranges → treat as free (defensive; shouldn't normally happen).
    return {"phase": "free", "price": 0.0, "is_free": True}


def phase_schedule() -> dict:
    """The full public pricing schedule (for the paywall UI)."""
    return {
        "currency": config.CURRENCY,
        "free_after_month": config.FREE_AFTER_MONTH,
        "phases": [
            {
                "from_month": p["from_month"],
                "to_month": p["to_month"],
                "price": float(p["price"]),
            }
            for p in config.PHASES
        ],
    }


def sync_lifetime(subscription, ref: date = None):
    """Persist the lifetime-free transition once the user passes ``FREE_AFTER_MONTH``.

    Idempotent: only writes on the first crossing. Returns the (possibly updated) instance.
    """
    ref = ref or timezone.localdate()
    idx = current_month_index(subscription.started_at, ref)
    if idx > config.FREE_AFTER_MONTH and not subscription.lifetime_free:
        subscription.lifetime_free = True
        subscription.status = subscription.Status.LIFETIME_FREE
        subscription.save(update_fields=["lifetime_free", "status", "updated_at"])
    return subscription


def compute_status(subscription, ref: date = None) -> dict:
    """Derive the live status for a subscription (pure; does not save)."""
    ref = ref or timezone.localdate()
    idx = current_month_index(subscription.started_at, ref)
    this_phase = phase_for_month(idx)
    next_phase = phase_for_month(idx + 1)

    is_free = this_phase["is_free"]
    # Access: lifetime-free / currently-free, or an active paid subscription.
    has_access = (
        subscription.lifetime_free
        or is_free
        or subscription.status == subscription.Status.ACTIVE
    )
    return {
        "month_index": idx,
        "phase": this_phase["phase"],
        "current_price": this_phase["price"],
        "is_free": is_free,
        "next_price": next_phase["price"],
        "lifetime_free": subscription.lifetime_free or is_free,
        "status": subscription.status,
        "has_access": has_access,
    }


def user_has_pro(user, ref: date = None) -> bool:
    """Entitlement check for other apps to gate Pro features."""
    sub = getattr(user, "subscription", None)
    if sub is None:
        return False
    sub = sync_lifetime(sub, ref)
    return compute_status(sub, ref)["has_access"]
