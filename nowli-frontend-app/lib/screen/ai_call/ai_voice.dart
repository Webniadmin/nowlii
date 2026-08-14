import 'package:nowlii/widget/nowlii_avatar.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/services/ai_call_service.dart';
import 'package:nowlii/services/voice_call_service.dart';
import 'package:nowlii/api/storage.dart';
import 'package:nowlii/models/ai_call_models.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:nowlii/services/audio_stream_service.dart';
import 'package:nowlii/services/call_duration.dart';
import 'package:nowlii/services/call_reminder_service.dart';
import 'package:nowlii/services/call_time_announcer.dart';
import 'package:nowlii/services/realtime_call_service.dart';
import 'package:nowlii/services/spark_state.dart';
import 'package:nowlii/services/spark_state_store.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

class AiVoice extends StatefulWidget {
  /// Optional quest title. When launched from a quest whose "Enable call" flag is on,
  /// this is passed as conversation context so the companion knows the task.
  final String? questTitle;

  /// Set when the call was started from a scheduled reminder, so the backend can close that
  /// plan out. It does not affect the daily limit — a planned call queues for it like any
  /// other and gets the same 429 when the day's calls are gone.
  final int? scheduledCallId;

  const AiVoice({super.key, this.questTitle, this.scheduledCallId});

  @override
  State<AiVoice> createState() => _AiVoiceState();
}

