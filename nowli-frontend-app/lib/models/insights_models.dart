import 'package:nowlii/models/quest_suggestion_model.dart';

class InsightsResponse {
  final WeeklyInsights weekly;
  final MonthlyInsights monthly;

  InsightsResponse({
    required this.weekly,
    required this.monthly,
  });

  factory InsightsResponse.fromJson(Map<String, dynamic> json) {
    return InsightsResponse(
      weekly: WeeklyInsights.fromJson(json['weekly']),
      monthly: MonthlyInsights.fromJson(json['monthly']),
    );
  }
}

class WeeklyInsights {
  final int questsCompleted;
  final int totalQuests;
  final List<String> aiReflections;
  final List<QuestSuggestion> questSuggestions;
  final List<ZoneProgress> zoneProgress;
  final List<String> skippedDays;
  final List<CalendarDay> calendar;
  // Top Emotions section (aggregated from voice-call snapshots). Empty when the user
  // has no calls yet — the UI hides the section in that case.
  final List<TopEmotion> topEmotions;
  final String emotionsSummary;
  // "When feeling low" section — recurring low-mood phrases + placeholder interpretation.
  // Empty phrases → the section still renders, with an empty-state placeholder.
  final List<String> lowMoodPhrases;
  final String lowMoodSummary;
  final String lowMoodRecommendation;

  WeeklyInsights({
    required this.questsCompleted,
    required this.totalQuests,
    required this.aiReflections,
    required this.questSuggestions,
    required this.zoneProgress,
    required this.skippedDays,
    required this.calendar,
    required this.topEmotions,
    required this.emotionsSummary,
    required this.lowMoodPhrases,
    required this.lowMoodSummary,
    required this.lowMoodRecommendation,
  });

  factory WeeklyInsights.fromJson(Map<String, dynamic> json) {
    return WeeklyInsights(
      questsCompleted: json['quests_completed'] ?? 0,
      totalQuests: json['total_quests'] ?? 0,
      aiReflections: List<String>.from(json['ai_reflections'] ?? []),
      questSuggestions: (json['quest_suggestions'] as List?)
              ?.map((e) => QuestSuggestion.fromJson(e))
              .toList() ??
          [],
      zoneProgress: (json['zone_progress'] as List?)
              ?.map((e) => ZoneProgress.fromJson(e))
              .toList() ??
          [],
      skippedDays: List<String>.from(json['skipped_days'] ?? []),
      calendar: (json['calendar'] as List?)
              ?.map((e) => CalendarDay.fromJson(e))
              .toList() ??
          [],
      topEmotions: (json['top_emotions'] as List?)
              ?.map((e) => TopEmotion.fromJson(e))
              .toList() ??
          [],
      emotionsSummary: json['emotions_summary'] ?? '',
      lowMoodPhrases: List<String>.from(json['low_mood_phrases'] ?? []),
      lowMoodSummary: json['low_mood_summary'] ?? '',
      lowMoodRecommendation: json['low_mood_recommendation'] ?? '',
    );
  }
}

class TopEmotion {
  final String key; // happy | motivated | angry | tired | sad
  final String label;
  final double pct; // 0–100

  TopEmotion({
    required this.key,
    required this.label,
    required this.pct,
  });

  factory TopEmotion.fromJson(Map<String, dynamic> json) {
    return TopEmotion(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      pct: (json['pct'] ?? 0).toDouble(),
    );
  }
}

class MonthlyInsights {
  final List<MostCompletedQuest> mostCompletedQuests;
  final String mostProductiveDay;
  final PreferredQuestTypes preferredQuestTypes;
  final QuestsCompleted questsCompleted;
  final List<ZoneProgress> zoneProgress;
  final List<CalendarDay> calendar;
  final Milestones milestones;

  MonthlyInsights({
    required this.mostCompletedQuests,
    required this.mostProductiveDay,
    required this.preferredQuestTypes,
    required this.questsCompleted,
    required this.zoneProgress,
    required this.calendar,
    required this.milestones,
  });

