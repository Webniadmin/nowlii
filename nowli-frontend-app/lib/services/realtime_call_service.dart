import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';

/// One completed exchange (what the user said + what Nowlii replied). Collected during a
/// Realtime call and posted back to nowli-ai at call end so the existing summary / emotion
/// / low-mood endpoints (which read the session's turns) keep working unchanged.
class RealtimeTurn {
  String userMessage;
  String aiReply;
  RealtimeTurn({this.userMessage = '', this.aiReply = ''});
}

/// Live voice call over the OpenAI Realtime API (speech-to-speech) using WebRTC.
///
/// This replaces the old speech-to-text → GPT → text-to-speech pipeline. OpenAI does the
/// turn-taking natively (server VAD) with real barge-in: the user just talks and the model
/// stops. WebRTC gives hardware echo-cancellation, so the model never hears itself.
///
/// Flow: our backend mints a short-lived ephemeral token (the real API key stays server-
/// side) → we open a WebRTC peer connection to OpenAI, send the mic and play the model's
/// audio, and read transcript events over the "oai-events" data channel.
class RealtimeCallService {
  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  MediaStream? _localStream;
  bool _connected = false;
  bool _muted = false;
  bool _dcOpen = false;
  final List<Map<String, dynamic>> _outbox = []; // events queued until the channel opens

  // Transcript collection for the end-of-call summary.
  final List<RealtimeTurn> _turns = [];
  String _pendingUser = '';
  String _pendingAssistant = '';

  // Callbacks that drive the existing call-screen UI (kept identical in look).
  void Function(bool speaking)? onAiSpeakingChange; // AI talking → drives the animation
  void Function(bool listening)? onUserSpeakingChange; // user talking → mic-active icon
  void Function(String text)? onAssistantText; // live assistant caption (_aiResponse)
  void Function(String text)? onUserText; // final user transcript (live caption)
  void Function()? onConnected;
  void Function(String message)? onError;

  bool get isConnected => _connected;
  bool get isMuted => _muted;