class _AiVoiceState extends State<AiVoice>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Call duration policy. The backend is the source of truth for the daily call *count*;
  // these constants govern the in-call *timer* the user sees. Initial 5 minutes, with a
  // single optional +2.5 minute extension → 7.5 minutes maximum.
  // Shared with the screens that quote these lengths back to the user (trial screen,
  // onboarding step 7, the quest call button) so they cannot drift apart.
  static const Duration _initialDuration = kCallInitialDuration;
  static const Duration _extensionDuration = kCallExtensionDuration;

  // The "Add 2.5 minutes" card appears with this much time left.
  static const int _extensionPromptSeconds = 60;
  // Nowlii says it out loud this many seconds BEFORE that card appears, so the user hears
  // the option coming instead of noticing a card mid-sentence — and knows the call ends by
  // itself if they ignore it.
  static const int _spokenWarningLeadSeconds = 10;
  // How often the model is quietly told how much time is left, so it can answer "how long
  // do we have?" truthfully. One item per minute is negligible against the call's cost.
  static const int _timeContextIntervalSeconds = 60;

  // UI-TD-001: mic sound level (rms) above this ≈ the user is speaking. The
  // platform values are roughly dB on Android; the icon lights on voice activity.
  static const double _micSpeakingThreshold = 2.0;

  // Timer management
  late Duration _totalDuration;
  late Duration _elapsedTime;
  Timer? _timer;
  Timer? _listeningCheckTimer; // New timer to check listening state
  bool _isPaused = false;
  bool _isMuted = false;

  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;

  // State flags
  bool _showMuteWarning = false;
  bool _showWrapUpDialog = false;
  bool _questCompleted = false;
  bool _isHandlingAiResponse = false;

  // Call duration / limit notifications
  bool _extensionUsed = false; // the +2.5 min extension can be used at most once
  bool _showStartNotice = false; // "this call lasts up to N minutes" on connect
  bool _showOneMinuteWarning = false; // 1 minute left (offers the extension if unused)
  // "Wrap up" dismisses that card and lets the call run out normally. Without this flag the
  // dismissal would not stick: the per-second tick re-sets _showOneMinuteWarning to true on
  // every tick between 60s and 31s left, so the card would reappear a second later.
  bool _oneMinuteWarningDismissed = false;
  bool _showThirtySecWarning = false; // 30 seconds left
  // Owns the "when does Nowlii mention the clock" rules (fires once, re-arms on extension).
  // Kept as a separate object so those rules are unit-tested — see call_time_announcer.dart.
  final CallTimeAnnouncer _timeAnnouncer = CallTimeAnnouncer(
    promptSeconds: _extensionPromptSeconds,
    leadSeconds: _spokenWarningLeadSeconds,
    contextIntervalSeconds: _timeContextIntervalSeconds,
  );
  int _speechTimeoutStreak = 0; // consecutive "can't hear you" speech errors (no audio)
  bool _micHintShown = false;   // show the "check your microphone" hint at most once per streak
  int _countdownValue = 0; // >0 during the final 10-second countdown

  // Backend daily-limit gate (authoritative). The call timeline only starts after the
  // backend authorizes the call via POST /api/voice-calls/start/.
  final VoiceCallService _voiceCallService = VoiceCallService();
  bool _authorizing = true; // checking the daily limit with the backend
  bool _callBlocked = false; // limit reached or the check failed
  String _blockMessage = '';
  bool _connecting = false; // realtime: connecting / waiting for Nowlii's first words
  bool _callStarted = false; // realtime: timer started (on Nowlii's first words)
  int? _callId; // server-side VoiceCall id, for the end report
  bool _callEndReported = false;

  // Which of today's sparks this call is, for the header counter. Filled from the `start/`
  // response (it reports the quota *after* this call was counted), so it costs no extra
  // request. Stays `unknown` — and the counter stays hidden — if that read gave us nothing.
  SparkState _sparks = const SparkState.unknown();

  // The companion's name, for the subtitle. Resolved from the profile, never hardcoded.
  String _companionName = 'Fuzzy';

  // AI Call integration
  final AiCallService _aiCallService = AiCallService();
  AiSession? _currentSession;
  String _aiResponse = '';

  // Realtime (OpenAI speech-to-speech) engine. When _useRealtime is true the live call
  // runs over WebRTC with native turn-taking/barge-in (smooth, ChatGPT-like) instead of
  // the old speech-to-text → GPT → text-to-speech pipeline below. The old pipeline is kept
  // intact as a fallback (flip this to false). Design + all features are unchanged either
  // way — only the audio engine differs. The summary still works: we feed the Realtime
  // transcript into the nowli-ai session at call end (see _reportCallEnd).
  final RealtimeCallService _realtime = RealtimeCallService();
  bool _useRealtime = true;
  EmotionData? _currentEmotion;
  bool _isListening = false;

  // UI-TD-001: debounced visual state for the mic button. The icon follows real
  // speaking activity — active immediately when the user speaks, and returns to
  // normal only after ~1s of silence — instead of tracking the raw speech_to_text
  // lifecycle (`_isListening` flips on every pause, which made the icon flicker).
  // Recognition/restart logic is unchanged; this only drives the icon.
  bool _micActive = false;
  Timer? _micOffTimer;

  // Speech recognition and TTS
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _speechEnabled = false;
  
  // TTS Queue Processing
  final List<String> _ttsQueue = [];
  bool _isSpeaking = false;

  // Hands-free "barge-in": the mic stays OPEN while the AI speaks so the user can cut it
  // off just by talking — no button press. The hard part is echo: without perfect hardware
  // echo-cancellation the mic also hears the AI's OWN voice, and naively that makes the AI
  // interrupt itself non-stop. We defeat that with TWO guards so the AI can NEVER interrupt
  // itself, while a real human voice still stops it instantly:
  //   1) CONTENT match — we know exactly what the AI is currently saying (`_aiResponse`).
  //      A transcription made mostly of the AI's own words is echo → ignored. Only speech
  //      with enough NEW words (not in the AI's output) counts as the user talking.
  //   2) LOUDNESS gate — the user speaking into the phone is louder than the AI's speaker
  //      bleed, so we also require the recent mic level to cross a threshold.
  // Tap-to-interrupt (_toggleListening) still works as a manual fallback.
  static const bool _bargeInEnabled = true;
  // A real interruption needs at least this many words total AND this many NEW words
  // (words the AI is not currently saying), so the AI's own echo never trips it.
  static const int _bargeInMinWords = 2;
  static const int _bargeInMinNovelWords = 2;
  static const double _bargeInNovelRatio = 0.5; // >=50% of heard words must be new
  // Recent mic loudness must exceed this to allow a barge-in while the AI is speaking —
  // the user's voice is louder than the AI's speaker echo. Tune per device if needed.
  static const double _bargeInLevelThreshold = 2.5;
  double _recentMicLevel = 0.0; // most recent mic sound level (rms-ish), for the loudness gate
  bool _micLevelReported = false; // some platforms never report levels; only gate on loudness if they do
  bool _bargeInterrupt = false; // set when the user interrupts; breaks the SSE loop

  // Live audio streaming
  final AudioStreamService _audioStreamService = AudioStreamService();
  StreamSubscription<String>? _audioStreamSubscription;
  String _liveTranscription = '';
  
  // Manual input for testing (especially on web)
  final TextEditingController _testInputController = TextEditingController();
  bool _showTestInput = false;

  @override
  void initState() {
    super.initState();
    _totalDuration = _initialDuration;
    _elapsedTime = Duration.zero;

    // Keep the screen awake for the whole call: if the screen sleeps mid-call the WebRTC
    // connection drops and the call is lost. Released in dispose().
    WidgetsBinding.instance.addObserver(this); // re-assert it when we come back to the front
    _keepScreenAwake();

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // The subtitle greets the user in their companion's name, so resolve it up front.
    // Best-effort: the fallback is already a sensible name, so a failed read changes nothing.
    _resolveCompanionName().then((name) {
      if (mounted) setState(() => _companionName = name);
    });

    // Gate the call on the backend daily limit before starting anything.
    _authorizeAndBegin();
  }

  /// Hold the screen on for the duration of the call.
  ///
  /// `WakelockPlus.enable()` sets `FLAG_KEEP_SCREEN_ON` on the current window, so the flag
  /// belongs to the window and is lost whenever the app leaves the foreground — coming back
  /// from a notification, another app, or the recents switcher returns with the screen free
  /// to sleep again. So this is re-asserted on resume, not set once in initState.
  ///
  /// It is also verified rather than fired and forgotten: a silently failed enable is
  /// exactly the case the user reports as "the screen still locked and the call died".
  Future<void> _keepScreenAwake() async {
    try {
      await WakelockPlus.enable();
      final on = await WakelockPlus.enabled;
      if (!on) {
        // One retry — some OEM ROMs drop the first request right after a permission dialog.
        await WakelockPlus.enable();
        print('⚠️ Wakelock did not take on the first try; retried. '
            'Now: ${await WakelockPlus.enabled}');
      }
    } catch (e) {
      print('⚠️ Wakelock enable failed: $e — the screen may sleep and drop the call');
    }
  }

  Future<void> _releaseScreenAwake() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      print('⚠️ Wakelock disable failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Only while the call is actually running — once it is over, let the screen sleep.
    if (state == AppLifecycleState.resumed && !_questCompleted) {
      _keepScreenAwake();
    }
  }

  /// Ask the backend to register a new call (this enforces the per-user daily limit).
  /// Only if the backend authorizes it do we begin the call; otherwise we show a
  /// blocking message and leave the screen.
  Future<void> _authorizeAndBegin() async {
    final result =
        await _voiceCallService.startCall(scheduledCallId: widget.scheduledCallId);
    if (!mounted) return;

    if (result.outcome == VoiceCallStartOutcome.allowed) {
      _callId = result.callId;
      // The start response already carries the fresh allowance — use it for the header
      // counter and hand it to the shared store so the home screen is right on the way back.
      final sparks = SparkState(limit: result.limit, remaining: result.remaining);
      SparkStateStore.instance.adopt(
        limit: result.limit,
        remaining: result.remaining,
      );
      setState(() {
        _sparks = sparks;
        _authorizing = false;
      });
      _beginCall();
    } else {
      // A 429 is the backend telling us the allowance is gone — record that, so the home
      // screen shows the out-of-sparks card on the way back instead of a swipe button that
      // leads straight to this same refusal. A network error says nothing, so it changes
      // nothing.
      if (result.outcome == VoiceCallStartOutcome.limitReached) {
        SparkStateStore.instance.adopt(limit: result.limit, remaining: 0);
      }
      setState(() {
        _authorizing = false;
        _callBlocked = true;
        _blockMessage = result.outcome == VoiceCallStartOutcome.limitReached
            ? "You've reached your daily limit of AI calls.\nCome back tomorrow for more."
            : "Couldn't start the call right now.\nPlease check your connection and try again.";
      });
      // Give the user a moment to read the message, then leave the call screen.
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutespath.homeScreen);
        }
      });
    }
  }

  /// Start the AI session, the timer and listening — only after the call is authorized.
  void _beginCall() {
    if (_useRealtime) {
      _beginRealtimeCall();
      return;
    }

    // Initialize speech and TTS
    _initializeSpeech();
    _initializeTts();
    _initializeAudioStreaming();

    // Create AI session
    _createAiSession();

    _startCall();

    // Notify the user of the max duration as soon as the call connects.
    _showStartDurationNotice();

    // Auto-start listening after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_isMuted) {
        _startListening();
      }
    });

    // Start periodic check to ensure listening is active
    _startListeningCheck();
  }

  /// Realtime (OpenAI speech-to-speech) call. Same screen/design/features; only the audio
  /// engine differs. OpenAI handles turn-taking + barge-in natively over WebRTC, so there
  /// is no client-side STT/TTS or barge-in heuristics here.
  Future<void> _beginRealtimeCall() async {
    try {
      await _startRealtimeCall();
    } catch (e, st) {
      print('❌ Realtime start crashed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _callBlocked = true;
        _blockMessage = "Couldn't start the voice call.\n$e";
      });
    }
  }

  Future<void> _startRealtimeCall() async {
    // Show a "connecting" indicator until Nowlii actually starts talking. The call timer is
    // NOT started here — it starts on her first words (_onRealtimeStarted) so the timed
    // duration reflects the real conversation, not the connection/setup wait.
    if (mounted) setState(() => _connecting = true);

    // WebRTC's getUserMedia does NOT prompt for the mic on its own — request it up front,
    // otherwise the native audio capture fails hard (crash) on Android.
    if (!kIsWeb) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (!mounted) return;
        setState(() {
          _callBlocked = true;
          _blockMessage =
              "Microphone permission is required for the call.\nEnable it in Settings and try again.";
        });
        return;
      }
      // Let the audio subsystem settle after the permission grant before WebRTC captures
      // the mic — capturing the instant RECORD_AUDIO is granted can crash the native ADM.
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
    }

    // Create the nowli-ai session first — we need its id to mint the Realtime token, and it
    // keeps the end-of-call summary/emotion endpoints working (we feed the transcript in).
    await _createAiSession();
    if (!mounted) return;
    final sessionId = _currentSession?.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      setState(() {
        _callBlocked = true;
        _blockMessage =
            "Couldn't reach the voice service.\nPlease check your connection and try again.";
      });
      return;
    }

    // Wire the engine's events to the existing UI state (animation, caption, mic icon).
    _realtime
      ..onAiSpeakingChange = (speaking) {
        if (!mounted) return;
        // First time Nowlii speaks → drop the connecting overlay and start the timer.
        if (speaking) _onRealtimeStarted();
        setState(() {
          _isSpeaking = speaking;
          if (speaking) _markMicActive();
        });
      }
      ..onUserSpeakingChange = (listening) {
        if (!mounted) return;
        setState(() {
          _isListening = listening;
          if (listening) _markMicActive();
        });
      }
      ..onAssistantText = (text) {
        if (!mounted) return;
        setState(() => _aiResponse = text);
      }
      ..onUserText = (text) {
        if (!mounted) return;
        setState(() => _liveTranscription = text);
      }
      ..onError = (message) {
        print('❌ Realtime: $message');
      };

    final ok = await _realtime.connect(sessionId);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _connecting = false;
        _callBlocked = true;
        _blockMessage =
            "Couldn't start the voice call right now.\nPlease check your connection and try again.";
      });
      return;
    }

    // Safety net: if Nowlii's first words don't arrive (rare event delay), drop the
    // connecting overlay and start the timer anyway after a few seconds.
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_callStarted) _onRealtimeStarted();
    });

    // Seed quest context if launched from a quest, otherwise let Nowlii open warmly.
    final questTitle = widget.questTitle?.trim() ?? '';
    final userName = await _resolveUserName();
    if (questTitle.isNotEmpty) {
      _realtime.sendUserText(
        "I'm starting my task now: $questTitle. "
        "Please keep me company and help me stay focused.",
      );
    } else {
      _realtime.greet(userName);
    }
  }

  /// Runs once, the moment Nowlii first starts talking (or after the fallback timeout):
  /// hides the connecting indicator and starts the call timer — so the timed duration
  /// reflects the real conversation, not the connection wait.
  void _onRealtimeStarted() {
    if (_callStarted) return;
    _callStarted = true;
    if (mounted) setState(() => _connecting = false);
    _startCall();
    _showStartDurationNotice();
    // Give the model the clock up front, so it is time-aware from the first turn rather
    // than only once the first minute boundary passes.
    _sendTimeContext(_totalDuration.inSeconds);
  }

  void _showStartDurationNotice() {
    setState(() => _showStartNotice = true);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showStartNotice = false);
    });
  }

  /// Report the end of the call to the backend (duration + whether it was extended).
  /// Guarded so it only fires once; the backend end record is idempotent anyway.
  Future<void> _reportCallEnd() async {
    if (_callEndReported || _callId == null) return;
    _callEndReported = true;

    // Capture the AI call insights (emotion breakdown + low-mood phrases) in ONE GPT-free
    // call while the nowli-ai session is still in memory (it isn't persisted there and is
    // dropped on restart), then hand them to the backend end record. Best-effort — on any
    // failure the call still finalizes without this data.
    Map<String, double>? emotionBreakdown;
    String? dominantEmotion;
    List<Map<String, dynamic>>? lowMoodPhrases;
    final sessionId = _currentSession?.sessionId;
    if (sessionId != null && sessionId.isNotEmpty) {
      // Realtime: hand the collected transcript to nowli-ai FIRST so the insight/summary
      // endpoints (which read the session's turns) have the conversation to analyze.
      if (_useRealtime) {
        await _realtime.flushTranscript(sessionId);
      }
      final data = await _aiCallService.getCallInsights(sessionId);
      final raw = data?['emotion_breakdown'];
      if (raw is Map) {
        emotionBreakdown = raw.map(
          (k, v) => MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0),
        );
        dominantEmotion = data?['dominant_emotion']?.toString();
      }
      final rawPhrases = data?['low_mood_phrases'];
      if (rawPhrases is List) {
        lowMoodPhrases = rawPhrases
            .whereType<Map>()
            .map((m) => {
                  'phrase': m['phrase']?.toString() ?? '',
                  'category': m['category']?.toString() ?? '',
                  'count': (m['count'] is num) ? (m['count'] as num).toInt() : 1,
                })
            .where((m) => (m['phrase'] as String).isNotEmpty)
            .toList();
      }
    }

    _voiceCallService.endCall(
      callId: _callId!,
      durationSeconds: _elapsedTime.inSeconds,
      extensionUsed: _extensionUsed,
      emotionBreakdown: emotionBreakdown,
      dominantEmotion: dominantEmotion,
      lowMoodPhrases: lowMoodPhrases,
    );

    // This call just consumed one of the day's two. Re-lay the reminders so any call still
    // scheduled for today is re-checked against the quota — if it can no longer run, its
    // reminder becomes the "move it to tomorrow" one instead of inviting the user into a
    // call the backend would refuse. This is the moment that keeps that wording honest:
    // spending a call always happens with the app open.
    unawaited(CallReminderService.instance.sync());
  }
  
  void _startListeningCheck() {
    _listeningCheckTimer?.cancel();
    _listeningCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      // Check if we should be listening but aren't
      if (mounted && 
          !_isListening && 
          !_isMuted && 
          !_isPaused && 
          !_isHandlingAiResponse && 
          !_isSpeaking &&
          _currentSession != null &&
          !_questCompleted) {
        print('⚠️ Listening check: Not listening when we should be. Restarting...');
        _startListening();
      }
    });
  }
  
  Future<void> _initializeAudioStreaming() async {
    if (!kIsWeb) {
      final initialized = await _audioStreamService.initialize();
      if (initialized) {
        print('✅ Live audio streaming ready');
      }
    }
  }
  
  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    try {
      // Check microphone permission first
      if (!kIsWeb) {
        final micPermission = await Permission.microphone.status;
        print('🎤 Microphone permission status: $micPermission');
        
        if (!micPermission.isGranted) {
          print('⚠️ Requesting microphone permission...');
          final result = await Permission.microphone.request();
          
          if (!result.isGranted) {
            print('❌ Microphone permission denied');
            _speechEnabled = false;
            
            // Show error to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Microphone permission is required for voice input'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () {
                      openAppSettings();
                    },
                  ),
                ),
              );
            }
            return;
          }
        }
      }
      
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          print('❌ Speech error: $error');
          
          // Check if it's a "no match" error (user paused speaking)
          final errorMsg = error.errorMsg.toLowerCase();
          
          if (errorMsg.contains('no_match') || errorMsg.contains('no match')) {
            print('⚠️ No speech detected, will restart listening...');
            // Don't stop listening, just restart after a short delay
            if (mounted && !_isMuted && !_isHandlingAiResponse && !_isPaused) {
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted && !_isMuted && !_isHandlingAiResponse && !_isPaused && !_isListening) {
                  print('🔄 Auto-restarting listening after no_match error');
                  _startListening();
                }
              });
            }
          } else {
            // For other errors, stop listening
            print('❌ Permanent error, stopping: $errorMsg');
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
            // When speech repeatedly can't be heard (e.g. no mic audio is reaching the
            // app — a silent/disabled microphone), surface a one-time hint instead of
            // looping in silence. Reset by the first recognized words (see onResult).
            if (errorMsg.contains('timeout') ||
                errorMsg.contains('no_speech') ||
                errorMsg.contains('audio')) {
              _speechTimeoutStreak++;
              if (_speechTimeoutStreak >= 2 && !_micHintShown && mounted) {
                _micHintShown = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("I can't hear you — check that your microphone is on."),
                    backgroundColor: Color(0xFFFF8F26),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            }
          }
        },
        onStatus: (status) {
          print('📊 Speech status: $status');
          // Don't auto-restart, let TTS completion handle it
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }

            // UI-TD-001: user paused → debounce the mic icon off (~1s), not instantly.
            _scheduleMicInactive();

            // Auto-restart if not handling AI response and not muted
            if (status == 'notListening' && !_isHandlingAiResponse && !_isMuted && !_isPaused && mounted) {
              Future.delayed(Duration(milliseconds: 800), () {
                if (mounted && !_isHandlingAiResponse && !_isMuted && !_isPaused && !_isListening) {
                  print('🔄 Auto-restarting listening after notListening status');
                  _startListening();
                }
              });
            }
          }
        },
      );
      
      if (_speechEnabled) {
        print('✅ Speech recognition initialized successfully');
      } else {
        print('⚠️ Speech recognition not available on this device');
      }
    } catch (e) {
      print('❌ Speech initialization error: $e');
      _speechEnabled = false;
    }
  }
  
  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
      
      // Set completion handler to know when TTS finishes
      _flutterTts.setCompletionHandler(() {
        print('🔊 TTS completed');
        // TTS queue will handle the next item or resume listening
      });
      
      _flutterTts.setErrorHandler((msg) {
        print('❌ TTS error: $msg');
      });
    } catch (e) {
      print('TTS initialization error (may not be supported on web): $e');
    }
  }
  
  void _speakText(String text) {
    if (_isMuted || text.trim().isEmpty) return;
    _ttsQueue.add(text.trim());
    if (!_isSpeaking) {
      _processTtsQueue();
    }
  }

  /// Split text into lowercase word tokens (letters/digits only) for echo comparison.
  List<String> _wordTokens(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  /// True when a transcription heard *while the AI is speaking* looks like the real user
  /// talking rather than the mic picking up the AI's own TTS. Echo is made of the AI's own
  /// words (`_aiResponse`), so we require enough NEW words AND a loud-enough mic level.
  /// This is the guard that stops the AI interrupting itself while still allowing the user
  /// to barge in hands-free.
  bool _isLikelyUserInterruption(String transcription) {
    final heard = _wordTokens(transcription);
    if (heard.length < _bargeInMinWords) return false;
    final aiWords = _wordTokens(_aiResponse).toSet();
    final novel = heard.where((w) => !aiWords.contains(w)).length;
    if (novel < _bargeInMinNovelWords) return false;
    if (novel / heard.length < _bargeInNovelRatio) return false;
    // Loudness gate — but only if this platform actually reports mic levels, otherwise a
    // permanently-zero level would block every voice interruption. Content match still holds.
    if (_micLevelReported && _recentMicLevel < _bargeInLevelThreshold) return false;
    return true;
  }

  /// True when a transcription is (near-)verbatim the AI's own words — i.e. speaker echo
  /// picked up right as/after the AI spoke. Used to make sure such echo is never sent back
  /// as a user turn (which would make the AI talk to itself in a loop).
  bool _isEchoOfAi(String text) {
    final heard = _wordTokens(text);
    if (heard.isEmpty) return false;
    final aiWords = _wordTokens(_aiResponse).toSet();
    if (aiWords.isEmpty) return false;
    final overlap = heard.where((w) => aiWords.contains(w)).length;
    return overlap / heard.length >= 0.8; // ~verbatim echo of the AI's own words
  }

  /// Barge-in: the user started talking while the AI was speaking/streaming.
  /// Stop the AI immediately (TTS + any in-flight reply) so the user is heard.
  Future<void> _interruptAiForBargeIn() async {
    print('✋ Barge-in: user interrupted the AI');
    _bargeInterrupt = true;        // breaks the SSE loop in _sendMessageToAi
    _isHandlingAiResponse = false; // let the incoming user turn through
    _ttsQueue.clear();
    _isSpeaking = false;
    try {
      if (!kIsWeb) await _flutterTts.stop();
    } catch (e) {
      print('Error stopping TTS on barge-in: $e');
    }
  }

  Future<void> _processTtsQueue() async {
    if (_ttsQueue.isEmpty) {
      _isSpeaking = false;
      print('🔇 TTS queue empty, all speech completed');
      // If AI stream finished and we are done speaking, auto-resume listening after a small delay
      if (!_isHandlingAiResponse && !_isMuted && _currentSession != null && !_isPaused && mounted) {
        // Brief delay to avoid picking up the TTS tail, then resume listening quickly so
        // the user can reply without a noticeable gap.
        await Future.delayed(Duration(milliseconds: 300));
        if (!_isHandlingAiResponse && !_isMuted && _currentSession != null && !_isPaused && mounted && !_isListening) {
          print('✅ Ready to listen again');
          _startListening();
        }
      }
      return;
    }
    
    _isSpeaking = true;
    final text = _ttsQueue.removeAt(0);

    // Barge-in: keep the mic open while the AI speaks so the user can interrupt.
    if (_bargeInEnabled && !_isListening && !_isMuted && !_isPaused &&
        _currentSession != null && !_questCompleted && mounted) {
      _startListening();
    }

    try {
      if (kIsWeb) {
        print('🔊 [Web] Speaking: $text');
        await Future.delayed(Duration(milliseconds: text.length * 50));
      } else {
        print('🔊 Speaking: "$text"');
        await _flutterTts.speak(text);
        print('✅ Finished speaking: "$text"');
      }
    } catch (e) {
      print('TTS Error: $e');
    } finally {
      // Process next item
      if (mounted) {
        _processTtsQueue();
      }
    }
  }
  
  /// Resolve the real user identity for the AI session from the stored auth state /
  /// profile — never a hardcoded name. Falls back through profile name → auth username →
  /// a neutral greeting placeholder (only if the user somehow has neither).
  Future<String> _resolveUserName() async {
    final storage = StorageService();
    final profile = await storage.getProfileData();
    final profileName = profile?.name.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;
    final username = (await storage.getUsername())?.trim() ?? '';
    if (username.isNotEmpty) return username;
    return 'there';
  }

  /// Resolve the companion (Nowlii) name for the AI session from the stored profile —
  /// custom name if set, else the chosen predefined companion. Falls back to 'Fuzzy'
  /// so the AI always has a name to introduce itself with.
  Future<String> _resolveCompanionName() async {
    final storage = StorageService();
    final profile = await storage.getProfileData();
    final custom = profile?.customNowliiName?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    final predefined = profile?.nowliiName?.trim() ?? '';
    if (predefined.isNotEmpty) return predefined;
    return 'Fuzzy';
  }

  /// Resolve the companion's voice ('Male'/'Female') from the stored profile so the AI call
  /// speaks in the voice the user chose for their companion. Empty when unset → the AI
  /// service falls back to its default voice.
  Future<String> _resolveCompanionVoice() async {
    final storage = StorageService();
    final profile = await storage.getProfileData();
    return profile?.voice.trim() ?? '';
  }

  /// Topics the user asked the companion not to raise (Settings → AI Personalization).
  /// Read from the cached profile so the choice applies to this call even offline; the
  /// backend folds them into the call persona.
  Future<List<String>> _resolveRestrictedTopics() async {
    final profile = await StorageService().getProfileData();
    return profile?.restrictedTopics ?? const [];
  }

  Future<void> _createAiSession() async {
    try {
      final userName = await _resolveUserName();
      final companionName = await _resolveCompanionName();
      final companionVoice = await _resolveCompanionVoice();
      final restrictedTopics = await _resolveRestrictedTopics();
      final session = await _aiCallService.createSession(
        userName: userName,
        systemName: companionName,
        language: 'en',
        voice: companionVoice,
        restrictedTopics: restrictedTopics,
      );
      
      if (session != null) {
        if (mounted) {
            setState(() {
            _currentSession = session;
            });
        }
        print('✅ Session created: ${session.sessionId}');
        // Optional: you can manually test by calling _sendMessageToAi("Hello, are you there?");

        // Quest context: if this call was started from a quest ("Enable call" on),
        // seed the conversation so the companion knows the task and can keep the user
        // focused. Delayed so it doesn't clash with the start notice / auto-listen.
        // Quest seeding is handled by the Realtime engine in _beginRealtimeCall; only the
        // old SSE pipeline seeds it here.
        final questTitle = widget.questTitle?.trim() ?? '';
        if (questTitle.isNotEmpty && !_useRealtime) {
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted && _currentSession != null) {
              _sendMessageToAi(
                "I'm starting my task now: $questTitle. "
                "Please keep me company and help me stay focused.",
              );
            }
          });
        }
      } else {
        print('⚠️ Failed to create session - API may be unavailable');
        // Continue without session for UI testing
      }
    } catch (e) {
      print('❌ Error creating session: $e');
      // Continue without session for UI testing
    }
  }
  
  Future<void> _startListening() async {
    if (_isMuted) return;

    // Barge-in: we intentionally DO NOT bail out while the AI is speaking — the mic
    // must stay open during TTS so the user can interrupt. (Previously this returned
    // early when _isSpeaking, which made barge-in impossible.)
    if (!_bargeInEnabled && _isSpeaking) {
      print('⏸️ TTS is speaking, waiting to start listening...');
      return;
    }

    // Don't start if already listening
    if (_isListening) {
      print('⚠️ Already listening, skipping...');
      return;
    }
    
    print('🎤 Starting microphone input...');
    
    setState(() {
      _isListening = true;
      _liveTranscription = '';
    });
    
    if (kIsWeb) {
      print('🌐 Using Web Speech API');
    } else {
      // Use speech_to_text for mobile
      print('🎤 Starting speech recognition...');
      
      // Check if speech recognition is available
      if (!_speechEnabled) {
        print('⚠️ Speech recognition not initialized, initializing now...');
        await _initializeSpeech();
      }
      
      if (!_speechEnabled) {
        print('❌ Speech recognition not available');
        setState(() {
          _isListening = false;
        });
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone not available. Please check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Don't re-initialize, just start listening directly
      try {
        print('✅ Starting to listen...');
        await _speech.listen(
          onResult: (result) {
            final recognizedText = result.recognizedWords.trim();
            print('📝 Live transcription: "$recognizedText" (final: ${result.finalResult})');

            // UI-TD-001: speaking detected → mic icon active now, cancel pending off.
            // Also clears the "can't hear you" streak (speech is coming through fine).
            if (recognizedText.isNotEmpty) {
              _markMicActive();
              _speechTimeoutStreak = 0;
              _micHintShown = false;
            }
            
            if (mounted) {
              setState(() {
                _liveTranscription = recognizedText;
              });
            }

            // Barge-in: the user started talking while the AI is speaking or its reply is
            // still streaming. We ONLY interrupt when the transcript looks like real user
            // speech (enough NEW words vs. the AI's own words + loud enough) — this is what
            // stops the AI from hearing its own TTS and interrupting itself. Stops the AI
            // now; the final-result branch below then sends this turn normally.
            if (_bargeInEnabled &&
                (_isSpeaking || _isHandlingAiResponse) &&
                !_bargeInterrupt &&
                _isLikelyUserInterruption(recognizedText)) {
              print('✋ Real user interruption detected — stopping the AI');
              _interruptAiForBargeIn();
            }

            // Send a completed user turn. Guards, besides the usual ones:
            //  - !_isSpeaking: never send while the AI's TTS is still playing (that text is
            //    almost certainly the mic hearing the AI — closes the self-reply window).
            //  - !_isEchoOfAi: drop a (near-)verbatim echo of the AI's own words so the AI
            //    can't end up talking to itself.
            if (result.finalResult &&
                recognizedText.isNotEmpty &&
                !_isHandlingAiResponse &&
                !_isSpeaking &&
                !_isEchoOfAi(recognizedText)) {
              print('✅ Final result detected, sending immediately');
              final textToSend = recognizedText;
              if (mounted) {
                setState(() {
                  _liveTranscription = '';
                  _isListening = false;
                });
              }
              _speech.stop();
              _sendMessageToAi(textToSend);
            }
          },
          // UI-TD-001: voice-activity drives the mic icon — active while the user
          // is actually speaking (sound above threshold), off ~1s after they stop.
          onSoundLevelChange: (level) {
            _recentMicLevel = level; // feeds the barge-in loudness gate (_isLikelyUserInterruption)
            if (level > 0) _micLevelReported = true;
            if (level >= _micSpeakingThreshold) {
              _markMicActive();
            } else {
              _scheduleMicInactive();
            }
          },
          listenFor: Duration(minutes: 5), // Matches the 5-min base call duration (TD-010)
          // End the user's turn after a short silence so the AI replies promptly (natural
          // conversation pacing). 30s felt like a long dead-air lag; 3s ends the turn fast
          // without cutting off normal mid-sentence pauses.
          pauseFor: Duration(seconds: 3),
          partialResults: true,
          cancelOnError: false, // Don't cancel on errors
          listenMode: stt.ListenMode.dictation,
          localeId: 'en_US',
        );
      } catch (e) {
        print('❌ Error starting speech recognition: $e');
        if (mounted) {
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not start voice recognition. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _stopListening() async {
    print('🛑 Stopping microphone input...');
    
    setState(() {
      _isListening = false;
    });
    
    if (kIsWeb) {
      print('🌐 Web listening stopped');
    } else {
      try {
        await _speech.stop();
      } catch (e) {
        print('Error stopping speech: $e');
      }
      
      // Send final transcription if available
      if (_liveTranscription.isNotEmpty && !_isHandlingAiResponse) {
        print('📤 Sending final transcription: $_liveTranscription');
        final textToSend = _liveTranscription;
        _liveTranscription = '';
        _sendMessageToAi(textToSend);
      }
    }
  }
  
  void _toggleListening() {
    if (_useRealtime) {
      // Realtime is hands-free (you interrupt just by talking). The mic button becomes a
      // manual mute toggle: mute silences your mic, unmute re-opens it.
      setState(() {
        _isMuted = !_isMuted;
        _realtime.setMuted(_isMuted);
        _isListening = !_isMuted;
      });
      return;
    }
    // Tap-to-interrupt: if the AI is speaking or its reply is still streaming, a tap on
    // the mic stops it and opens the mic so the user can jump in. This is the manual
    // alternative to voice barge-in (which needs hardware echo cancellation) — it works
    // everywhere because the mic only opens AFTER the AI is silenced, so there's no echo.
    if (_isSpeaking || _isHandlingAiResponse) {
      print('✋ Tap-to-interrupt: stopping the AI and listening');
      _interruptAiForBargeIn().then((_) {
        if (mounted) _startListening();
      });
      return;
    }
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  // UI-TD-001: the user is speaking → make the mic icon active immediately and
  // cancel any pending turn-off (so a resumed speech/listening event keeps it on).
  void _markMicActive() {
    _micOffTimer?.cancel();
    if (!_micActive && mounted) {
      setState(() => _micActive = true);
    }
  }

  // UI-TD-001: the user seems to have stopped — don't turn the icon off right away.
  // Start a single ~1s countdown from when speech stopped (do NOT keep resetting it
  // on every silent sample); if speech resumes, _markMicActive cancels it.
  void _scheduleMicInactive() {
    if (!_micActive) return;
    if (_micOffTimer?.isActive ?? false) return; // already counting down
    _micOffTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _micActive = false);
    });
  }
  
  /* TD-009: dead code (unused). Kept commented, not deleted, per cleanup task.
  Future<void> _handleWebVoiceInput() async {
    if (!kIsWeb) return;
    
    print('🎤 Starting web voice input...');
    setState(() {
      _isListening = true;
    });
    
    // Show a dialog for web voice input
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.red),
            SizedBox(width: 8),
            Text('Listening...'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Speak now...'),
            SizedBox(height: 8),
            Text(
              'Click "Stop" when done',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isListening = false;
              });
            },
            child: Text('Stop'),
          ),
        ],
      ),
    );
    
    // Simulate voice input for now (you can implement actual Web Speech API)
    await Future.delayed(Duration(seconds: 3));
    
    if (mounted) {
      Navigator.pop(context);
      setState(() {
        _isListening = false;
      });
      
      // For demo, show input dialog
      _showTestInput = true;
      setState(() {});
    }
  }
  */
  
  Future<void> _sendMessageToAi(String message) async {
    if (message.isEmpty || _isHandlingAiResponse) return;

    _isHandlingAiResponse = true;
    _bargeInterrupt = false; // fresh turn — clear any prior barge-in flag

    // Stop listening immediately to avoid feedback
    await _stopListening();
    
    // Stop any ongoing TTS
    try {
      if (!kIsWeb) {
        await _flutterTts.stop();
      }
    } catch (e) {
      print('Error stopping TTS: $e');
    }
    
    // Clear TTS queue
    _ttsQueue.clear();
    _isSpeaking = false;
    
    // Check if session exists
    if (_currentSession == null) {
      print('⚠️ No active session - attempting to create one...');
      await _createAiSession();
      if (_currentSession == null) {
        print('❌ Cannot send message without session');
        if (mounted) {
            setState(() {
            _aiResponse = 'API connection unavailable. Please check your network and API server.';
            _isHandlingAiResponse = false;
            });
        }
        return;
      }
    }
    
    if (mounted) {
        setState(() {
        _aiResponse = '';
        });
    }
    
    try {
      String currentSentence = '';
      
      await for (var event in _aiCallService.chatStream(
        message: message,
        sessionId: _currentSession!.sessionId,
      )) {
        // Barge-in: the user interrupted mid-stream — stop consuming this reply.
        if (_bargeInterrupt) {
          print('✋ Barge-in during stream — abandoning this reply');
          break;
        }
        if (event.type == StreamEventType.emotion) {
          if (mounted) {
              setState(() {
                _currentEmotion = event.data as EmotionData;
              });
          }
          print('😊 Emotion detected: ${_currentEmotion!.emotionKey} (${_currentEmotion!.score})');
        } else if (event.type == StreamEventType.word) {
          if (mounted) {
              setState(() {
                _aiResponse += '${event.data} ';
              });
          }
          
          currentSentence += '${event.data} ';
          // Add to TTS queue if the word ends a sentence
          if (event.data.toString().contains(RegExp(r'[.!?]'))) {
             _speakText(currentSentence);
             currentSentence = '';
          }
        } else if (event.type == StreamEventType.warning) {
          // Content moderation blocked the user's message. Show a notice + speak a
          // gentle warning; the AI reply is skipped (server sends no 'word' events).
          final warningText = event.data.toString();
          print('⚠️ Moderation warning: $warningText');
          if (mounted) {
            setState(() {
              _aiResponse = warningText;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Let's keep it kind — please avoid inappropriate language."),
                backgroundColor: Color(0xFF4542EB),
                duration: Duration(seconds: 4),
              ),
            );
          }
          _speakText(warningText); // spoken warning; TTS queue resumes listening after
        } else if (event.type == StreamEventType.done) {
          if (currentSentence.trim().isNotEmpty) {
             _speakText(currentSentence);
          }
          final doneData = event.data as DoneEventData;
          print('✅ Response complete: ${doneData.words} words');
        }
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      if (mounted) {
          setState(() {
            _aiResponse = 'Error communicating with AI. Please try again.';
          });
      }
    } finally {
        _isHandlingAiResponse = false;
        print('🏁 AI response handling complete. TTS speaking: $_isSpeaking');
        // TTS queue will handle resuming listening when done
    }
  }

  void _startCall() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || !mounted) return;

      // Time-based notifications are all measured against the *remaining* time so they
      // adapt automatically to the extended 7.5-minute maximum when used.
      final remaining = _totalDuration.inSeconds - (_elapsedTime.inSeconds + 1);

      setState(() {
        _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);

        // Update progress relative to the current total (grows if the call is extended).
        _progressController.value = _elapsedTime.inSeconds / _totalDuration.inSeconds;

        if (remaining <= 0) {
          // Time is up — end the call automatically.
          _countdownValue = 0;
          _onQuestComplete();
        } else if (remaining <= 10) {
          // Final 10 seconds: show the countdown, hide the banners.
          _countdownValue = remaining;
          _showOneMinuteWarning = false;
          _showThirtySecWarning = false;
        } else if (remaining <= 30) {
          // 30 seconds left.
          _showThirtySecWarning = true;
          _showOneMinuteWarning = false;
        } else if (remaining <= _extensionPromptSeconds) {
          // 1 minute left (offers the one-time extension while it is still unused).
          // This branch runs on *every* tick of the last minute, so it must respect a
          // "Wrap up" dismissal — otherwise the card the user just closed comes straight
          // back a second later.
          _showOneMinuteWarning = !_oneMinuteWarningDismissed;
        }
      });

      // Kept out of setState: these talk to the model, which is not a UI concern and must
      // never run from a build.
      if (remaining > 0) _updateAiTimeAwareness(remaining);
    });
  }

  /// Keep Nowlii aware of the clock, and have it warn the user before the call runs out.
  ///
  /// The *when* lives in [CallTimeAnnouncer]; this only carries out what it decides.
  void _updateAiTimeAwareness(int remaining) {
    switch (_timeAnnouncer.onTick(remaining)) {
      case CallTimeCue.speakEndingSoonCanExtend:
        _announceCallEndingSoon(canExtend: true);
      case CallTimeCue.speakEndingSoonFinal:
        _announceCallEndingSoon(canExtend: false);
      case CallTimeCue.sendSilentTimeContext:
        _sendTimeContext(remaining);
      case null:
        break;
    }
  }

  /// Tell the model how much time is left, silently — it must not read this out.
  void _sendTimeContext(int remaining) {
    if (!_useRealtime || !_realtime.isConnected) return;
    final mins = remaining ~/ 60;
    final secs = remaining % 60;
    final left = mins > 0 ? '$mins min ${secs}s' : '${secs}s';
    _realtime.sendSilentContext(
      'Background information only — do not mention it unless the user asks about time: '
      'about $left of this call remains. '
      '${_extensionUsed ? 'It has already been extended and cannot be extended again.' : 'The user can add 2.5 minutes once, by tapping a card that appears near the end.'}',
    );
  }

  /// Nowlii tells the user, out loud and in its own words, that time is nearly up.
  ///
  /// When [canExtend] is false the extension is already spent, so the wording must not
  /// dangle an option that no longer exists.
  void _announceCallEndingSoon({required bool canExtend}) {
    final instructions = canExtend
        ? 'The call has about a minute left. In one short, warm sentence, tell the user a card '
          'will appear on screen that they can tap to add 2.5 more minutes, and that otherwise '
          'the call will end on its own. Do not ask a question.'
        : 'The call has about a minute left and cannot be extended again. In one short, warm '
          'sentence, let the user know you will need to wrap up soon so they can finish their '
          'thought. Do not ask a question.';

    if (_useRealtime) {
      if (_realtime.isConnected) _realtime.speak(instructions);
      return;
    }

    // Legacy speech-to-text/TTS fallback path: no model to instruct, so speak fixed copy.
    _speakText(canExtend
        ? "We have about a minute left. Tap the card on your screen to add two and a half "
          "more minutes — otherwise the call will end on its own."
        : "We're nearly out of time, so let's start wrapping up.");
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_useRealtime) {
        // Realtime: pausing mutes the mic so Nowlii can't hear you; the timer pause is
        // handled by _isPaused in _startCall. Unpausing re-opens the mic.
        _realtime.setMuted(_isPaused || _isMuted);
        return;
      }
      if (_isPaused) {
        // Paused - stop listening
        _stopListening();
      } else {
        // Resumed - restart listening if conditions are met
        if (!_isMuted && !_isHandlingAiResponse && !_isSpeaking) {
          _startListening();
        }
      }
    });
  }

  /* TD-009: dead code (unused). Kept commented, not deleted, per cleanup task.
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _showMuteWarning = true;
        _stopListening();
        
        // Stop TTS and clear queue
        _ttsQueue.clear();
        _isSpeaking = false;
        try {
          if (!kIsWeb) {
            _flutterTts.stop();
          }
        } catch (e) {
          print('TTS stop error: $e');
        }
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showMuteWarning = false;
            });
          }
        });
      } else {
        // Unmuted - restart listening check
        _startListeningCheck();
        // Only start listening if not currently handling AI response
        if (!_isHandlingAiResponse && !kIsWeb) {
          _startListening();
        }
      }
    });
  }
  */

  void _addExtension() {
    // The extension can be used at most once; after that the call is capped at 7.5 min.
    if (_extensionUsed) return;

    setState(() {
      _extensionUsed = true;
      _totalDuration = _totalDuration + _extensionDuration; // 5:00 → 7:30
      _progressController.duration = _totalDuration;
      // Clear the current warnings; they re-appear relative to the new end time.
      _showOneMinuteWarning = false;
      // A dismissal belonged to the old ending. The call now runs 2.5 minutes longer, so
      // the user should still be warned before the real end.
      _oneMinuteWarningDismissed = false;
      _showThirtySecWarning = false;
      _countdownValue = 0;
    });

    // Arm the spoken warning again so the user is told before the *real* end too — this
    // time without offering another extension, since there isn't one.
    _timeAnnouncer.onExtended();
    _sendTimeContext(_totalDuration.inSeconds - _elapsedTime.inSeconds);

    // Show success popup (same style as the existing in-call dialogs)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF4542EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '2.5 more minutes added',
                style: TextStyle(
                  color: const Color(0xFF011F54),
                  fontSize: 20,
                  fontFamily: 'Work Sans',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We can keep talking a little longer!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF595754),
                  fontSize: 16,
                  fontFamily: 'Work Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onQuestComplete() {
    setState(() {
      _questCompleted = true;
    });
    _reportCallEnd();
    _timer?.cancel();
    _listeningCheckTimer?.cancel(); // Stop listening check when quest completes
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Pass session ID + call id to the summary screen (callId lets it persist the
        // generated summary to the backend for this user).
        context.go(_callSummaryRoute());
      }
    });
  }

  void _markAsDone() {
    setState(() {
      _showWrapUpDialog = true;
    });
  }

  void _onWrapUpYes() {
    _reportCallEnd();
    _timer?.cancel();
    _listeningCheckTimer?.cancel(); // Stop listening check
    
    // Navigate to call summary with session ID + call id (see _callSummaryRoute).
    if (mounted) {
      context.go(_callSummaryRoute());
    }
  }

  /// Build the call-summary route, carrying the nowli-ai session id (so the screen can
  /// generate the summary) and the backend call id (so it can persist that summary for
  /// this user). Both are optional — either may be absent if the call never fully started.
  String _callSummaryRoute() {
    final params = <String, String>{
      if (_currentSession != null) 'sessionId': _currentSession!.sessionId,
      if (_callId != null) 'callId': '$_callId',
    };
    if (params.isEmpty) return AppRoutespath.callSummary;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '${AppRoutespath.callSummary}?$query';
  }

  void _onWrapUpContinue() {
    setState(() {
      _showWrapUpDialog = false;
    });
  }

  @override
  void dispose() {
    // Best-effort: if the user leaves the screen mid-call, still record the end.
    _reportCallEnd();
    // Let the screen sleep normally again now that the call is over.
    WidgetsBinding.instance.removeObserver(this);
    _releaseScreenAwake();
    _timer?.cancel();
    _listeningCheckTimer?.cancel(); // Cancel listening check timer
    _micOffTimer?.cancel(); // UI-TD-001: cancel the mic-icon debounce timer
    _progressController.dispose();
    _pulseController.dispose();
    _testInputController.dispose();
    _audioStreamSubscription?.cancel();
    _audioStreamService.dispose();
    _realtime.disconnect(); // tear down the WebRTC call (no-op if not connected)
    try {
      if (!_useRealtime) {
        _speech.stop();
        _flutterTts.stop();
      }
    } catch (e) {
      print('Dispose error: $e');
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  // UI-TD-002: the widest digit's width in the timer font, measured once.
  double? _digitSlotWidth;
  double _measureDigitWidth() {
    if (_digitSlotWidth != null) return _digitSlotWidth!;
    const style = TextStyle(
      fontSize: 52,
      fontFamily: 'Wosker',
      fontWeight: FontWeight.w400,
      height: 0.80,
    );
    double maxWidth = 0;
    for (final d in const ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
      final tp = TextPainter(
        text: TextSpan(text: d, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width > maxWidth) maxWidth = tp.width;
    }
    _digitSlotWidth = maxWidth;
    return maxWidth;
  }

  // UI-TD-002: lay a time string out with each digit centered in a fixed-width
  // slot (the widest digit's width). Same Wosker look, but the width no longer
  // changes as the digits change, so the timer — and the layout — stay put.
  Widget _fixedWidthTime(String text, Color color) {
    final slot = _measureDigitWidth();
    final style = TextStyle(
      color: color,
      fontSize: 52,
      fontFamily: 'Wosker',
      fontWeight: FontWeight.w400,
      height: 0.80,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((ch) {
        final code = ch.codeUnitAt(0);
        final isDigit = code >= 0x30 && code <= 0x39;
        final glyph = Text(ch, style: style);
        return isDigit
            ? SizedBox(width: slot, child: Center(child: glyph))
            : glyph;
      }).toList(),
    );
  }

  // UI-TD-003: removed `_isTimeWarningActive` — the end-of-call warnings no longer
  // recolor the background or the timer, so nothing reads that state anymore.

  Color get _backgroundColor {
    if (_questCompleted) return const Color(0xFFCCFFAA);
    // UI-TD-003: the last-minute warnings no longer tint the background orange —
    // it stays blue. The warning cards and _timerColor are intentionally unchanged.
    return const Color(0xFF91BBF9);
  }

  Color get _timerColor {
    if (_questCompleted) return const Color(0xFF3BB64B);
    // UI-TD-003: the last-minute warnings no longer recolor the timer/progress
    // ring/pulse (they used to turn orange, which made the digits hard to read).
    // Only the notice card signals the warning now; everything else stays put.
    return const Color(0xFF4542EB);
  }
  
  /* TD-009: dead code (unused). Kept commented, not deleted, per cleanup task.
  IconData _getEmotionIcon(String emotionKey) {
    switch (emotionKey.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
      case 'sadness':
        return Icons.sentiment_dissatisfied;
      case 'angry':
      case 'anger':
        return Icons.sentiment_very_dissatisfied;
      case 'fear':
      case 'scared':
        return Icons.warning;
      case 'surprise':
        return Icons.sentiment_neutral;
      case 'calm':
      case 'neutral':
        return Icons.sentiment_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
  
  Color _getEmotionColor(String emotionKey) {
    switch (emotionKey.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Colors.green;
      case 'sad':
      case 'sadness':
        return Colors.blue;
      case 'angry':
      case 'anger':
        return Colors.red;
      case 'fear':
      case 'scared':
        return Colors.orange;
      case 'surprise':
        return Colors.purple;
      case 'calm':
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: _backgroundColor,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 17),

                        // "Spark in progress" + which of today's sparks this is.
                        _buildSparkRow(),

                        const SizedBox(height: 41),

                        // Title Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _callHeadline(),
                            style: AppsTextStyles.extraBold32Centered,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _questCompleted
                                ? 'Take a deep breath - you did great.\nI\'ll be here when you\'re ready for the next one.'
                                : _extensionUsed
                                    ? 'New energy — a little more time together!'
                                    : '$_companionName’s here, you’ve got this',
                            style: AppsTextStyles.regular16l,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const Spacer(),

                        // Avatar with progress
                        _buildAvatarWithProgress(size),
                  
                  const Spacer(),

                  // Quest completed text
                  if (_questCompleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'QUEST\nCOMPLETED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF3BB64B),
                          fontSize: 52,
                          fontFamily: 'Wosker',
                          fontWeight: FontWeight.w400,
                          height: 0.8,
                        ),
                      ),
                    ),

                  // Timer Display
                  if (!_questCompleted)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _togglePause,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC3DBFF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPaused ? Icons.play_arrow : Icons.pause,
                                color: const Color(0xFF4542EB),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // UI-TD-002: render the timer with fixed-width digit slots so
                          // the proportional-digit Wosker font no longer changes the
                          // timer's width (which shifted the whole layout) as it counts.
                          // Non-digit glyphs (':', '/', ' ') are constant-width already.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _fixedWidthTime(
                                      _formatDuration(_elapsedTime), _timerColor),
                                  Text(
                                    ' / ',
                                    style: TextStyle(
                                      color: _timerColor.withOpacity(0.5),
                                      fontSize: 52,
                                      fontFamily: 'Wosker',
                                      fontWeight: FontWeight.w400,
                                      height: 0.80,
                                    ),
                                  ),
                                  _fixedWidthTime(
                                    _formatDuration(_totalDuration),
                                    _timerColor.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Controls
                  if (!_questCompleted)
                    Padding(
                      // Match the horizontal inset of the other full-width containers
                      // (title/timer use horizontal: 20) instead of a fixed 335 width,
                      // which read narrower than the rest on screens wider than 375.
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                // Always toggle: tap to mute, tap again to unmute. (The old
                                // guard skipped the tap while muted, so you could never
                                // unmute.) _toggleListening() flips mute both ways.
                                onTap: _toggleListening,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _micActive
                                        ? Colors.red.withOpacity(0.2)
                                        : _isMuted
                                            ? const Color(0xFFFFE5E5)
                                            : const Color(0xFFC3DBFF),
                                    shape: BoxShape.circle,
                                    border: _micActive
                                        ? Border.all(color: Colors.red, width: 3)
                                        : null,
                                  ),
                                  child: Icon(
                                    _isMuted ? Icons.mic_off : Icons.mic,
                                    color: _micActive
                                        ? Colors.red
                                        : _isMuted
                                            ? Colors.red
                                            : const Color(0xFF4542EB),
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showTestInput = !_showTestInput;
                                  });
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: _showTestInput 
                                        ? const Color(0xFF4542EB) 
                                        : const Color(0xFFC3DBFF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.keyboard,
                                    color: _showTestInput 
                                        ? Colors.white 
                                        : const Color(0xFF4542EB),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _markAsDone,
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: Image.asset(
                                    'assets/images/right_sound.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Mark as done',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF011F54),
                                  fontSize: 12,
                                  fontFamily: 'Work Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Start-of-call notice: maximum duration.
              if (_showStartNotice && !_questCompleted)
                _buildStartNotice(),

              // 1-minute-left warning (offers the one-time extension).
              if (_showOneMinuteWarning && !_questCompleted && _countdownValue == 0)
                _buildOneMinuteWarning(),

              // 30-seconds-left warning.
              if (_showThirtySecWarning && !_questCompleted && _countdownValue == 0)
                _buildThirtySecWarning(),

              // Final 10-second countdown (UI-TD-004: on the shared notice card,
              // no fullscreen overlay).
              if (_countdownValue > 0 && !_questCompleted)
                _buildCountdownNotice(),

              // Mute warning
              if (_showMuteWarning)
                _buildMuteWarning(),

              // Wrap up dialog
              if (_showWrapUpDialog)
                _buildWrapUpDialog(),

              // Test input dialog (for web testing)
              if (_showTestInput)
                _buildTestInputDialog(),

              // Daily-limit gate: checking with the backend / blocked.
              if (_authorizing)
                _buildAuthorizingOverlay(),
              if (_connecting && !_callBlocked)
                _buildConnectingOverlay(),
              if (_callBlocked)
                _buildBlockedOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  /// The width the composition below was drawn at: the outer ring reaches
  /// 320 + 40 at the top of its pulse.
  static const double _callArtExtent = 360.0;

  Widget _buildAvatarWithProgress(Size size) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Every number in this Stack is absolute, and the largest of them is
        // wider than a 320dp phone — so on a narrow screen the outer pulse ring
        // ran past both edges and what breathed was the whole screen rather
        // than a disc on it. Scaling the composition by how much room there
        // actually is keeps every proportion exactly as drawn (at 375 and up
        // `fit` is 1 and nothing changes) while giving the pulse an edge to
        // stop at. This is the same bargain `ResponsiveText` makes for type.
        final available =
            constraints.maxWidth.isFinite ? constraints.maxWidth : size.width;
        final fit = (available / _callArtExtent).clamp(0.0, 1.0);

        return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outermost pulse ring (animated)
            if (!_questCompleted)
              Container(
                width: (320 + (pulseValue * 40)) * fit,
                height: (320 + (pulseValue * 40)) * fit,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [
                      _timerColor.withOpacity(0),
                      _timerColor.withOpacity(0.1 * (1 - pulseValue)),
                    ],
                  ),
                ),
              ),
            
            // Middle pulse ring
            if (!_questCompleted)
              Container(
                width: (300 + (pulseValue * 20)) * fit,
                height: (300 + (pulseValue * 20)) * fit,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.5,
                    colors: [
                      _timerColor.withOpacity(0),
                      _timerColor.withOpacity(0.2 * (1 - pulseValue)),
                    ],
                  ),
                ),
              ),
            
            // Progress ring
            SizedBox(
              width: 280 * fit,
              height: 280 * fit,
              child: CircularProgressIndicator(
                value: _progressController.value,
                strokeWidth: 16 * fit,
                backgroundColor: _timerColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(_timerColor),
              ),
            ),
            
            // Inner glow
            Container(
              width: 250 * fit,
              height: 250 * fit,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _timerColor.withOpacity(0.3),
                    blurRadius: 30 * fit,
                    spreadRadius: 10 * fit,
                  ),
                ],
              ),
            ),
            
            // Avatar image with scale animation
            //
            // Unchanged from the original except for the picture: `callStartedEmpty.png`
            // is `callStarted.png` with the orange character lifted out and the disc
            // underneath restored from `popupSpeking` at matching scale — same canvas,
            // same halos, same disc, same position. The companion is drawn inside at 87,
            // the height the baked-in character measured in this 240 box, and sits within
            // the same `Transform.scale` so it breathes with the disc exactly as before.
            Transform.scale(
              scale: 1.0 + (pulseValue * 0.05),
              child: Container(
                width: 240 * fit,
                height: 240 * fit,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/svg_images/callStartedEmpty.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  child: NowliiAvatar(
                    size: 87 * fit,
                    pose: CompanionPose.speaking,
                  ),
                ),
              ),
            ),
          ],
        );
      },
        );
      },
    );
  }

  // In-call notice card, shared style (same cream card the mute/time popups used).
  /// The screen's headline. The design shows the quest the call was started for
  /// ("Answer emails ✉️"). A spontaneous swipe-to-talk call has no quest behind it, so it
  /// keeps the neutral greeting rather than inventing a title.
  String _callHeadline() {
    if (_questCompleted) return 'All done ✓';
    final quest = widget.questTitle?.trim() ?? '';
    return quest.isNotEmpty ? quest : 'Let\'s talk 💬';
  }

  /// Label S from the design system: Work Sans SemiBold 12.
  static final TextStyle _sparkLabelStyle = GoogleFonts.workSans(
    color: const Color(0xFF011F54),
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.0,
  );

  /// Top row: a live dot and "Spark in progress" on the left, today's counter on the right.
  ///
  /// The counter is absent rather than approximate whenever there is nothing true to show —
  /// an unlimited QA account (`limit: -1`, which would otherwise read "Spark 1 of -1") or a
  /// quota we could not read. The left label is always honest: a call *is* in progress.
  Widget _buildSparkRow() {
    final counter = _sparks.counterLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3BB64B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    // The design's 4px halo: a spread with no blur, so it reads as a ring.
                    BoxShadow(
                      color: Color(0x3345841C),
                      spreadRadius: 4,
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Opacity(
                opacity: 0.75,
                child: Text('Spark in progress', style: _sparkLabelStyle),
              ),
            ],
          ),
          if (counter != null)
            Opacity(
              opacity: 0.80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC3DBFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(counter, style: _sparkLabelStyle),
              ),
            ),
        ],
      ),
    );
  }

  Widget _noticeCard({required Widget child}) {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFFCF1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x070A0C12),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _noticeTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF011F54),
          fontSize: 20,
          fontFamily: 'Work Sans',
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.5,
        ),
      );

  Widget _noticeBody(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF595754),
          fontSize: 14,
          fontFamily: 'Work Sans',
          fontWeight: FontWeight.w400,
          height: 1.6,
        ),
      );

  // Shown on connect: the call's maximum duration.
  Widget _buildStartNotice() {
    return _noticeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _noticeTitle('Let\'s talk!'),
          const SizedBox(height: 12),
          _noticeBody('This call lasts up to ${_initialDuration.inMinutes} minutes.'),
        ],
      ),
    );
  }

  /// "Wrap up" on the ending-soon toast: close the card and let the call finish on its own
  /// clock. It deliberately does **not** hang up — the user asked to be left alone for the
  /// last minute, not cut off — and it does not spend the extension.
  void _dismissOneMinuteWarning() {
    setState(() {
      _showOneMinuteWarning = false;
      _oneMinuteWarningDismissed = true;
    });
  }

  /// One of the two toast buttons. Built from a Container rather than ElevatedButton so the
  /// 44px height and pill radius are exactly the designed ones, with no material elevation.
  Widget _toastButton({
    required String label,
    required Color background,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: borderColor == null
                  ? BorderSide.none
                  : BorderSide(color: borderColor, width: 2),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  /// Shown once with a minute to go: take the one-time +2:30, or wave the card away and let
  /// the call end when it was always going to.
  ///
  /// After the extension has been spent there is no second one to offer, so "+2:30"
  /// disappears and "Wrap up" takes the full width rather than sitting there disabled.
  Widget _buildOneMinuteWarning() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFFCF1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x140A0D12),
              blurRadius: 16,
              offset: Offset(0, 12),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x080A0D12),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFAE3CE),
                shape: BoxShape.circle,
              ),
              child: Assets.svgIcons.sparkClock.svg(width: 26, height: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Call ending soon!',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _extensionUsed
                        ? 'About a minute left. This is a good place to stop.'
                        : 'About a minute left. Take it if you’re mid-thought — '
                            'otherwise this is a good place to stop.',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF595754),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!_extensionUsed) ...[
                        _toastButton(
                          label: '+2:30',
                          background: const Color(0xFFFF8F26),
                          onTap: _addExtension,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _toastButton(
                        label: 'Wrap up',
                        background: const Color(0xFFFFFEF8),
                        borderColor: const Color(0xFFC3DBFF),
                        onTap: _dismissOneMinuteWarning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _extensionUsed
                        ? 'That was this spark’s extension.\n'
                            'Either way you get your receipt.'
                        : 'One extension per spark.\n'
                            'Either way you get your receipt.',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4C586E),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 30 seconds left.
  Widget _buildThirtySecWarning() {
    return _noticeCard(
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF011F54)),
          const SizedBox(width: 12),
          Expanded(child: _noticeTitle('30 seconds left')),
        ],
      ),
    );
  }

  // UI-TD-004: final 10-second countdown, shown on the same notice card as the
  // other end-of-call warnings (counts 10 → 1). Replaces the previous fullscreen
  // overlay.
  Widget _buildCountdownNotice() {
    return _noticeCard(
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF011F54)),
          const SizedBox(width: 12),
          Expanded(child: _noticeTitle('Ending in $_countdownValue…')),
        ],
      ),
    );
  }

  /* UI-TD-004: replaced by _buildCountdownNotice (no fullscreen overlay).
     Kept commented, not deleted, per the preserve-not-delete cleanup rule.
  // Final 10-second countdown, centered over the call.
  Widget _buildCountdownOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(0.15),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ending in',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Work Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_countdownValue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 120,
                  fontFamily: 'Wosker',
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  */

  // Full-screen overlay while the Realtime call is connecting and we wait for Nowlii's
  // first words. It disappears the moment she starts talking (then the timer starts).
  Widget _buildConnectingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF91BBF9),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                color: Color(0xFF4542EB),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 22),
            Text(
              'Connecting…',
              style: TextStyle(
                color: Color(0xFF011F54),
                fontSize: 20,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'One moment — the conversation will\nbegin as soon as you hear a voice.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF011F54),
                fontSize: 14,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full-screen overlay while the backend daily-limit check is in flight.
  Widget _buildAuthorizingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF91BBF9),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Color(0xFF4542EB)),
            SizedBox(height: 20),
            Text(
              'Checking your daily calls…',
              style: TextStyle(
                color: Color(0xFF011F54),
                fontSize: 18,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full-screen overlay when the call is blocked (limit reached or check failed).
  Widget _buildBlockedOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF91BBF9),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_filled, size: 50, color: Color(0xFF4542EB)),
              const SizedBox(height: 16),
              Text(
                _blockMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF011F54),
                  fontSize: 18,
                  fontFamily: 'Work Sans',
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuteWarning() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFFCF1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.mic_off, color: const Color(0xFF011F54)),
            const SizedBox(width: 12),
            Text(
              'You\'re muted',
              style: TextStyle(
                color: const Color(0xFF011F54),
                fontSize: 18,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrapUpDialog() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 50, color: const Color(0xFF4542EB)),
                const SizedBox(height: 16),
                Text(
                  'Wrap up already?',
                  style: TextStyle(
                    color: const Color(0xFF011F54),
                    fontSize: 24,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No rush — but if you\'re done, let\'s mark this quest complete.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF595754),
                    fontSize: 16,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _onWrapUpContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: const Color(0xFF4542EB), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: Text(
                    'Continue a bit longer',
                    style: TextStyle(
                      color: const Color(0xFF4542EB),
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _onWrapUpYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4542EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  child: Text(
                    'Yes, I\'m done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTestInputDialog() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Test Input',
                  style: TextStyle(
                    color: const Color(0xFF011F54),
                    fontSize: 18,
                    fontFamily: 'Work Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showTestInput = false;
                    });
                  },
                  icon: Icon(Icons.close, color: const Color(0xFF011F54)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _testInputController,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final message = _testInputController.text.trim();
                if (message.isNotEmpty) {
                  // Typed input: in Realtime mode send it over the data channel (Nowlii
                  // replies in voice); otherwise use the old SSE path.
                  if (_useRealtime) {
                    _realtime.sendUserText(message);
                  } else {
                    _sendMessageToAi(message);
                  }
                  _testInputController.clear();
                  setState(() {
                    _showTestInput = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4542EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Send to AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Work Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_currentSession != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '✅ Session: ${_currentSession!.sessionId.substring(0, 8)}...',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontFamily: 'Work Sans',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_currentSession == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ No active session',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontFamily: 'Work Sans',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                _testInputController.text = 'Hello, how are you?';
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFF4542EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Quick Test: "Hello"',
                style: TextStyle(
                  color: const Color(0xFF4542EB),
                  fontSize: 14,
                  fontFamily: 'Work Sans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
