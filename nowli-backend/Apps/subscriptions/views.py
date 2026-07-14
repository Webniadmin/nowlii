from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from . import config, services
from .models import Subscription
from .serializers import PlanScheduleSerializer, SubscriptionStatusSerializer


def _status_payload(user) -> dict:
    """Build the /me/ payload from the user's subscription (or the 'none' state)."""
    sub = getattr(user, "subscription", None)
    if sub is None:
        return {
            "subscribed": False,
            "status": "none",
            "currency": config.CURRENCY,
            "has_access": False,
            "lifetime_free": False,
        }
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


class ActivateView(APIView):
    """POST /api/subscriptions/activate/ — Phase-1 MOCK activation (no real charge).

    Starts the lifecycle today for a first-time subscriber, or re-activates a previously
    cancelled/expired one WITHOUT resetting the phase schedule. Phase 2 replaces this with
    real Apple/Google receipt verification (see ``VerifyReceiptView``).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        sub, _created = Subscription.objects.get_or_create(
            user=request.user,
            defaults={
                "started_at": timezone.localdate(),
                "platform": Subscription.Platform.MOCK,
            },
        )
        if sub.status in (Subscription.Status.CANCELLED, Subscription.Status.EXPIRED):
            sub.status = Subscription.Status.ACTIVE
            sub.cancelled_at = None
            sub.save(update_fields=["status", "cancelled_at", "updated_at"])
        data = _status_payload(request.user)
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
        data = _status_payload(request.user)
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
