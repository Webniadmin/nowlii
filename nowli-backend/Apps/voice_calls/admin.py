from django.contrib import admin

from .models import VoiceCall


@admin.register(VoiceCall)
class VoiceCallAdmin(admin.ModelAdmin):
    list_display = ('started_at', 'user', 'status', 'duration_seconds', 'extension_used', 'ended_at')
    list_filter = ('status', 'extension_used', 'started_at')
    search_fields = ('user__email', 'session_id')
    readonly_fields = ('started_at', 'ended_at', 'duration_seconds', 'extension_used',
                       'status', 'session_id', 'user')
    list_select_related = ('user',)

    def has_add_permission(self, request):
        # Voice calls are created by the app via the start endpoint, never by hand.
        return False
