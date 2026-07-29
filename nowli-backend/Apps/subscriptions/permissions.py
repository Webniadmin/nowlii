"""Entitlement gate for the app's paid features.

NOWLII gives every new user a free trial on first login; when it runs out they must
subscribe to keep using the app. This module is what actually enforces that — the frontend
redirect is UX, not security.

Deliberately NOT applied to auth, profile, subscriptions or support: a blocked user must
still be able to log in, see who they are, buy a subscription and reach support.
"""
from django.conf import settings
from rest_framework import status
from rest_framework.exceptions import APIException
from rest_framework.permissions import BasePermission

from . import services


class SubscriptionRequired(APIException):
    """402 Payment Required — the caller is authenticated but out of trial/subscription.

    Distinct from 401 (not logged in) and 403 (logged in, wrong owner) so the app can route
    straight to the paywall instead of bouncing the user back to the login screen.
    """
    status_code = status.HTTP_402_PAYMENT_REQUIRED
    default_detail = "Your free trial has ended. Subscribe to Nowlii Pro to keep going."
    default_code = "subscription_required"


def _is_exempt(user) -> bool:
    """Accounts that bypass the gate: staff, and the configured test allowlist.

    Mirrors ``VOICE_CALL_UNLIMITED_USERS`` so dev/test accounts don't get locked out mid-test.
    """
    if getattr(user, "is_staff", False) or getattr(user, "is_superuser", False):
        return True
    allowlist = getattr(settings, "SUBSCRIPTION_UNLIMITED_USERS", None) or []
    username = (getattr(user, "username", "") or "").strip().lower()
    email = (getattr(user, "email", "") or "").strip().lower()
    return bool(username and username in allowlist) or bool(email and email in allowlist)


class HasProAccess(BasePermission):
    """Allow only users with an active trial, paid subscription, or lifetime-free access.

    Pair it with ``IsAuthenticated`` — on its own it treats anonymous callers as blocked,
    but returning 402 to someone who simply isn't logged in would be misleading.
    """

    def has_permission(self, request, view):
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False                      # let IsAuthenticated raise the 401
        if not getattr(settings, "SUBSCRIPTION_ENFORCED", True):
            return True                       # kill switch — gate off, app fully open
        if _is_exempt(user):
            return True
        if services.user_has_pro(user):       # also starts the trial on first contact
            return True
        raise SubscriptionRequired()
