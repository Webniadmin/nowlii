from rest_framework import serializers

from .models import CallSummary, ScheduledCall, VoiceCall


class VoiceCallSerializer(serializers.ModelSerializer):
    class Meta:
        model = VoiceCall
        fields = [
            'id', 'session_id', 'started_at', 'ended_at',
            'duration_seconds', 'extension_used', 'status',
        ]
        # started_at/status are server-managed; the call lifecycle is driven by the
        # dedicated start/end endpoints, not by arbitrary writes.
        read_only_fields = ['id', 'started_at', 'status']


class ScheduledCallSerializer(serializers.ModelSerializer):
    """A planned call, as the app should show it.

    ``status`` is the *resolved* status: a pending row whose time has passed reads as
    ``missed`` without anything having had to run at midnight to make it so.
    """

    status = serializers.CharField(source='resolved_status', read_only=True)
    quest_id = serializers.IntegerField(source='quest.pk', read_only=True)
    quest_title = serializers.CharField(source='quest.task', read_only=True, default='')
    call_id = serializers.IntegerField(source='call.pk', read_only=True, default=None)

    class Meta:
        model = ScheduledCall
        fields = [
            'id', 'quest_id', 'quest_title',
            'scheduled_for', 'local_date', 'status', 'call_id',
        ]
        # Everything is derived from the quest — the app edits the quest, not this row. The
        # one exception is rescheduling, handled explicitly by ScheduledCallDetailView.
        read_only_fields = fields


class CallSummarySerializer(serializers.ModelSerializer):
    """Read-only view of a saved call summary (for a user's call history / progress)."""

    call_id = serializers.IntegerField(source='call.pk', read_only=True)
    started_at = serializers.DateTimeField(source='call.started_at', read_only=True)
    duration_seconds = serializers.IntegerField(source='call.duration_seconds', read_only=True)

    class Meta:
        model = CallSummary
        fields = [
            'call_id', 'started_at', 'duration_seconds',
            'mood_detected', 'focus_topic', 'energy_shift', 'next_step',
            'dominant_emotion', 'top_emotions', 'language', 'total_turns',
            'created_at',
        ]
