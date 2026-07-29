from django.urls import path

from .views import (
    PlanView,
    MySubscriptionView,
    StartTrialView,
    ActivateView,
    CancelView,
    VerifyReceiptView,
)

urlpatterns = [
    path("plan/", PlanView.as_view(), name="subscription-plan"),
    path("me/", MySubscriptionView.as_view(), name="subscription-me"),
    path("start-trial/", StartTrialView.as_view(), name="subscription-start-trial"),
    path("activate/", ActivateView.as_view(), name="subscription-activate"),
    path("cancel/", CancelView.as_view(), name="subscription-cancel"),
    path("verify-receipt/", VerifyReceiptView.as_view(), name="subscription-verify-receipt"),
]
