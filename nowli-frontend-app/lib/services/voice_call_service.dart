import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/call_summary_history.dart';

/// Outcome of asking the backend to start a call. The backend is the sole authority for
/// the daily limit, so the UI acts on this result — it never counts calls itself.
enum VoiceCallStartOutcome {
  allowed, // call registered; proceed
  limitReached, // 429 — user is out of calls for today
  error, // network/backend error — fail closed (do not allow the call)
}

class VoiceCallQuota {
  final int limit;
  final int used;
  final int remaining;

  const VoiceCallQuota({
    required this.limit,
    required this.used,
    required this.remaining,
  });

  factory VoiceCallQuota.fromJson(Map<String, dynamic> json) => VoiceCallQuota(
        limit: json['limit'] ?? 0,
        used: json['used'] ?? 0,
        remaining: json['remaining'] ?? 0,
      );

  bool get hasRemaining => remaining > 0;
}

class VoiceCallStartResult {
  final VoiceCallStartOutcome outcome;
  final int? callId;
  final int remaining;
  final int limit;

  const VoiceCallStartResult({
    required this.outcome,
    this.callId,
    this.remaining = 0,
    this.limit = 0,
  });
}

/// Talks to the Django backend (baseUrl) for the AI voice-call daily limit and the
/// per-call start/end records. Authenticated with the stored JWT, like the other
/// feature services (e.g. QuestService).
class VoiceCallService {
  static String get _base => ApiConstants.baseUrl;

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': ApiConstants.contentType,
        'accept': ApiConstants.accept,
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };

  /// How many AI calls the user has left today. Returns null on error.
  Future<VoiceCallQuota?> getQuota() async {
    try {
      final token = await _getToken();
      final response = await http
          .get(Uri.parse('$_base${ApiConstants.voiceCallQuota}'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return VoiceCallQuota.fromJson(jsonDecode(response.body));
      }
      print('⚠️ getQuota status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ getQuota error: $e');
      return null;
    }
  }

  /// Register the start of a call. The backend enforces the daily limit and returns 429
  /// when the user is out of calls. On any network/backend error we fail closed
  /// (outcome = error) — the frontend must never let a call through without the
  /// backend's approval.
  Future<VoiceCallStartResult> startCall({String? sessionId}) async {
    try {
      final token = await _getToken();
      final response = await http
          .post(
            Uri.parse('$_base${ApiConstants.voiceCallStart}'),
            headers: _headers(token),
            body: jsonEncode({if (sessionId != null) 'session_id': sessionId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return VoiceCallStartResult(
          outcome: VoiceCallStartOutcome.allowed,
          callId: json['id'],
          remaining: json['remaining'] ?? 0,
          limit: json['limit'] ?? 0,
        );
      }

      if (response.statusCode == 429) {
        final json = jsonDecode(response.body);
        return VoiceCallStartResult(
          outcome: VoiceCallStartOutcome.limitReached,
          remaining: 0,
          limit: json['limit'] ?? 0,
        );
      }

      print('⚠️ startCall status: ${response.statusCode} — ${response.body}');
      return const VoiceCallStartResult(outcome: VoiceCallStartOutcome.error);
    } catch (e) {
      print('❌ startCall error: $e');
      return const VoiceCallStartResult(outcome: VoiceCallStartOutcome.error);
    }
  }

  /// Finalize a call with its real duration and whether the extension was used.
  /// Optionally persists the AI Top-Emotion breakdown captured at call end (the app
  /// fetches it from nowli-ai while the session is still alive and hands it here).
  /// Fire-and-forget: the backend end record is best-effort and idempotent.
  Future<void> endCall({
    required int callId,
    required int durationSeconds,
    required bool extensionUsed,
    Map<String, double>? emotionBreakdown,
    String? dominantEmotion,
    List<Map<String, dynamic>>? lowMoodPhrases,
  }) async {
    try {
      final token = await _getToken();
      await http
          .post(
            Uri.parse('$_base${ApiConstants.voiceCallEnd(callId)}'),
            headers: _headers(token),
            body: jsonEncode({
              'duration_seconds': durationSeconds,
              'extension_used': extensionUsed,
              if (emotionBreakdown != null) 'emotion_breakdown': emotionBreakdown,
              if (dominantEmotion != null) 'dominant_emotion': dominantEmotion,
              if (lowMoodPhrases != null) 'low_mood_phrases': lowMoodPhrases,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('❌ endCall error: $e');
    }
  }

  /// Persist a finished call's conversational summary for this user. The app already
  /// generated the summary via nowli-ai to show the summary screen; this saves it so it
  /// survives nowli-ai restarts and builds the user's call history for progress tracking.
  /// Idempotent on the backend (one summary per call). Fire-and-forget / best-effort.
  Future<void> saveSummary({
    required int callId,
    required String moodDetected,
    required String focusTopic,
    required String energyShift,
    required String nextStep,
    String? dominantEmotion,
    Map<String, double>? topEmotions,
    String? language,
    int? totalTurns,
  }) async {
    try {
      final token = await _getToken();
      await http
          .post(
            Uri.parse('$_base${ApiConstants.voiceCallSummary(callId)}'),
            headers: _headers(token),
            body: jsonEncode({
              'mood_detected': moodDetected,
              'focus_topic': focusTopic,
              'energy_shift': energyShift,
              'next_step': nextStep,
              if (dominantEmotion != null) 'dominant_emotion': dominantEmotion,
              if (topEmotions != null) 'top_emotions': topEmotions,
              if (language != null) 'language': language,
              if (totalTurns != null) 'total_turns': totalTurns,
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('❌ saveSummary error: $e');
    }
  }

  /// The current user's saved call summaries (newest first), for the Call History screen.
  /// Returns an empty list on any error.
  Future<List<CallSummaryHistoryItem>> getSummaries() async {
    try {
      final token = await _getToken();
      final response = await http
          .get(Uri.parse('$_base${ApiConstants.voiceCallSummaries}'),
              headers: _headers(token))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(CallSummaryHistoryItem.fromJson)
              .toList();
        }
      } else {
        print('⚠️ getSummaries status: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ getSummaries error: $e');
      return [];
    }
  }
}
