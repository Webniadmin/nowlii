from django.urls import path

from .views import (
    PlanView,
    MySubscriptionView,
    StartTrialView,
    ActivateView,
    CancelView,
    ResumeView,
    ConfirmSwitchView,
    VerifyReceiptView,
    CheckoutSessionView,
    BillingPortalView,
    StripeWebhookView,
    checkout_success,
    checkout_cancelled,
)

urlpatterns = [
    path("plan/", PlanView.as_view(), name="subscription-plan"),
    path("me/", MySubscriptionView.as_view(), name="subscription-me"),
    path("start-trial/", StartTrialView.as_view(), name="subscription-start-trial"),
    path("activate/", ActivateView.as_view(), name="subscription-activate"),
    path("cancel/", CancelView.as_view(), name="subscription-cancel"),
    path("resume/", ResumeView.as_view(), name="subscription-resume"),

    # Stripe. `webhook/` is the only unauthenticated route here — Stripe's servers have no
    # account, so it is verified by signature instead. See StripeWebhookView.
    path("checkout/", CheckoutSessionView.as_view(), name="subscription-checkout"),
    path("portal/", BillingPortalView.as_view(), name="subscription-portal"),
    path("webhook/", StripeWebhookView.as_view(), name="subscription-webhook"),
    path("success/", checkout_success, name="subscription-checkout-success"),
    path("cancelled/", checkout_cancelled, name="subscription-checkout-cancelled"),
    path("confirm-switch/", ConfirmSwitchView.as_view(), name="subscription-confirm-switch"),
    path("verify-receipt/", VerifyReceiptView.as_view(), name="subscription-verify-receipt"),
]
