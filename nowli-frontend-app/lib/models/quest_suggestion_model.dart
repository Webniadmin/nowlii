class QuestSuggestionResponse {
  final WeeklySuggestions weekly;

  QuestSuggestionResponse({
    required this.weekly,
  });

  factory QuestSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return QuestSuggestionResponse(
      weekly: WeeklySuggestions.fromJson(json['weekly']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekly': weekly.toJson(),
    };
  }
}

class WeeklySuggestions {
  final int questsCompleted;
  final int totalQuests;
  final List<String> aiReflections;
  final List<QuestSuggestion> questSuggestions;

  WeeklySuggestions({
    required this.questsCompleted,
    required this.totalQuests,
    required this.aiReflections,
    required this.questSuggestions,
  });

  factory WeeklySuggestions.fromJson(Map<String, dynamic> json) {
    return WeeklySuggestions(
      questsCompleted: json['quests_completed'] ?? 0,
      totalQuests: json['total_quests'] ?? 0,
      aiReflections: List<String>.from(json['ai_reflections'] ?? []),
      questSuggestions: (json['quest_suggestions'] as List?)
              ?.map((item) => QuestSuggestion.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quests_completed': questsCompleted,
      'total_quests': totalQuests,
      'ai_reflections': aiReflections,
      'quest_suggestions': questSuggestions.map((item) => item.toJson()).toList(),
    };
  }
}

class QuestSuggestion {
  final String task;
  final String description;
  final String zone;
  final String suggestedTime;

  QuestSuggestion({
    required this.task,
    required this.description,
    required this.zone,
    required this.suggestedTime,
  });

  factory QuestSuggestion.fromJson(Map<String, dynamic> json) {
    return QuestSuggestion(
      task: json['task'] ?? '',
      description: json['description'] ?? '',
      zone: json['zone'] ?? '',
      suggestedTime: json['suggested_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'description': description,
      'zone': zone,
      'suggested_time': suggestedTime,
    };
  }
  
  // Helper method to get zone color
  String getZoneColor() {
    switch (zone.toLowerCase()) {
      case 'soft steps':
        return '#A0E871'; // Green
      case 'stretch zone':
        return '#FFB84D'; // Orange
      case 'power move':
        return '#FF6B6B'; // Red
      case 'elevated':
        return '#9B59B6'; // Purple
      default:
        return '#A0E871';
    }
  }
  
  // Helper method to get zone emoji
  String getZoneEmoji() {
    switch (zone.toLowerCase()) {
      case 'soft steps':
        return '🌱';
      case 'stretch zone':
        return '💪';
      case 'power move':
        return '🔥';
      case 'elevated':
        return '⭐';
      default:
        return '✨';
    }
  }
}
