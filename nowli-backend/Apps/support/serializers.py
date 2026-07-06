from rest_framework import serializers

from .models import SupportMessage


class SupportMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportMessage
        fields = ['id', 'sender', 'category', 'body', 'is_read', 'created_at']
        # `sender` is forced to 'user' server-side; the rest are server-managed.
        read_only_fields = ['id', 'sender', 'is_read', 'created_at']
