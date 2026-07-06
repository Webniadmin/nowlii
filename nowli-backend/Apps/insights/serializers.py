from rest_framework import serializers


# ── Monthly insight sub-serializers ──────────────────────────────────────────

class MostCompletedQuestSerializer(serializers.Serializer):
    task          = serializers.CharField()
    completed_count = serializers.IntegerField()
    repeat_quest  = serializers.BooleanField()


class PreferredQuestTypesSerializer(serializers.Serializer):
    soft_steps_pct  = serializers.FloatField()
    power_moves_pct = serializers.FloatField()
    summary         = serializers.CharField()


class CalendarDaySerializer(serializers.Serializer):
    date      = serializers.DateField()
    status    = serializers.ChoiceField(choices=['consistent', 'skipped', 'streak', 'none'])
    assigned  = serializers.IntegerField()
    completed = serializers.IntegerField()


class MonthlyQuestsCompletedSerializer(serializers.Serializer):
    assigned  = serializers.IntegerField()
    completed = serializers.IntegerField()


class MilestoneSerializer(serializers.Serializer):
    quests_completed_this_month = serializers.IntegerField()
    longest_streak_days         = serializers.IntegerField()


class MonthlyInsightSerializer(serializers.Serializer):
    most_completed_quests  = MostCompletedQuestSerializer(many=True)
    most_productive_day    = serializers.CharField(allow_blank=True, allow_null=True)
    preferred_quest_types  = PreferredQuestTypesSerializer()
    quests_completed       = MonthlyQuestsCompletedSerializer()
    calendar               = CalendarDaySerializer(many=True)
    milestones             = MilestoneSerializer()


# ── Weekly insight sub-serializers ───────────────────────────────────────────

class ZoneProgressSerializer(serializers.Serializer):
    zone      = serializers.CharField()
    assigned  = serializers.IntegerField()
    completed = serializers.IntegerField()
    ratio     = serializers.CharField()   # e.g. "3/5"


class QuestSuggestionSerializer(serializers.Serializer):
    task           = serializers.CharField()
    description    = serializers.CharField()
    zone           = serializers.CharField()
    suggested_time = serializers.CharField()


class WeeklyInsightSerializer(serializers.Serializer):
    quests_completed    = serializers.IntegerField()
    total_quests        = serializers.IntegerField()
    ai_reflections      = serializers.ListField(child=serializers.CharField())
    quest_suggestions   = QuestSuggestionSerializer(many=True)
    zone_progress       = ZoneProgressSerializer(many=True)
    skipped_days        = serializers.ListField(child=serializers.CharField())
    calendar            = CalendarDaySerializer(many=True)


# ── Combined top-level response ───────────────────────────────────────────────

class AIInsightResponseSerializer(serializers.Serializer):
    weekly  = WeeklyInsightSerializer()
    monthly = MonthlyInsightSerializer()