  factory MonthlyInsights.fromJson(Map<String, dynamic> json) {
    return MonthlyInsights(
      mostCompletedQuests: (json['most_completed_quests'] as List?)
              ?.map((e) => MostCompletedQuest.fromJson(e))
              .toList() ??
          [],
      mostProductiveDay: json['most_productive_day'] ?? '',
      preferredQuestTypes:
          PreferredQuestTypes.fromJson(json['preferred_quest_types'] ?? {}),
      questsCompleted:
          QuestsCompleted.fromJson(json['quests_completed'] ?? {}),
      zoneProgress: (json['zone_progress'] as List?)
              ?.map((e) => ZoneProgress.fromJson(e))
              .toList() ??
          [],
      calendar: (json['calendar'] as List?)
              ?.map((e) => CalendarDay.fromJson(e))
              .toList() ??
          [],
      milestones: Milestones.fromJson(json['milestones'] ?? {}),
    );
  }
}

class ZoneProgress {
  final String zone;
  final int assigned;
  final int completed;
  final String ratio;

  ZoneProgress({
    required this.zone,
    required this.assigned,
    required this.completed,
    required this.ratio,
  });

  factory ZoneProgress.fromJson(Map<String, dynamic> json) {
    return ZoneProgress(
      zone: json['zone'] ?? '',
      assigned: json['assigned'] ?? 0,
      completed: json['completed'] ?? 0,
      ratio: json['ratio'] ?? '0/0',
    );
  }
}

class CalendarDay {
  final String date;
  final String status; // "consistent", "skipped", "none"
  final int assigned;
  final int completed;

  CalendarDay({
    required this.date,
    required this.status,
    required this.assigned,
    required this.completed,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: json['date'] ?? '',
      status: json['status'] ?? 'none',
      assigned: json['assigned'] ?? 0,
      completed: json['completed'] ?? 0,
    );
  }
}

class MostCompletedQuest {
  final String task;
  final int completedCount;
  final bool repeatQuest;

  MostCompletedQuest({
    required this.task,
    required this.completedCount,
    required this.repeatQuest,
  });

  factory MostCompletedQuest.fromJson(Map<String, dynamic> json) {
    return MostCompletedQuest(
      task: json['task'] ?? '',
      completedCount: json['completed_count'] ?? 0,
      repeatQuest: json['repeat_quest'] ?? false,
    );
  }
}

class PreferredQuestTypes {
  final double softStepsPct;
  final double powerMovesPct;
  final String summary;

  PreferredQuestTypes({
    required this.softStepsPct,
    required this.powerMovesPct,
    required this.summary,
  });

  factory PreferredQuestTypes.fromJson(Map<String, dynamic> json) {
    return PreferredQuestTypes(
      softStepsPct: (json['soft_steps_pct'] ?? 0).toDouble(),
      powerMovesPct: (json['power_moves_pct'] ?? 0).toDouble(),
      summary: json['summary'] ?? '',
    );
  }
}

class QuestsCompleted {
  final int assigned;
  final int completed;

  QuestsCompleted({
    required this.assigned,
    required this.completed,
  });

  factory QuestsCompleted.fromJson(Map<String, dynamic> json) {
    return QuestsCompleted(
      assigned: json['assigned'] ?? 0,
      completed: json['completed'] ?? 0,
    );
  }
}

class Milestones {
  final int questsCompletedThisMonth;
  final int longestStreakDays;

  Milestones({
    required this.questsCompletedThisMonth,
    required this.longestStreakDays,
  });

  factory Milestones.fromJson(Map<String, dynamic> json) {
    return Milestones(
      questsCompletedThisMonth: json['quests_completed_this_month'] ?? 0,
      longestStreakDays: json['longest_streak_days'] ?? 0,
    );
  }
}
