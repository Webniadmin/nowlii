from rest_framework import serializers

from .models import VoiceCall


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
