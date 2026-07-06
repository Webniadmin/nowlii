class CallSummaryResponse {
  final String sessionId;
  final String userName;
  final String systemName;
  final String language;
  final String languageName;
  final int totalTurns;
  final String moodDetected;
  final String focusTopic;
  final String energyShift;
  final String nextStep;
  final String dominantEmotion;
  final Map<String, int> emotionCounts;
  final List<EmotionTimelineItem> emotionTimeline;
  final double processingMs;

  CallSummaryResponse({
    required this.sessionId,
    required this.userName,
    required this.systemName,
    required this.language,
    required this.languageName,
    required this.totalTurns,
    required this.moodDetected,
    required this.focusTopic,
    required this.energyShift,
    required this.nextStep,
    required this.dominantEmotion,
    required this.emotionCounts,
    required this.emotionTimeline,
    required this.processingMs,
  });

  factory CallSummaryResponse.fromJson(Map<String, dynamic> json) {
    return CallSummaryResponse(
      sessionId: json['session_id'] ?? '',
      userName: json['user_name'] ?? '',
      systemName: json['system_name'] ?? '',
      language: json['language'] ?? '',
      languageName: json['language_name'] ?? '',
      totalTurns: json['total_turns'] ?? 0,
      moodDetected: json['mood_detected'] ?? '',
      focusTopic: json['focus_topic'] ?? '',
      energyShift: json['energy_shift'] ?? '',
      nextStep: json['next_step'] ?? '',
      dominantEmotion: json['dominant_emotion'] ?? '',
      emotionCounts: Map<String, int>.from(json['emotion_counts'] ?? {}),
      emotionTimeline: (json['emotion_timeline'] as List?)
              ?.map((item) => EmotionTimelineItem.fromJson(item))
              .toList() ??
          [],
      processingMs: (json['processing_ms'] ?? 0).toDouble(),
    );
  }
}

class EmotionTimelineItem {
  final int turn;
  final String message;
  final String dominant;
  final Map<String, double> scores;

  EmotionTimelineItem({
    required this.turn,
    required this.message,
    required this.dominant,
    required this.scores,
  });

  factory EmotionTimelineItem.fromJson(Map<String, dynamic> json) {
    return EmotionTimelineItem(
      turn: json['turn'] ?? 0,
      message: json['message'] ?? '',
      dominant: json['dominant'] ?? '',
      scores: Map<String, double>.from(
        (json['scores'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
            ) ??
            {},
      ),
    );
  }
}
