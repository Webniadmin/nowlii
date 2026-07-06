from rest_framework import serializers


class SubTaskRequestSerializer(serializers.Serializer):
    category = serializers.CharField(
        max_length=255,
        help_text="The category to generate sub-tasks for (e.g. Fitness, Marketing)"
    )
    previous_tasks = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        default=list,
        help_text="Previously generated tasks to avoid repetition (for regeneration)"
    )


class SubTaskResponseSerializer(serializers.Serializer):
    category = serializers.CharField()
    provider = serializers.CharField()
    tasks    = serializers.ListField(child=serializers.CharField())
    count    = serializers.IntegerField()