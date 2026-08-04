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
from rest_framework.permissions import SAFE_METHODS, BasePermission

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


def _passes(user) -> bool:
    """Shared entitlement test: kill switch, allowlist, then real access."""
    if not getattr(settings, "SUBSCRIPTION_ENFORCED", True):
        return True                           # kill switch — gate off, app fully open
    if _is_exempt(user):
        return True
    return services.user_has_pro(user)        # also starts the trial on first contact


def user_is_entitled(user) -> bool:
    """The same test the gate applies, for views that degrade instead of refusing.

    Insights is the case this exists for: the numbers on that screen are the user's own
    records and stay visible after a lapse, but the AI paragraphs over them cost money per
    request. The view serves the data and skips the generation rather than returning 402.
    """
    if user is None or not user.is_authenticated:
        return False
    return _passes(user)


class HasProAccess(BasePermission):
    """Allow only users with an active trial, paid subscription, or lifetime-free access.

    Pair it with ``IsAuthenticated`` — on its own it treats anonymous callers as blocked,
    but returning 402 to someone who simply isn't logged in would be misleading.
    """

    def has_permission(self, request, view):
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False                      # let IsAuthenticated raise the 401
        if _passes(user):
            return True
        raise SubscriptionRequired()


class HasProAccessOrReadOnly(BasePermission):
    """Full access for entitled users; everyone else may still read.

    A lapsed subscriber keeps the record of what they already did — their quests, their
    streak, their progress — and loses the ability to add to it. Locking someone out of
    their own history would make the account feel confiscated rather than paused, and it
    also removes the very thing that argues for renewing.

    Writes still raise 402, so this is not a softer gate: it is the same gate applied to
    the actions that create value rather than to the ones that recall it. Endpoints that
    cost us money per call (AI generation, voice calls) keep the strict [HasProAccess].
    """

    def has_permission(self, request, view):
        user = getattr(request, "user", None)
        if user is None or not user.is_authenticated:
            return False                      # let IsAuthenticated raise the 401
        if _passes(user):
            return True
        if request.method in SAFE_METHODS:
            return True
        raise SubscriptionRequired()
