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
import 'package:permission_handler/permission_handler.dart';

class AiVoice extends StatefulWidget {
  const AiVoice({super.key});

  @override
  State<AiVoice> createState() => _AiVoiceState();
}

class _AiVoiceState extends State<AiVoice> with TickerProviderStateMixin {
  // Call duration policy. The backend is the source of truth for the daily call *count*;
  // these constants govern the in-call *timer* the user sees. Initial 5 minutes, with a
  // single optional +2.5 minute extension → 7.5 minutes maximum.
  static const Duration _initialDuration = Duration(minutes: 5);
  static const Duration _extensionDuration = Duration(minutes: 2, seconds: 30);

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
  bool _showThirtySecWarning = false; // 30 seconds left
  int _speechTimeoutStreak = 0; // consecutive "can't hear you" speech errors (no audio)
  bool _micHintShown = false;   // show the "check your microphone" hint at most once per streak
  int _countdownValue = 0; // >0 during the final 10-second countdown

  // Backend daily-limit gate (authoritative). The call timeline only starts after the
  // backend authorizes the call via POST /api/voice-calls/start/.
  final VoiceCallService _voiceCallService = VoiceCallService();
  bool _authorizing = true; // checking the daily limit with the backend
  bool _callBlocked = false; // limit reached or the check failed
  String _blockMessage = '';
  int? _callId; // server-side VoiceCall id, for the end report
  bool _callEndReported = false;

  // AI Call integration
  final AiCallService _aiCallService = AiCallService();
  AiSession? _currentSession;
  String _aiResponse = '';
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

  // Barge-in: let the user interrupt the AI mid-reply for a fluid conversation.
  // The mic stays open while the AI speaks; real user speech stops the AI.
  // Voice barge-in: the mic stays open while the AI speaks; a real user phrase stops it.
  // REQUIRES hardware echo cancellation (a real phone) OR headphones on the emulator —
  // otherwise the mic hears the AI's own TTS and the AI interrupts itself. (Tap-to-
  // interrupt in _toggleListening works regardless, as a manual fallback.)
  static const bool _bargeInEnabled = true;
  // Ignore 1-word blips (echo / noise / TTS tail); require a short real phrase.
  static const int _bargeInMinWords = 2;
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

