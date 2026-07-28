from rest_framework import serializers

from .models import CallSummary, VoiceCall


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
