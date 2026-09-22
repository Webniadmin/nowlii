"""Deleting an account — the one implementation, used by the app and by the public web page.

Both stores require it (Google Play's data-deletion policy, Apple guideline 5.1.1(v)), and so
does the GDPR's right to erasure. It is a hard delete: the database cascade removes the
profile, quests and subtasks, voice calls with their summaries and emotion snapshots,
scheduled calls, insights, the subscription row and support messages. Two things a cascade
cannot reach are handled here — the avatar file in S3, and billing in Stripe.
"""

import logging

from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken

logger = logging.getLogger(__name__)


class DeletionBlocked(Exception):
    """Billing could not be stopped, so the account was left in place. Safe to retry."""


def _stop_billing(user):
    """Cancel any Stripe billing *before* the account goes.

    Deleting the account first and hoping Stripe follows would be the worst order: a
    subscription that outlives its account keeps charging someone who can no longer even
    log in to cancel it. So a Stripe failure blocks the deletion instead.
    """
    from Apps.subscriptions import stripe_gateway

    sub = getattr(user, "subscription", None)
    customer_id = getattr(sub, "stripe_customer_id", "") if sub else ""
    if not customer_id:
        return
    try:
        stripe_gateway.delete_customer(customer_id)
    except stripe_gateway.StripeNotConfigured:
        # A server without keys cannot reach Stripe. That only matters if something there
        # could still bill; a customer created by an abandoned checkout cannot.
        if sub.stripe_subscription_id and not sub.lifetime_free:
            raise DeletionBlocked("Stripe is not configured on this server.")
    except Exception as exc:
        logger.exception("Could not delete Stripe customer %s for user %s", customer_id, user.pk)
        raise DeletionBlocked(str(exc)) from exc


def delete_account(user, *, reason: str = "the user's request"):
    """Stop billing, then remove the user and everything they own. Raises DeletionBlocked."""
    user_id, user_email = user.pk, user.email

    _stop_billing(user)

    # The avatar lives in S3 and would survive the cascade as an orphaned object.
    profile = getattr(user, "profile", None)
    if profile is not None and profile.profile_image:
        try:
            profile.profile_image.delete(save=False)
        except Exception:
            # Never block the deletion on a storage hiccup — the account matters more than
            # one leftover file, and the row is going regardless.
            logger.exception("Could not delete the avatar for user %s", user_id)

    # Best-effort: stop outstanding refresh tokens from being usable in the window before
    # their rows cascade away.
    try:
        for token in OutstandingToken.objects.filter(user=user):
            BlacklistedToken.objects.get_or_create(token=token)
    except Exception:
        logger.exception("Could not blacklist tokens for user %s", user_id)

    user.delete()
    logger.info("Deleted account %s (%s) at %s", user_id, user_email, reason)