    // Gate the call on the backend daily limit before starting anything.
    _authorizeAndBegin();
  }

  /// Ask the backend to register a new call (this enforces the per-user daily limit).
  /// Only if the backend authorizes it do we begin the call; otherwise we show a
  /// blocking message and leave the screen.
  Future<void> _authorizeAndBegin() async {
    final result = await _voiceCallService.startCall();
    if (!mounted) return;

    if (result.outcome == VoiceCallStartOutcome.allowed) {
      _callId = result.callId;
      setState(() => _authorizing = false);
      _beginCall();
    } else {
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
          final errorMsg = error.errorMsg?.toLowerCase() ?? '';
          
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
        // Add a small delay to avoid picking up TTS tail or system sounds
        await Future.delayed(Duration(milliseconds: 1000)); // Increased delay
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

  Future<void> _createAiSession() async {
    try {
      final userName = await _resolveUserName();
      final companionName = await _resolveCompanionName();
      final session = await _aiCallService.createSession(
        userName: userName,
        systemName: companionName,
        language: 'en',
      );
      
      if (session != null) {
        if (mounted) {
            setState(() {
            _currentSession = session;
            });
        }
        print('✅ Session created: ${session.sessionId}');
        // Optional: you can manually test by calling _sendMessageToAi("Hello, are you there?");
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

            // Barge-in: the user started talking while the AI is speaking or its reply
            // is still streaming. Require a short real phrase (>= _bargeInMinWords) so a
            // single-word blip / echo / TTS tail doesn't cut the AI off. Stops the AI now;
            // the final-result branch below then sends this turn normally.
            final wordCount = recognizedText
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .length;
            if (_bargeInEnabled &&
                (_isSpeaking || _isHandlingAiResponse) &&
                wordCount >= _bargeInMinWords &&
                !_bargeInterrupt) {
              _interruptAiForBargeIn();
            }

            // If this is a final result and we have text, send it immediately
            if (result.finalResult && recognizedText.isNotEmpty && !_isHandlingAiResponse) {
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
            if (level >= _micSpeakingThreshold) {
              _markMicActive();
            } else {
              _scheduleMicInactive();
            }
          },
          listenFor: Duration(minutes: 5), // Matches the 5-min base call duration (TD-010)
          pauseFor: Duration(seconds: 30), // Increased pause tolerance to 30 seconds
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
      if (!_isPaused && mounted) {
        setState(() {
          _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);

          // Update progress relative to the current total (grows if the call is extended).
          _progressController.value = _elapsedTime.inSeconds / _totalDuration.inSeconds;

          // Time-based notifications, all measured against the *remaining* time so they
          // adapt automatically to the extended 7.5-minute maximum when used.
          final remaining = _totalDuration.inSeconds - _elapsedTime.inSeconds;

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
          } else if (remaining <= 60) {
            // 1 minute left (offers the one-time extension while it is still unused).
            _showOneMinuteWarning = true;
          }
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
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
      _showThirtySecWarning = false;
      _countdownValue = 0;
    });

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
        // Pass session ID to call summary screen
        if (_currentSession != null) {
          context.go('${AppRoutespath.callSummary}?sessionId=${_currentSession!.sessionId}');
        } else {
          context.go(AppRoutespath.callSummary);
        }
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
    
    // Navigate to call summary with session ID
    if (mounted) {
      if (_currentSession != null) {
        context.go('${AppRoutespath.callSummary}?sessionId=${_currentSession!.sessionId}');
      } else {
        context.go(AppRoutespath.callSummary);
      }
    }
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
    _timer?.cancel();
    _listeningCheckTimer?.cancel(); // Cancel listening check timer
    _micOffTimer?.cancel(); // UI-TD-001: cancel the mic-icon debounce timer
    _progressController.dispose();
    _pulseController.dispose();
    _testInputController.dispose();
    _audioStreamSubscription?.cancel();
    _audioStreamService.dispose();
    try {
      _speech.stop();
      _flutterTts.stop();
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
                        const SizedBox(height: 40),

                        // Title Section
                        Text(
                          _questCompleted ? 'All done ✓' : 'Let\'s talk 💬',
                          style: AppsTextStyles.black24Uppercase,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _questCompleted
                                ? 'Take a deep breath - you did great.\nI\'ll be here when you\'re ready for the next one.'
                                : _extensionUsed
                                    ? 'New energy — a little more time together!'
                                    : 'You\'re doing great — keep it going',
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
                                onTap: () {
                                  if (!_isMuted) {
                                    _toggleListening();
                                  }
                                },
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
              if (_callBlocked)
                _buildBlockedOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWithProgress(Size size) {
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
                width: 320 + (pulseValue * 40),
                height: 320 + (pulseValue * 40),
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
                width: 300 + (pulseValue * 20),
                height: 300 + (pulseValue * 20),
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
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: _progressController.value,
                strokeWidth: 16,
                backgroundColor: _timerColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(_timerColor),
              ),
            ),
            
            // Inner glow
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _timerColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            
            // Avatar image with scale animation
            Transform.scale(
              scale: 1.0 + (pulseValue * 0.05),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: Assets.svgImages.callStarted.image().image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // In-call notice card, shared style (same cream card the mute/time popups used).
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

  // 1 minute left. Offers the one-time +2.5 min extension while it is still unused.
  Widget _buildOneMinuteWarning() {
    return _noticeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _noticeTitle('1 minute left'),
          const SizedBox(height: 12),
          _noticeBody(_extensionUsed
              ? 'Your call is wrapping up soon.'
              : 'Your call is wrapping up. You can add 2.5 more minutes once.'),
          if (!_extensionUsed) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addExtension,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 18, color: Color(0xFF011F54)),
                  SizedBox(width: 8),
                  Text(
                    'Add 2.5 minutes',
                    style: TextStyle(
                      color: Color(0xFF011F54),
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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
                  _sendMessageToAi(message);
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