  Future<bool> connect(String sessionId) async {
    try {
      // 1) Ephemeral token from our backend (keeps the real OpenAI key server-side).
      final tokenResp = await http
          .post(
            Uri.parse('${ApiConstants.aiBaseUrl}/api/v1/realtime/token'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'session_id': sessionId}),
          )
          .timeout(const Duration(seconds: 15));
      if (tokenResp.statusCode != 200) {
        onError?.call('Realtime token failed (HTTP ${tokenResp.statusCode})');
        return false;
      }
      final tok = jsonDecode(tokenResp.body) as Map<String, dynamic>;
      final ephemeral = tok['client_secret']?.toString();
      final sdpUrl =
          (tok['sdp_url'] ?? 'https://api.openai.com/v1/realtime/calls').toString();
      if (ephemeral == null || ephemeral.isEmpty) {
        onError?.call('Realtime token missing');
        return false;
      }

      // 2) Microphone FIRST. WebRTC's audio processing (echo-cancellation / noise-
      //    suppression / auto-gain) is on by default — that AEC is what stops the model
      //    from hearing (and interrupting) itself. Capturing the mic before creating the
      //    peer connection matches the canonical WebRTC order and avoids native init races.
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      // 3) Peer connection.
      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      });

      // Remote audio (the model's voice) — on native it routes to the audio output
      // automatically once the track arrives; nothing else to attach for audio-only.
      _pc!.onTrack = (RTCTrackEvent event) {
        // Model audio track received — playback is handled by the native audio device.
      };
      _pc!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _connected = false;
        }
      };

      // 4) Add the mic track(s) to the connection.
      for (final track in _localStream!.getAudioTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }

      // 4) Data channel for events (transcripts, speech start/stop).
      final dcInit = RTCDataChannelInit()..ordered = true;
      _dc = await _pc!.createDataChannel('oai-events', dcInit);
      _dc!.onMessage = (RTCDataChannelMessage msg) => _handleEvent(msg.text);
      _dc!.onDataChannelState = (state) {
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          _dcOpen = true;
          for (final m in _outbox) {
            _send(m);
          }
          _outbox.clear();
        }
      };

      // 5) Offer / answer SDP exchange with OpenAI (ephemeral token as Bearer).
      final offer = await _pc!.createOffer({});
      await _pc!.setLocalDescription(offer);

      // NOTE: no ?model= query param — the model is already bound to the ephemeral session
      // (client_secret). Passing it again makes /v1/realtime/calls return 409 Conflict.
      final sdpResp = await http
          .post(
            Uri.parse(sdpUrl),
            headers: {
              'Authorization': 'Bearer $ephemeral',
              'Content-Type': 'application/sdp',
            },
            body: offer.sdp,
          )
          .timeout(const Duration(seconds: 20));
      if (sdpResp.statusCode != 200 && sdpResp.statusCode != 201) {
        onError?.call('Realtime SDP failed (HTTP ${sdpResp.statusCode})');
        return false;
      }
      await _pc!.setRemoteDescription(
        RTCSessionDescription(sdpResp.body, 'answer'),
      );

      // Route to the loudspeaker for a hands-free call (best-effort).
      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (_) {}

      _connected = true;
      onConnected?.call();
      return true;
    } catch (e) {
      onError?.call('Realtime connect error: $e');
      return false;
    }
  }

  void _handleEvent(String text) {
    Map<String, dynamic> ev;
    try {
      ev = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final type = ev['type']?.toString() ?? '';
    switch (type) {
      case 'input_audio_buffer.speech_started':
        // User started talking. Server VAD will interrupt the model automatically.
        onUserSpeakingChange?.call(true);
        onAiSpeakingChange?.call(false);
        break;
      case 'input_audio_buffer.speech_stopped':
        onUserSpeakingChange?.call(false);
        break;
      case 'conversation.item.input_audio_transcription.completed':
        final t = ev['transcript']?.toString().trim() ?? '';
        if (t.isNotEmpty) {
          _pendingUser = t;
          onUserText?.call(t);
        }
        break;
      case 'response.created':
        _pendingAssistant = '';
        onAiSpeakingChange?.call(true);
        break;
      case 'response.output_audio_transcript.delta':
      case 'response.audio_transcript.delta':
        _pendingAssistant += ev['delta']?.toString() ?? '';
        onAssistantText?.call(_pendingAssistant);
        break;
      case 'response.output_audio_transcript.done':
      case 'response.audio_transcript.done':
        final t = ev['transcript']?.toString() ?? _pendingAssistant;
        _pendingAssistant = t.trim();
        if (_pendingAssistant.isNotEmpty) onAssistantText?.call(_pendingAssistant);
        break;
      case 'response.done':
        onAiSpeakingChange?.call(false);
        if (_pendingUser.isNotEmpty || _pendingAssistant.isNotEmpty) {
          _turns.add(RealtimeTurn(
            userMessage: _pendingUser,
            aiReply: _pendingAssistant,
          ));
          _pendingUser = '';
          _pendingAssistant = '';
        }
        break;
      case 'error':
        final err = ev['error'];
        final msg = (err is Map) ? (err['message']?.toString() ?? 'error') : text;
        onError?.call('Realtime error: $msg');
        break;
    }
  }

  void setMuted(bool muted) {
    _muted = muted;
    for (final t in _localStream?.getAudioTracks() ?? const []) {
      t.enabled = !muted;
    }
  }

  void _send(Map<String, dynamic> event) {
    try {
      _dc?.send(RTCDataChannelMessage(jsonEncode(event)));
    } catch (_) {}
  }

  void _enqueue(Map<String, dynamic> event) {
    if (_dcOpen) {
      _send(event);
    } else {
      _outbox.add(event);
    }
  }

  /// Ask Nowlii to open the conversation with a short warm greeting (spoken).
  void greet(String userName) {
    final who = userName.trim().isEmpty ? '' : ' $userName';
    _enqueue({
      'type': 'response.create',
      'response': {
        'instructions':
            'Greet$who warmly in one short, natural sentence and gently ask how they are doing right now.',
      },
    });
  }

  /// Inject a user message (e.g. seed the quest context) and let Nowlii respond.
  void sendUserText(String text) {
    _enqueue({
      'type': 'conversation.item.create',
      'item': {
        'type': 'message',
        'role': 'user',
        'content': [
          {'type': 'input_text', 'text': text},
        ],
      },
    });
    _enqueue({'type': 'response.create'});
  }

  /// Push the collected transcript to nowli-ai so the summary / emotion / low-mood
  /// endpoints keep working. Call this at call end BEFORE fetching the insights.
  Future<void> flushTranscript(String sessionId) async {
    final turns = [..._turns];
    if (_pendingUser.isNotEmpty || _pendingAssistant.isNotEmpty) {
      turns.add(RealtimeTurn(userMessage: _pendingUser, aiReply: _pendingAssistant));
    }
    if (turns.isEmpty) return;
    try {
      await http
          .post(
            Uri.parse('${ApiConstants.aiBaseUrl}/api/v1/session/turns'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'session_id': sessionId,
              'turns': turns
                  .map((t) => {
                        'user_message': t.userMessage,
                        'ai_reply': t.aiReply,
                      })
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      // Best-effort: the call still finalizes without the summary transcript.
    }
  }

  Future<void> disconnect() async {
    _connected = false;
    try {
      await _dc?.close();
    } catch (_) {}
    try {
      for (final t in _localStream?.getAudioTracks() ?? const []) {
        await t.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    _dc = null;
    _pc = null;
    _localStream = null;
  }
}
