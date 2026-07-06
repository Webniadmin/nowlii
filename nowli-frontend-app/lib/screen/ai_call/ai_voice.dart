import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/services/ai_call_service.dart';
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
  bool _showTimeWarning = false;
  bool _showMuteWarning = false;
  bool _showWrapUpDialog = false;
  bool _questCompleted = false;
  bool _isHandlingAiResponse = false;
  
  // Typing animation
  bool _showTypingAnimation = false;
  String _typedText = '';
  Timer? _typingTimer;
  int _typingIndex = 0;
  final String _typingMessage = "You're doing great – keep it going";
  
  // AI Call integration
  final AiCallService _aiCallService = AiCallService();
  AiSession? _currentSession;
  String _aiResponse = '';
  EmotionData? _currentEmotion;
  bool _isListening = false;
  
  // Speech recognition and TTS
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _speechEnabled = false;
  
  // TTS Queue Processing
  final List<String> _ttsQueue = [];
  bool _isSpeaking = false;
  
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
    _totalDuration = const Duration(minutes: 5);
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
    
    // Initialize speech and TTS
    _initializeSpeech();
    _initializeTts();
    _initializeAudioStreaming();
    
    // Create AI session
    _createAiSession();
    
    _startCall();
    
    // Auto-start listening after a short delay
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted && !_isMuted) {
        _startListening();
      }
    });
    
    // Start periodic check to ensure listening is active
    _startListeningCheck();
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
  
  Future<void> _createAiSession() async {
    try {
      final session = await _aiCallService.createSession(
        userName: 'User', // You can get this from user profile
        systemName: 'Aria',
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
    
    // Don't start listening if TTS is still speaking
    if (_isSpeaking) {
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
            
            if (mounted) {
              setState(() {
                _liveTranscription = recognizedText;
              });
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
          listenFor: Duration(minutes: 10), // Extended to 10 minutes to match call duration
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
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }
  
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
  
  Future<void> _sendMessageToAi(String message) async {
    if (message.isEmpty || _isHandlingAiResponse) return;
    
    _isHandlingAiResponse = true;
    
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
          
          // Update progress
          _progressController.value = _elapsedTime.inSeconds / _totalDuration.inSeconds;
          
          // Check for 5 minute mark to show typing animation
          if (_elapsedTime.inSeconds == 300 && !_showTypingAnimation) {
            _startTypingAnimation();
          }
          
          // Check for warning (1 minute before end)
          if (_elapsedTime.inSeconds == (_totalDuration.inSeconds - 60) && !_showTimeWarning) {
            _showTimeWarning = true;
          }
          
          // Quest completed
          if (_elapsedTime.inSeconds >= _totalDuration.inSeconds) {
            _onQuestComplete();
          }
        });
      }
    });
  }

  void _startTypingAnimation() {
    setState(() {
      _showTypingAnimation = true;
      _typedText = '';
      _typingIndex = 0;
    });
    
    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_typingIndex < _typingMessage.length) {
        setState(() {
          _typedText = _typingMessage.substring(0, _typingIndex + 1);
          _typingIndex++;
        });
      } else {
        timer.cancel();
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

  void _addTenMinutes() {
    setState(() {
      _totalDuration = Duration(minutes: _totalDuration.inMinutes + 5);
      _showTimeWarning = false;
    });
    
    // Show success popup
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
                decoration: BoxDecoration(
                  color: const Color(0xFF4542EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                '5 more minutes added',
                style: TextStyle(
                  color: const Color(0xFF011F54),
                  fontSize: 20,
                  fontFamily: 'Work Sans',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can now talk to me 5 more minutes!',
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
    _timer?.cancel();
    _typingTimer?.cancel();
    _listeningCheckTimer?.cancel(); // Cancel listening check timer
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

  Color get _backgroundColor {
    if (_questCompleted) return const Color(0xFFCCFFAA);
    if (_showTimeWarning) return const Color(0xFFFF8F26);
    return const Color(0xFF91BBF9);
  }

  Color get _timerColor {
    if (_questCompleted) return const Color(0xFF3BB64B);
    if (_showTimeWarning) return const Color(0xFFFF8F26);
    return const Color(0xFF4542EB);
  }
  
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
                          _questCompleted ? 'Answer emails ✉️ ✓' : 'Answer emails 📧',
                          style: AppsTextStyles.black24Uppercase,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _questCompleted
                                ? 'Take a deep breath - you did great.\nI\'ll be here when you\'re ready for the next one.'
                                : _showTypingAnimation
                                    ? _typedText
                                    : _totalDuration.inMinutes > 5
                                        ? 'New energy, new ${_totalDuration.inMinutes} minutes!'
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
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                children: [
                                  Text(
                                    _formatDuration(_elapsedTime),
                                    style: TextStyle(
                                      color: _timerColor,
                                      fontSize: 52,
                                      fontFamily: 'Wosker',
                                      fontWeight: FontWeight.w400,
                                      height: 0.80,
                                    ),
                                  ),
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
                                  Text(
                                    _formatDuration(_totalDuration),
                                    style: TextStyle(
                                      color: _timerColor.withOpacity(0.5),
                                      fontSize: 52,
                                      fontFamily: 'Wosker',
                                      fontWeight: FontWeight.w400,
                                      height: 0.80,
                                    ),
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
                    SizedBox(
                      width: 335,
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
                                    color: _isListening 
                                        ? Colors.red.withOpacity(0.2)
                                        : _isMuted 
                                            ? const Color(0xFFFFE5E5) 
                                            : const Color(0xFFC3DBFF),
                                    shape: BoxShape.circle,
                                    border: _isListening 
                                        ? Border.all(color: Colors.red, width: 3)
                                        : null,
                                  ),
                                  child: Icon(
                                    _isMuted ? Icons.mic_off : Icons.mic,
                                    color: _isListening 
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
              
              // Time warning popup
              if (_showTimeWarning && !_questCompleted)
                _buildTimeWarningPopup(),
              
              // Mute warning
              if (_showMuteWarning)
                _buildMuteWarning(),
              
              // Wrap up dialog
              if (_showWrapUpDialog)
                _buildWrapUpDialog(),
              
              // Test input dialog (for web testing)
              if (_showTestInput)
                _buildTestInputDialog(),
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

  Widget _buildTimeWarningPopup() {
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
          shadows: [
            BoxShadow(
              color: Color(0x070A0C12),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call ending soon!',
              style: TextStyle(
                color: const Color(0xFF011F54),
                fontSize: 20,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can add 5 more minutes to your call!',
              style: TextStyle(
                color: const Color(0xFF595754),
                fontSize: 14,
                fontFamily: 'Work Sans',
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addTenMinutes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: const Color(0xFF011F54)),
                  const SizedBox(width: 8),
                  Text(
                    'Add 5 minutes',
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w900,
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
