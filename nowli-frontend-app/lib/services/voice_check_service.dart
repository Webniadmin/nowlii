import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/services/ai_auth_headers.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Result of the onboarding voice check.
class VoiceCheckResult {
  /// What the user actually said. Empty if nothing was picked up.
  final String transcript;

  /// Dominant emotion returned by the AI service, when it managed to read one.
  final String? dominantEmotion;

  /// True when the microphone produced speech we could use.
  bool get heardSomething => transcript.trim().isNotEmpty;

  const VoiceCheckResult({
    required this.transcript,
    this.dominantEmotion,
  });

  static const empty = VoiceCheckResult(transcript: '');
}

/// Drives the onboarding "quick voice check".
///
/// This step used to be theatre: a ten-second countdown with the microphone never
/// opened and nothing sent anywhere. It now genuinely listens, reports live input
/// level so the waveform reacts to the user's voice, and sends the transcript to
/// the AI service for emotion detection — so if the microphone path is broken,
/// onboarding is where it surfaces rather than mid-call.
///
/// Built on `speech_to_text`, which the app already depends on, so this adds no
/// new native dependency.
///
/// **Known limit:** only the transcript is sent, not the raw audio, so the voice
/// (prosody) half of emotion detection is skipped and only text emotion runs.
/// Sending audio would need a recorder package added to the project.
class VoiceCheckService {
  final SpeechToText _speech = SpeechToText();

  /// Live input level, roughly 0..1, for the waveform. Never negative.
  final ValueNotifier<double> level = ValueNotifier<double>(0);

  bool _available = false;
  String _transcript = '';

  /// Ask for the microphone and initialise the engine. False means the voice
  /// check cannot run — the caller should let the user move on rather than trap
  /// them on this screen.
  Future<bool> prepare() async {
    try {
      _available = await _speech.initialize(
        onError: (e) {
          if (kDebugMode) debugPrint('VoiceCheck: speech error — ${e.errorMsg}');
        },
        onStatus: (s) {
          if (kDebugMode) debugPrint('VoiceCheck: status $s');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceCheck: initialize failed — $e');
      _available = false;
    }
    return _available;
  }

  /// Listen for [duration], updating [level] as the user speaks.
  Future<void> startListening({
    Duration duration = const Duration(seconds: 10),
    String localeId = 'en_US',
  }) async {
    if (!_available) return;
    _transcript = '';
    try {
      await _speech.listen(
        localeId: localeId,
        listenFor: duration,
        pauseFor: duration,
        onResult: (result) {
          _transcript = result.recognizedWords;
        },
        onSoundLevelChange: (raw) {
          // Platforms report this on different scales; normalise into 0..1 so the
          // waveform behaves the same on both.
          final normalised = ((raw + 2) / 12).clamp(0.0, 1.0);
          level.value = normalised;
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceCheck: listen failed — $e');
    }
  }

  /// Stop listening and send what was heard for emotion detection.
  ///
  /// Best-effort throughout: the voice check is a confidence-builder, not a gate,
  /// so a failed network call still returns whatever was transcribed instead of
  /// blocking onboarding.
  Future<VoiceCheckResult> finish() async {
    try {
      await _speech.stop();
    } catch (_) {
      // Already stopped, or never started.
    }
    level.value = 0;

    final transcript = _transcript.trim();
    if (transcript.isEmpty) return VoiceCheckResult.empty;

    final emotion = await _detectEmotion(transcript);
    return VoiceCheckResult(transcript: transcript, dominantEmotion: emotion);
  }

  Future<String?> _detectEmotion(String text) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.aiBaseUrl}${ApiConstants.aiDetectEmotion}',
      );
      // Multipart: the endpoint takes `text` and `audio_file` as form fields.
      final request = http.MultipartRequest('POST', url)
        ..fields['text'] = text;

      final headers = await aiAuthHeaders();
      headers.remove('Content-Type'); // multipart sets its own boundary
      request.headers.addAll(headers);

      final streamed = await request.send().timeout(
            const Duration(seconds: 15),
          );
      if (streamed.statusCode != 200) return null;

      final body = jsonDecode(await streamed.stream.bytesToString());
      final dominant = body['dominant_emotion'];
      return dominant is String && dominant.isNotEmpty ? dominant : null;
    } catch (e) {
      if (kDebugMode) debugPrint('VoiceCheck: emotion detection failed — $e');
      return null;
    }
  }

  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // Nothing to cancel.
    }
    level.value = 0;
  }

  void dispose() {
    level.dispose();
  }
}
