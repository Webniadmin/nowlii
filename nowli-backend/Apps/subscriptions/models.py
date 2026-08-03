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
        TRIAL = "trial", "Trial"                           # free trial, no card, full access
        ACTIVE = "active", "Active"                        # within a paid phase
        LIFETIME_FREE = "lifetime_free", "Lifetime free"   # completed the year → free forever
        CANCELLED = "cancelled", "Cancelled"
        EXPIRED = "expired", "Expired"                     # trial ran out / paid sub lapsed

    class Platform(models.TextChoices):
        MOCK = "mock", "Mock"                              # Phase-1 testing (no real charge)
        APPLE = "apple", "Apple"
        GOOGLE = "google", "Google"

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="subscription",
    )
    # NULL while the user is still on the free trial and has never paid — the paid phase
    # schedule only starts counting on the day they actually subscribe.
    started_at = models.DateField(
        blank=True, null=True,
        help_text="First billing day; anchors the phase schedule. Null during a trial.",
    )
    trial_started_at = models.DateField(
        blank=True, null=True,
        help_text="Day the free trial began. Null if the user never had one.",
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    platform = models.CharField(max_length=10, choices=Platform.choices, default=Platform.MOCK)
    lifetime_free = models.BooleanField(default=False)
    cancelled_at = models.DateField(blank=True, null=True)
    # Store references, filled by receipt verification.
    store_transaction_id = models.CharField(max_length=255, blank=True)
    store_token = models.TextField(blank=True)
    # The store product currently billing this user — a Play base plan id or an Apple
    # product id. The price ladder is four products, so this is how the backend knows which
    # rung the store is actually on, as opposed to which rung the schedule says it should be.
    store_product_id = models.CharField(max_length=100, blank=True)
    # When the billed product first fell out of step with the schedule.
    #
    # Neither store offers a server-side plan change, so closing the gap needs the user to
    # open the app. This field is what stops that being invisible: while it is set, the user
    # is paying more than the plan promises, and every renewal that passes makes it worse.
    # Surfaced in the admin so it can be found and refunded rather than discovered by them.
    step_down_pending_since = models.DateField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Subscription"
        verbose_name_plural = "Subscriptions"

    def __str__(self):
        when = self.started_at or self.trial_started_at or "—"
        return f"{self.user} | {self.status} | since {when}"
