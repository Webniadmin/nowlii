import logging

import stripe
from django.conf import settings
from django.shortcuts import render
from django.utils import timezone
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated

from . import config, services, stripe_gateway, webhooks
from .models import Subscription
from .serializers import PlanScheduleSerializer, SubscriptionStatusSerializer

log = logging.getLogger(__name__)


def _reported_region(request) -> str:
    """The storefront the app says it is in, upper-cased, or "" if it did not say.

    Reported by the client (its device region) rather than derived from the IP, because the
    device region is the closest thing to the storefront the user actually buys from and it
    needs no GeoIP database on the server. It is a policy gate, not a security one — nothing
    behind it is secret, it only decides whether a payment link may be shown at all.
    """
    return (request.headers.get("X-Nowlii-Region", "") or "").strip().upper()


def _checkout_allowed(region: str) -> bool:
    """May this user be offered an outside payment page?

    Apple has allowed linking out in the US since 2025-05 and Google Play since 2025-12-09;
    in most storefronts anti-steering still stands and the button must not appear. Launch is
    US-first, so ``CHECKOUT_ALLOWED_COUNTRIES`` defaults to US alone.

    A client that reports no region at all is allowed through — that is an older build, and
    refusing it would silently break buying for people who already have the app. Every
    current build sends the header, so the gate applies where it matters.
    """
    if not region:
        return True
    return region in settings.CHECKOUT_ALLOWED_COUNTRIES


def _status_payload(user, sub=None, grant_trial: bool = True, region: str = "") -> dict:
    """Build the /me/ payload from the user's subscription.

    By default this **grants the free trial** when the user has none — /me/ is the first
    thing the app calls after login, so that's where the 7-day clock starts for a fresh
    install. Pass ``grant_trial=False`` to read the state without creating anything.

    Callers that just mutated a subscription MUST pass it as ``sub``: re-reading
    ``user.subscription`` can return a stale cached instance and report the pre-change state.

    ``region`` is the storefront the app reported, and decides ``checkout_available`` — the
    server's answer to whether this user may be shown a payment link at all.
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
            "checkout_available": _checkout_allowed(region) and stripe_gateway.is_configured(),
        }
    sub = services.sync_trial_expiry(sub)
    sub = services.sync_lifetime(sub)
    sub = services.sync_step_down_state(sub)
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
        # The day access runs to, and whether the plan is already set to stop on it.
        "current_period_end": st["current_period_end"],
        "cancel_at_period_end": st["cancel_at_period_end"],
        # False both where linking out is forbidden and where this server has no Stripe keys,
        # so the app has one flag to read and never shows a button that cannot work.
        "checkout_available": _checkout_allowed(region) and stripe_gateway.is_configured(),
        # The app reads this on every launch: while `due` is true the user is being billed
        # more than the plan promises, and only the device can fix it. Always false on the
        # Stripe path — Stripe steps the price down itself, server-side. It is kept for the
        # store path, which is not in use. See docs/stripe-payments.md.
        "step_down": services.step_down_due(sub),
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
        data = _status_payload(request.user, region=_reported_region(request))
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
        data = _status_payload(request.user, sub=sub,
                               region=_reported_region(request))
        return Response(SubscriptionStatusSerializer(data).data, status=status.HTTP_200_OK)


class ActivateView(APIView):
    """POST /api/subscriptions/activate/ — MOCK activation (no real charge). Dev only.

    This is how the paywall was tested before there was a payment processor: it grants a
    subscription without taking any money. Real purchases now go through Stripe Checkout
    (``CheckoutSessionView``), so this is **off unless ``SUBSCRIPTION_ALLOW_MOCK_ACTIVATE``
    is set** — left reachable in production it is a button that hands out the paid product.

    Kept rather than deleted because it is still the fastest way to put an account into a
    given month of the ladder on a dev box without touching Stripe at all.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not settings.SUBSCRIPTION_ALLOW_MOCK_ACTIVATE:
            return Response(
                {"detail": "Mock activation is disabled. Use POST /subscriptions/checkout/."},
                status=status.HTTP_403_FORBIDDEN,
            )
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
        data = _status_payload(request.user, sub=sub,
                               region=_reported_region(request))
        return Response(SubscriptionStatusSerializer(data).data, status=status.HTTP_200_OK)


