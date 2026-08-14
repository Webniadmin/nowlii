import 'package:nowlii/services/api_date.dart';

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

  /// Words the user kept returning to, from the same GPT pass as the sentences above.
  final List<String> wordsCircled;

  /// One short question printed on the receipt. Empty hides the card.
  final String tinyQuestion;

  /// The user's own note on this receipt — the one field here they wrote themselves.
  final String note;
  final DateTime? noteUpdatedAt;

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
    this.wordsCircled = const [],
    this.tinyQuestion = '',
    this.note = '',
    this.noteUpdatedAt,
    this.language = '',
    this.totalTurns = 0,
    this.createdAt,
  });

  bool get hasNote => note.trim().isNotEmpty;

  /// A copy carrying a freshly-saved note, so the list can update without a refetch.
  CallSummaryHistoryItem withNote(String newNote, DateTime? updatedAt) =>
      CallSummaryHistoryItem(
        callId: callId,
        startedAt: startedAt,
        durationSeconds: durationSeconds,
        moodDetected: moodDetected,
        focusTopic: focusTopic,
        energyShift: energyShift,
        nextStep: nextStep,
        dominantEmotion: dominantEmotion,
        topEmotions: topEmotions,
        wordsCircled: wordsCircled,
        tinyQuestion: tinyQuestion,
        note: newNote,
        noteUpdatedAt: updatedAt,
        language: language,
        totalTurns: totalTurns,
        createdAt: createdAt,
      );

  factory CallSummaryHistoryItem.fromJson(Map<String, dynamic> json) {
    // The API has not always sent ISO-8601 — see parseApiDate. Using tryParse directly
    // turned every receipt date into null and blanked the dates on screen.
    const parseDate = parseApiDate;

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
      wordsCircled: (json['words_circled'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      tinyQuestion: json['tiny_question'] ?? '',
      note: json['note'] ?? '',
      noteUpdatedAt: parseDate(json['note_updated_at']),
      language: json['language'] ?? '',
      totalTurns: (json['total_turns'] is num) ? (json['total_turns'] as num).toInt() : 0,
      createdAt: parseDate(json['created_at']),
    );
  }
}
