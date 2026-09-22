"""The public account-deletion page — ``https://api.nowlii.com/delete-account/``.

Google Play's data-deletion policy wants a web link where someone can ask for their account
and data to be deleted *without* the app (they may already have uninstalled it). The app's
own "Delete My Account" stays the main path; this page reaches the same
``account_deletion.delete_account``.

Ownership is proved by a code mailed to the account's address, which also covers people who
signed in with Google or Apple and never had a password. The page answers identically whether
or not an account exists for the address, so it cannot be used to find out who has one.
"""

import logging

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.core.validators import validate_email
from django.core.exceptions import ValidationError
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

from .account_deletion import DeletionBlocked, delete_account
from .models import AccountDeletionRequest

logger = logging.getLogger(__name__)
TEMPLATE = "users/delete_account.html"


def _send_code(email: str) -> None:
    """Mail a fresh code if an account exists and the cooldown allows. Silent otherwise."""
    user = get_user_model().objects.filter(email__iexact=email).first()
    if user is None:
        return
    req, _ = AccountDeletionRequest.objects.get_or_create(email=user.email.lower())
    if not req.can_resend():
        return
    code = req.issue_code()
    try:
        send_mail(
            subject="Your NOWLII account deletion code",
            message=(
                f"Your code to delete your NOWLII account is {code}.\n\n"
                "It expires in 15 minutes. Entering it on the deletion page permanently "
                "deletes your account and all of its data.\n\n"
                "If you did not ask for this, ignore this email — nothing will be deleted."
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
        )
    except Exception:
        logger.exception("Could not mail an account-deletion code to user %s", user.pk)


@require_http_methods(["GET", "POST"])
def delete_account_page(request):
    ctx = {"step": "email", "email": "", "error": ""}
    if request.method == "GET":
        return render(request, TEMPLATE, ctx)

    email = (request.POST.get("email") or "").strip().lower()
    ctx["email"] = email
    try:
        validate_email(email)
    except ValidationError:
        ctx["error"] = "Please enter the email address of your NOWLII account."
        return render(request, TEMPLATE, ctx, status=400)

    if request.POST.get("action") == "send":
        _send_code(email)
        ctx["step"] = "code"
        return render(request, TEMPLATE, ctx)

    # action == "confirm"
    ctx["step"] = "code"
    if request.POST.get("understand") != "yes":
        ctx["error"] = "Please tick the box to confirm you understand this cannot be undone."
        return render(request, TEMPLATE, ctx, status=400)

    req = AccountDeletionRequest.objects.filter(email=email).first()
    user = get_user_model().objects.filter(email__iexact=email).first()
    if req is None or user is None or not req.check_code(request.POST.get("code", "")):
        # One message for every failure — wrong, expired, used up, or no such account —
        # so the answer never reveals whether an address has an account.
        ctx["error"] = ("That code is not right or has expired. Check the email, or request "
                        "a new code below.")
        return render(request, TEMPLATE, ctx, status=400)

    try:
        delete_account(user, reason="the user's request (web page)")
    except DeletionBlocked:
        ctx["error"] = ("We couldn't cancel your subscription just now, so nothing was "
                        "deleted. Please try again in a few minutes.")
        return render(request, TEMPLATE, ctx, status=503)

    req.delete()
    return render(request, TEMPLATE, {"step": "done"})