class CancelView(APIView):
    """POST /api/subscriptions/cancel/ — stop the plan at the end of the paid period.

    Access is **not** taken away here. The user has already paid for the month in progress,
    and keeping their money while removing what it bought is both unfair and the shortest
    route to a chargeback. So the plan runs to ``current_period_end`` and stops there; Stripe
    ends it on the day and the ``customer.subscription.deleted`` webhook closes the local row.

    A lifetime-free user has nothing to cancel — they finished the year and pay nothing.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        sub = getattr(request.user, "subscription", None)
        if sub is None:
            return Response({"detail": "No subscription to cancel."},
                            status=status.HTTP_404_NOT_FOUND)

        if sub.lifetime_free:
            data = _status_payload(request.user, sub=sub,
                               region=_reported_region(request))
            return Response(SubscriptionStatusSerializer(data).data)

        if sub.platform == Subscription.Platform.STRIPE and sub.stripe_subscription_id:
            try:
                result = stripe_gateway.cancel_at_period_end(sub)
            except stripe_gateway.StripeNotConfigured as exc:
                return Response({"detail": str(exc)},
                                status=status.HTTP_503_SERVICE_UNAVAILABLE)
            except stripe.StripeError:
                log.exception("stripe: cancel failed for user %s", request.user.pk)
                return Response(
                    {"detail": "Could not reach the payment provider. Please try again."},
                    status=status.HTTP_502_BAD_GATEWAY,
                )
            fields = ["cancel_at_period_end"]
            sub.cancel_at_period_end = True
            period_end = webhooks._as_date(result.get("current_period_end"))
            if period_end:
                sub.current_period_end = period_end
                fields.append("current_period_end")
            sub.save(update_fields=fields + ["updated_at"])
        else:
            # The mock path, and any pre-Stripe row: there is no provider to tell, so the
            # only honest thing is to end it here and now.
            sub.status = Subscription.Status.CANCELLED
            sub.cancelled_at = timezone.localdate()
            sub.save(update_fields=["status", "cancelled_at", "updated_at"])

        data = _status_payload(request.user, sub=sub,
                               region=_reported_region(request))
        return Response(SubscriptionStatusSerializer(data).data)


class ResumeView(APIView):
    """POST /api/subscriptions/resume/ — call off a cancellation that has not happened yet.

    Only meaningful between "cancel" and the end of the paid period. Someone who cancelled
    by accident, or changed their mind two days later, should not have to lose the rest of
    the month and buy the plan again at a rung they had already climbed past.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        sub = getattr(request.user, "subscription", None)
        if sub is None or not sub.cancel_at_period_end:
            return Response({"detail": "Nothing to resume."},
                            status=status.HTTP_400_BAD_REQUEST)
        try:
            result = stripe_gateway.resume(sub)
        except stripe_gateway.StripeNotConfigured as exc:
            return Response({"detail": str(exc)},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except stripe.StripeError:
            log.exception("stripe: resume failed for user %s", request.user.pk)
            return Response(
                {"detail": "Could not reach the payment provider. Please try again."},
                status=status.HTTP_502_BAD_GATEWAY,
            )
        sub.cancel_at_period_end = False
        fields = ["cancel_at_period_end"]
        period_end = webhooks._as_date(result.get("current_period_end"))
        if period_end:
            sub.current_period_end = period_end
            fields.append("current_period_end")
        sub.save(update_fields=fields + ["updated_at"])
        data = _status_payload(request.user, sub=sub,
                               region=_reported_region(request))
        return Response(SubscriptionStatusSerializer(data).data)


class ConfirmSwitchView(APIView):
    """POST /api/subscriptions/confirm-switch/ — the app finished a plan change.

    Body: ``{"store_product_id": "<base plan or Apple product id>"}``.

    The store is the only thing that knows what a user is really being billed; this endpoint
    is how that fact gets back to us after the device completes a switch the backend asked
    for. It deliberately accepts **any** product on the ladder rather than only the expected
    one: if the store put them somewhere unexpected, recording the truth is more useful than
    rejecting it and keeping a number we know is wrong.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        product = str(request.data.get("store_product_id", "")).strip()
        if not product:
            return Response({"detail": "store_product_id is required."},
                            status=status.HTTP_400_BAD_REQUEST)

        known = {p.get("google_base_plan") for p in config.PHASES}
        known |= {p.get("apple_product") for p in config.PHASES}
        if product not in known:
            return Response({"detail": f"Unknown store product '{product}'."},
                            status=status.HTTP_400_BAD_REQUEST)

        sub = getattr(request.user, "subscription", None)
        if sub is None:
            return Response({"detail": "No subscription."},
                            status=status.HTTP_404_NOT_FOUND)

        sub.store_product_id = product
        sub.save(update_fields=["store_product_id", "updated_at"])
        # Clears step_down_pending_since when this actually closed the gap.
        services.sync_step_down_state(sub)

        data = _status_payload(request.user, sub=sub,
                               region=_reported_region(request))
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


# ─────────────────────────────────────────────
#  Stripe — taking the money
# ─────────────────────────────────────────────

class CheckoutSessionView(APIView):
    """POST /api/subscriptions/checkout/ — start a purchase, return a hosted Checkout URL.

    The app opens the URL in the device's **browser**, not a webview: linking out to an
    outside payment page is permitted on the condition that it leaves the app, and a webview
    is the thing the rule exists to forbid.

    Nothing about entitlement changes here. A Checkout URL is an invitation to pay; access
    follows the webhook, which is the only thing that knows a charge actually succeeded.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        region = _reported_region(request)
        if not _checkout_allowed(region):
            return Response(
                {"detail": "Subscriptions are not available in your region yet.",
                 "region": region},
                status=status.HTTP_403_FORBIDDEN,
            )
        sub, _created = Subscription.objects.get_or_create(user=request.user)
        sub = services.sync_lifetime(sub)

        # Facts about this user come before facts about the server: someone who finished the
        # year pays nothing ever again whatever the server's configuration, and someone
        # already paying would end up with two subscriptions against one account.
        if sub.lifetime_free:
            return Response({"detail": "You already have free lifetime access."},
                            status=status.HTTP_409_CONFLICT)
        if sub.status == Subscription.Status.ACTIVE and sub.stripe_subscription_id:
            return Response({"detail": "You already have an active subscription."},
                            status=status.HTTP_409_CONFLICT)

        if not stripe_gateway.is_configured():
            return Response({"detail": "Payments are not configured on this server."},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE)

        try:
            url = stripe_gateway.create_checkout_session(request.user, sub)
        except stripe_gateway.StripeNotConfigured as exc:
            log.error("stripe: checkout unavailable — %s", exc)
            return Response({"detail": "Payments are not configured on this server."},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except stripe.StripeError:
            log.exception("stripe: could not create a checkout session for user %s",
                          request.user.pk)
            return Response(
                {"detail": "Could not reach the payment provider. Please try again."},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        month = stripe_gateway.start_month_for(sub)
        rung = services.phase_for_month(month)
        return Response({
            "url": url,
            # What the app can show while the browser opens, so the price on the button and
            # the price on the Stripe page are the same number from the same source.
            "stage": rung["stage"],
            "price": rung["price"],
            "currency": config.CURRENCY,
            "month_index": month,
        })


class BillingPortalView(APIView):
    """POST /api/subscriptions/portal/ — a Stripe-hosted page to manage the subscription.

    Card details, invoices and cancellation all live there. Keeping it hosted means no card
    number ever reaches this backend, and the cancellation a user performs is the real one
    rather than a flag here that may not match what they are still being charged.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        sub = getattr(request.user, "subscription", None)
        if sub is None or not sub.stripe_customer_id:
            return Response({"detail": "No billing account yet — subscribe first."},
                            status=status.HTTP_404_NOT_FOUND)
        try:
            url = stripe_gateway.create_portal_session(sub)
        except stripe_gateway.StripeNotConfigured as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except stripe.StripeError:
            log.exception("stripe: portal failed for user %s", request.user.pk)
            return Response(
                {"detail": "Could not reach the payment provider. Please try again."},
                status=status.HTTP_502_BAD_GATEWAY,
            )
        return Response({"url": url})


@method_decorator(csrf_exempt, name="dispatch")
class StripeWebhookView(APIView):
    """POST /api/subscriptions/webhook/ — the only thing that turns a payment into access.

    Public by necessity: Stripe's servers call it and have no account here. What makes that
    safe is the **signature**, checked against ``STRIPE_WEBHOOK_SECRET`` before the body is
    parsed. Without the secret configured every request is refused — an unverified webhook
    is an endpoint that hands a subscription to anyone who can POST JSON.

    It answers 200 to anything it has verified, including events it does not handle and
    replays it has already applied. A non-2xx makes Stripe retry, and there is nothing to
    retry for an event that was understood and deliberately ignored.
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        signature = request.META.get("HTTP_STRIPE_SIGNATURE", "")
        try:
            event = stripe_gateway.construct_event(request.body, signature)
        except stripe_gateway.StripeNotConfigured:
            log.error("stripe webhook: refused — STRIPE_WEBHOOK_SECRET is not set")
            return Response({"detail": "Webhook is not configured."},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except ValueError:
            log.warning("stripe webhook: malformed payload")
            return Response({"detail": "Invalid payload."},
                            status=status.HTTP_400_BAD_REQUEST)
        except stripe.SignatureVerificationError:
            log.warning("stripe webhook: bad signature")
            return Response({"detail": "Invalid signature."},
                            status=status.HTTP_400_BAD_REQUEST)

        try:
            result = webhooks.dispatch(event)
        except Exception:
            # A 500 here makes Stripe retry, which is what we want for a transient fault —
            # but the event id is already recorded, so the retry will be dropped as a
            # duplicate. Log loudly: this one needs a human.
            log.exception("stripe webhook: handler failed for %s (%s)",
                          event.get("id"), event.get("type"))
            return Response({"detail": "Handler error."},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({"received": True, "result": result})


# ─────────────────────────────────────────────
#  Where the browser lands after Checkout
# ─────────────────────────────────────────────
#
# Plain pages, no deep link. The app re-reads /subscriptions/me/ whenever it comes back into
# focus, so the purchase is noticed by returning to it — which works even if the user closes
# the tab, switches apps, or finishes checkout on a different device.

def checkout_success(request):
    return render(request, "subscriptions/success.html")


def checkout_cancelled(request):
    return render(request, "subscriptions/cancelled.html")
