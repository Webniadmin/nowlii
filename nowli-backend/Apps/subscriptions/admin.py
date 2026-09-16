from django.contrib import admin
from django.utils import timezone

from .models import StripeEvent, Subscription


class OverpayingFilter(admin.SimpleListFilter):
    """Find the people the price ladder has left behind.

    Neither store lets a server move a subscriber to a cheaper plan, so a user who stops
    opening the app keeps paying the older, higher price. Nobody is notified when that
    happens — which is why it needs to be one click away in here rather than something we
    hear about from the customer.
    """
    title = "paying more than the plan"
    parameter_name = "overpaying"

    def lookups(self, request, model_admin):
        return (("yes", "Behind the price ladder"), ("no", "In step"))

    def queryset(self, request, queryset):
        if self.value() == "yes":
            return queryset.filter(step_down_pending_since__isnull=False)
        if self.value() == "no":
            return queryset.filter(step_down_pending_since__isnull=True)
        return queryset


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ("user", "status", "platform", "trial_started_at", "started_at",
                    "current_period_end", "cancel_at_period_end", "lifetime_free",
                    "overpaying_for", "updated_at")
    list_filter = ("status", "platform", "lifetime_free", "cancel_at_period_end",
                   OverpayingFilter)
    # The Stripe ids are here so a support question ("this person says they were charged")
    # can be answered by pasting what they give you — an email, or an id from their receipt.
    search_fields = ("user__username", "user__email", "store_transaction_id",
                     "store_product_id", "stripe_customer_id", "stripe_subscription_id")
    readonly_fields = ("created_at", "updated_at")

    @admin.display(description="Overpaying for", ordering="step_down_pending_since")
    def overpaying_for(self, obj):
        """How long this user has been billed above the schedule. '—' when they are in step.

        Shown in days because that is what a refund is calculated from.
        """
        if obj.step_down_pending_since is None:
            return "—"
        days = (timezone.localdate() - obj.step_down_pending_since).days
        return f"{days} day{'s' if days != 1 else ''}"


@admin.register(StripeEvent)
class StripeEventAdmin(admin.ModelAdmin):
    """The webhook's audit trail — and the answer to "did that event ever reach us?".

    Read-only on purpose: these rows are the record of what has already been applied, and
    deleting one would let Stripe's next retry apply the same event a second time.
    """
    list_display = ("event_type", "event_id", "received_at")
    list_filter = ("event_type",)
    search_fields = ("event_id", "event_type")
    readonly_fields = ("event_id", "event_type", "received_at")

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False
