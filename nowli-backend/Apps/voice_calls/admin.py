from django.contrib import admin

from .models import (
    CallEmotionSnapshot,
    CallLowMoodSnapshot,
    CallSummary,
    ScheduledCall,
    VoiceCall,
)


@admin.register(ScheduledCall)
class ScheduledCallAdmin(admin.ModelAdmin):
    list_display = ('scheduled_for', 'user', 'quest', 'status', 'resolved_status', 'call')
    list_filter = ('status', 'local_date')
    search_fields = ('user__email', 'quest__task')
    readonly_fields = ('created_at', 'updated_at', 'call')
    list_select_related = ('user', 'quest', 'call')
    date_hierarchy = 'scheduled_for'

    @admin.display(description='Shown to user as')
    def resolved_status(self, obj):
        # `missed` is derived on read, so the stored value alone can mislead in the admin.
        return obj.resolved_status

    def has_add_permission(self, request):
        # Created by the quest sync signal, never by hand.
        return False


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


@admin.register(CallSummary)
class CallSummaryAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'user', 'dominant_emotion', 'focus_topic', 'total_turns')
    list_filter = ('dominant_emotion', 'language', 'created_at')
    search_fields = ('user__email', 'mood_detected', 'focus_topic')
    readonly_fields = ('call', 'user', 'mood_detected', 'focus_topic', 'energy_shift',
                       'next_step', 'dominant_emotion', 'top_emotions', 'language',
                       'total_turns', 'created_at')
    list_select_related = ('user',)

    def has_add_permission(self, request):
        # Summaries are written by the app at call end, never by hand.
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
