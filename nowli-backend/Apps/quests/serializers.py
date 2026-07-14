from rest_framework import serializers
from django.utils import timezone
from .models import Quests, SubTasks


# ------------------------------------------------------------------------------
# SUBTASKS
# ------------------------------------------------------------------------------
class SubTasksSerializers(serializers.ModelSerializer):
    """Nested representation used inside QuestsSerializers (``task`` is set by the parent)."""
    class Meta:
        model = SubTasks
        exclude = ['task']


class SubTasksCrudSerializers(serializers.ModelSerializer):
    """Standalone representation for the subtasks CRUD endpoint — ``task`` (the parent
    quest id) is writable so a subtask can be created/moved on its own."""
    class Meta:
        model = SubTasks
        fields = '__all__'


# ------------------------------------------------------------------------------
# QUESTS
# ------------------------------------------------------------------------------
class QuestsSerializers(serializers.ModelSerializer):
    subtasks = SubTasksSerializers(many=True, required=False)
    
    class Meta:
        model = Quests
        exclude = ['user']

    def validate_select_a_date(self, value):
        # No past scheduling. Enforce on create only — editing an existing quest
        # must not be blocked just because its original date has since passed.
        # Date-level check against the server's local date keeps this timezone-safe
        # (the same-day past-*time* case is guarded precisely on the client).
        if self.instance is None and value is not None and value < timezone.localdate():
            raise serializers.ValidationError("Quest date cannot be in the past.")
        return value

    def create(self, validated_data):
        subtasks_data = validated_data.pop('subtasks', [])
        quest = Quests.objects.create(**validated_data)
        for subtask_data in subtasks_data:
            SubTasks.objects.create(task=quest, **subtask_data)
        return quest

    def update(self, instance, validated_data):
        subtasks_data = validated_data.pop('subtasks', None)
        instance = super().update(instance, validated_data)
        if subtasks_data is not None:
            instance.subtasks.all().delete()
            for subtask_data in subtasks_data:
                SubTasks.objects.create(task=instance, **subtask_data)
        return instance