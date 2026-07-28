/// One saved AI voice-call summary, as returned by GET /api/voice-calls/summaries/.
/// Used by the Call History screen to let the user look back over their calls and see how
/// they've been progressing over time.
class CallSummaryHistoryItem {
  final int callId;
  final DateTime? startedAt;
  final int durationSeconds;
  final String moodDetected;
  final String focusTopic;
  final String energyShift;
  final String nextStep;
  final String dominantEmotion;
  final Map<String, double> topEmotions;
  final String language;
  final int totalTurns;
  final DateTime? createdAt;

  const CallSummaryHistoryItem({
    required this.callId,
    this.startedAt,
    this.durationSeconds = 0,
    this.moodDetected = '',
    this.focusTopic = '',
    this.energyShift = '',
    this.nextStep = '',
    this.dominantEmotion = '',
    this.topEmotions = const {},
    this.language = '',
    this.totalTurns = 0,
    this.createdAt,
  });

  factory CallSummaryHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        (v is String && v.isNotEmpty) ? DateTime.tryParse(v)?.toLocal() : null;

    return CallSummaryHistoryItem(
      callId: (json['call_id'] is num) ? (json['call_id'] as num).toInt() : 0,
      startedAt: parseDate(json['started_at']),
      durationSeconds:
          (json['duration_seconds'] is num) ? (json['duration_seconds'] as num).toInt() : 0,
      moodDetected: json['mood_detected'] ?? '',
      focusTopic: json['focus_topic'] ?? '',
      energyShift: json['energy_shift'] ?? '',
      nextStep: json['next_step'] ?? '',
      dominantEmotion: json['dominant_emotion'] ?? '',
      topEmotions: (json['top_emotions'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0),
          ) ??
          {},
      language: json['language'] ?? '',
      totalTurns: (json['total_turns'] is num) ? (json['total_turns'] as num).toInt() : 0,
      createdAt: parseDate(json['created_at']),
    );
  }
}
