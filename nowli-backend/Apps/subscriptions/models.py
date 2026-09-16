from django.conf import settings
from django.db import models


class Subscription(models.Model):
    """A user's subscription lifecycle. One per user.

    NOWLII's monthly price steps down over the first year (see ``config.PHASES``) and after
    ``config.FREE_AFTER_MONTH`` months the user is granted lifetime-free access. The BACKEND
    is the source of truth for access: it derives the current phase/price from ``started_at``.
    Stripe only *feeds* this model, through the webhook — it never decides access on its own,
    and a user whose webhook is late still has whatever ``started_at`` says they have.
    """

    class Status(models.TextChoices):
        TRIAL = "trial", "Trial"                           # free trial, no card, full access
        ACTIVE = "active", "Active"                        # within a paid phase
        # A renewal failed and Stripe is retrying the card. Access is kept, but only to the
        # end of the period the user actually paid for (``current_period_end``) — not
        # indefinitely. Cards decline for reasons that clear themselves in a day, so cutting
        # someone off on the first failed charge locks out paying customers; carrying them
        # past the month they paid for would be giving the app away. The paid-through date
        # is the line, and ``services.compute_status`` enforces it.
        PAST_DUE = "past_due", "Past due"
        LIFETIME_FREE = "lifetime_free", "Lifetime free"   # completed the year → free forever
        CANCELLED = "cancelled", "Cancelled"
        EXPIRED = "expired", "Expired"                     # trial ran out / paid sub lapsed

    class Platform(models.TextChoices):
        MOCK = "mock", "Mock"                              # Phase-1 testing (no real charge)
        STRIPE = "stripe", "Stripe"                        # the live payment path
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

    # ── Stripe ────────────────────────────────────────────────────────────────
    # Filled by the webhook. The customer id outlives any single subscription, so a user who
    # cancels and comes back is the same customer and keeps their payment methods and
    # invoice history; the subscription and schedule ids belong to the current purchase.
    stripe_customer_id = models.CharField(max_length=255, blank=True, db_index=True)
    stripe_subscription_id = models.CharField(max_length=255, blank=True, db_index=True)
    # The schedule is the price ladder itself: four phases of three months, then it ends and
    # the subscription cancels, which is what turns into lifetime-free access here.
    stripe_schedule_id = models.CharField(max_length=255, blank=True)
    # End of the period the user has already paid for. This date does two jobs: cancellation
    # is scheduled for it rather than taken immediately, and it is the day access ends for
    # someone whose card is failing.
    current_period_end = models.DateField(blank=True, null=True)
    # The user asked to stop, and Stripe will end the plan when the paid period runs out.
    # Access is unchanged until then — they paid for these days. The app reads this to say
    # "your plan ends on <date>" instead of pretending nothing happened.
    cancel_at_period_end = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Subscription"
        verbose_name_plural = "Subscriptions"

    def __str__(self):
        when = self.started_at or self.trial_started_at or "—"
        return f"{self.user} | {self.status} | since {when}"


class StripeEvent(models.Model):
    """Every Stripe webhook event this backend has already applied.

    Stripe retries a webhook until it gets a 2xx, and it is explicit that the same event can
    arrive more than once even after a success. Every handler here writes something — a start
    date, a status, a lifetime grant — so replaying one is not harmless. This table is the
    guard: the event id is unique, and an event whose row already exists is acknowledged and
    dropped rather than applied twice.
    """

    event_id = models.CharField(max_length=255, unique=True)
    event_type = models.CharField(max_length=100, blank=True)
    received_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Stripe event"
        verbose_name_plural = "Stripe events"
        ordering = ["-received_at"]

    def __str__(self):
        return f"{self.event_type} {self.event_id}"
