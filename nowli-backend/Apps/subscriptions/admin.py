from django.contrib import admin

from .models import Subscription


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ("user", "status", "platform", "started_at", "lifetime_free", "updated_at")
    list_filter = ("status", "platform", "lifetime_free")
    search_fields = ("user__username", "user__email", "store_transaction_id")
    readonly_fields = ("created_at", "updated_at")
