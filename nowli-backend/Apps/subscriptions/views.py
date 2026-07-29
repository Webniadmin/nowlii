from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from . import config, services
from .models import Subscription
from .serializers import PlanScheduleSerializer, SubscriptionStatusSerializer


def _status_payload(user, sub=None, grant_trial: bool = True) -> dict:
    """Build the /me/ payload from the user's subscription.

    By default this **grants the free trial** when the user has none — /me/ is the first
    thing the app calls after login, so that's where the 7-day clock starts for a fresh
    install. Pass ``grant_trial=False`` to read the state without creating anything.

    Callers that just mutated a subscription MUST pass it as ``sub``: re-reading
    ``user.subscription`` can return a stale cached instance and report the pre-change state.
    """
    if sub is None:
        sub = getattr(user, "subscription", None)
    if sub is None and grant_trial:
        sub = services.start_trial(user)
    if sub is None:
        # Only reachable with trials disabled (TRIAL_DAYS = 0) and no subscription.
        return {
            "subscribed": False,
            "status": "none",
            "currency": config.CURRENCY,
            "has_access": False,
            "lifetime_free": False,
            "in_trial": False,
            "trial_days_left": 0,
            "trial_days_total": config.TRIAL_DAYS,
            "trial_used": False,
        }
    sub = services.sync_trial_expiry(sub)
    sub = services.sync_lifetime(sub)
    st = services.compute_status(sub)
    return {
        "subscribed": True,
        "status": st["status"],
        "currency": config.CURRENCY,
        "platform": sub.platform,
        "started_at": sub.started_at,
        "month_index": st["month_index"],
        "phase": st["phase"],
        "current_price": st["current_price"],
        "next_price": st["next_price"],
        "is_free": st["is_free"],
        "lifetime_free": st["lifetime_free"],
        "has_access": st["has_access"],
        # Free-trial block — drives the "X days left" copy and the paywall redirect.
        "in_trial": st["in_trial"],
        "trial_days_left": st["trial_days_left"],
        "trial_ends_at": st["trial_ends_at"],
        "trial_days_total": config.TRIAL_DAYS,
        "trial_used": st["trial_used"],
    }


class PlanView(APIView):
    """GET /api/subscriptions/plan/ — the public price schedule for the paywall UI."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(PlanScheduleSerializer(services.phase_schedule()).data)


class MySubscriptionView(APIView):
    """GET /api/subscriptions/me/ — the caller's current subscription status."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        data = _status_payload(request.user)
        return Response(SubscriptionStatusSerializer(data).data)


class StartTrialView(APIView):
    """POST /api/subscriptions/start-trial/ — begin the free trial. Idempotent.

    The trial is normally granted automatically on the first authenticated request, so this
    exists for the explicit "Let's begin 7 days free" button. Calling it again (or after the
    trial is over, or once subscribed) never re-grants or extends anything — it just returns
    the current state.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        sub = services.start_trial(request.user)
        data = _status_payload(request.user, sub=sub)
        return Response(SubscriptionStatusSerializer(data).data, status=status.HTTP_200_OK)


class ActivateView(APIView):
    """POST /api/subscriptions/activate/ — Phase-1 MOCK activation (no real charge).

    Starts the lifecycle today for a first-time subscriber, or re-activates a previously
    cancelled/expired one WITHOUT resetting the phase schedule. Phase 2 replaces this with
    real Apple/Google receipt verification (see ``VerifyReceiptView``).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        today = timezone.localdate()
        sub, _created = Subscription.objects.get_or_create(
            user=request.user,
            defaults={
                "started_at": today,
                "platform": Subscription.Platform.MOCK,
            },
        )
        fields = []
        # Converting from a trial: the paid year starts NOW, not when the trial did, so the
        # user gets the full month-1 price phase they're paying for.
        if sub.started_at is None:
            sub.started_at = today
            fields.append("started_at")
        # Trial → paid, or re-activating a lapsed sub. A lifetime-free user is deliberately
        # left alone: they've earned free access and must not be flipped back to paying.
        if sub.status in (Subscription.Status.TRIAL,
                          Subscription.Status.CANCELLED,
                          Subscription.Status.EXPIRED):
            sub.status = Subscription.Status.ACTIVE
            sub.cancelled_at = None
            fields += ["status", "cancelled_at"]
        if fields:
            sub.save(update_fields=fields + ["updated_at"])
        data = _status_payload(request.user, sub=sub)
        return Response(SubscriptionStatusSerializer(data).data, status=status.HTTP_200_OK)


class CancelView(APIView):
    """POST /api/subscriptions/cancel/ — cancel a paid subscription (lifetime-free stays)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        sub = getattr(request.user, "subscription", None)
        if sub is None:
            return Response({"detail": "No subscription to cancel."},
                            status=status.HTTP_404_NOT_FOUND)
        if not sub.lifetime_free:
            sub.status = Subscription.Status.CANCELLED
            sub.cancelled_at = timezone.localdate()
            sub.save(update_fields=["status", "cancelled_at", "updated_at"])
        data = _status_payload(request.user, sub=sub)
        return Response(SubscriptionStatusSerializer(data).data)


class VerifyReceiptView(APIView):
    """POST /api/subscriptions/verify-receipt/ — Phase-2 STUB.

    Will verify an Apple IAP / Google Play purchase token and drive the lifecycle engine.
    Not implemented yet — mobile-only IAP integration is a later phase.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        return Response(
            {"detail": "Receipt verification is not implemented yet "
                       "(Phase 2: Apple IAP / Google Play Billing)."},
            status=status.HTTP_501_NOT_IMPLEMENTED,
        )
