from django.contrib import admin

from .models import CallEmotionSnapshot, CallLowMoodSnapshot, VoiceCall


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


@admin.register(CallEmotionSnapshot)
class CallEmotionSnapshotAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'user', 'dominant_emotion',
                    'happy', 'motivated', 'angry', 'tired', 'sad')
    list_filter = ('dominant_emotion', 'created_at')
    search_fields = ('user__email',)
    readonly_fields = ('call', 'user', 'happy', 'motivated', 'angry', 'tired', 'sad',
                       'dominant_emotion', 'created_at')
    list_select_related = ('user',)

    def has_add_permission(self, request):
        # Snapshots are written by the app at call end, never by hand.
        return False


@admin.register(CallLowMoodSnapshot)
class CallLowMoodSnapshotAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'user', 'dominant_category')
    list_filter = ('dominant_category', 'created_at')
    search_fields = ('user__email',)
    readonly_fields = ('call', 'user', 'phrases', 'dominant_category', 'created_at')
    list_select_related = ('user',)

    def has_add_permission(self, request):
        # Snapshots are written by the app at call end, never by hand.
        return False
