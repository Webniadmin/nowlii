from django.conf import settings
from django.db import models


class Subscription(models.Model):
    """A user's subscription lifecycle. One per user.

    NOWLII's monthly price steps down over the first year (see ``config.PHASES``) and after
    ``config.FREE_AFTER_MONTH`` months the user is granted lifetime-free access. The BACKEND
    is the source of truth for access: it derives the current phase/price from ``started_at``.
    The store (Apple IAP / Google Play, wired in a later phase) only *feeds* this model via
    receipt verification — it never decides access on its own.
    """

    class Status(models.TextChoices):
        ACTIVE = "active", "Active"                        # within a paid phase
        LIFETIME_FREE = "lifetime_free", "Lifetime free"   # completed the year → free forever
        CANCELLED = "cancelled", "Cancelled"
        EXPIRED = "expired", "Expired"

    class Platform(models.TextChoices):
        MOCK = "mock", "Mock"                              # Phase-1 testing (no real charge)
        APPLE = "apple", "Apple"
        GOOGLE = "google", "Google"

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="subscription",
    )
    started_at = models.DateField(help_text="First billing day; anchors the phase schedule.")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    platform = models.CharField(max_length=10, choices=Platform.choices, default=Platform.MOCK)
    lifetime_free = models.BooleanField(default=False)
    cancelled_at = models.DateField(blank=True, null=True)
    # Store references for the future IAP/Play verification (unused in Phase 1).
    store_transaction_id = models.CharField(max_length=255, blank=True)
    store_token = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Subscription"
        verbose_name_plural = "Subscriptions"

    def __str__(self):
        return f"{self.user} | {self.status} | since {self.started_at}"
