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


# Shared by both weekly and monthly insights (defined here so the monthly serializer
# below can reference it).
class ZoneProgressSerializer(serializers.Serializer):
    zone      = serializers.CharField()
    assigned  = serializers.IntegerField()
    completed = serializers.IntegerField()
    ratio     = serializers.CharField()   # e.g. "3/5"


class MonthlyInsightSerializer(serializers.Serializer):
    most_completed_quests  = MostCompletedQuestSerializer(many=True)
    most_productive_day    = serializers.CharField(allow_blank=True, allow_null=True)
    preferred_quest_types  = PreferredQuestTypesSerializer()
    quests_completed       = MonthlyQuestsCompletedSerializer()
    zone_progress          = ZoneProgressSerializer(many=True)
    calendar               = CalendarDaySerializer(many=True)
    milestones             = MilestoneSerializer()


# ── Weekly insight sub-serializers ───────────────────────────────────────────

class QuestSuggestionSerializer(serializers.Serializer):
    task           = serializers.CharField()
    description    = serializers.CharField()
    zone           = serializers.CharField()
    suggested_time = serializers.CharField()


class TopEmotionSerializer(serializers.Serializer):
    key   = serializers.CharField()   # happy | motivated | angry | tired | sad
    label = serializers.CharField()
    pct   = serializers.FloatField()  # 0–100


class MoodDaySerializer(serializers.Serializer):
    day      = serializers.CharField()                       # Mon..Sun
    date     = serializers.DateField()
    level    = serializers.IntegerField()                    # 0–100 (bar height)
    emotion  = serializers.CharField(allow_null=True)        # dominant key or null
    has_data = serializers.BooleanField()


class WeeklyInsightSerializer(serializers.Serializer):
    quests_completed    = serializers.IntegerField()
    total_quests        = serializers.IntegerField()
    ai_reflections      = serializers.ListField(child=serializers.CharField())
    quest_suggestions   = QuestSuggestionSerializer(many=True)
    zone_progress       = ZoneProgressSerializer(many=True)
    skipped_days        = serializers.ListField(child=serializers.CharField())
    calendar            = CalendarDaySerializer(many=True)
    # Top Emotions section — optional so responses/tests without call data still validate.
    top_emotions        = TopEmotionSerializer(many=True, required=False)
    emotions_summary    = serializers.CharField(required=False, allow_blank=True)
    # "When feeling low" section — optional; the section is always shown, with an empty-state
    # in the UI when there are no phrases.
    low_mood_phrases        = serializers.ListField(child=serializers.CharField(), required=False)
    low_mood_summary        = serializers.CharField(required=False, allow_blank=True)
    low_mood_recommendation = serializers.CharField(required=False, allow_blank=True)
    # "Your mood" weekly chart — one entry per weekday (Mon..Sun). Optional so responses
    # without call data still validate; the UI hides the section when the week is empty.
    mood_week               = MoodDaySerializer(many=True, required=False)


# ── Combined top-level response ───────────────────────────────────────────────

class AIInsightResponseSerializer(serializers.Serializer):
    weekly  = WeeklyInsightSerializer()
    monthly = MonthlyInsightSerializer()
