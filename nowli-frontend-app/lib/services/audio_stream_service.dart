import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioStreamService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  
  StreamController<String>? _transcriptionController;
  Stream<String>? _transcriptionStream;
  
  // Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => print('❌ Speech error: $error'),
        onStatus: (status) => print('📊 Speech status: $status'),
      );
      
      if (_isInitialized) {
        print('✅ Audio streaming initialized');
      } else {
        print('⚠️ Speech recognition not available');
      }
      
      return _isInitialized;
    } catch (e) {
      print('❌ Failed to initialize audio streaming: $e');
      return false;
    }
  }
  
  // Start live audio streaming (continuous listening)
  Stream<String> startLiveStream() {
    _transcriptionController = StreamController<String>.broadcast();
    _transcriptionStream = _transcriptionController!.stream;
    
    if (!_isInitialized) {
      print('⚠️ Audio streaming not initialized');
      _transcriptionController!.close();
      return _transcriptionStream!;
    }
    
    print('🎤 Starting live audio stream...');
    
    _speech.listen(
      onResult: (result) {
        // Stream partial results for live feel
        if (result.recognizedWords.isNotEmpty) {
          print('🎙️ Live transcription: ${result.recognizedWords}');
          _transcriptionController!.add(result.recognizedWords);
          
          // If final result, we can process it
          if (result.finalResult) {
            print('✅ Final transcription: ${result.recognizedWords}');
          }
        }
      },
      listenFor: Duration(seconds: 30), // Max listening duration
      pauseFor: Duration(seconds: 3), // Pause detection
      partialResults: true, // Enable live streaming
      onSoundLevelChange: (level) {
        // You can use this for visual feedback
        // print('🔊 Sound level: $level');
      },
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
    
    return _transcriptionStream!;
  }
  
  // Stop live streaming
  Future<void> stopLiveStream() async {
    print('🛑 Stopping live audio stream...');
    await _speech.stop();
    await _transcriptionController?.close();
    _transcriptionController = null;
    _transcriptionStream = null;
  }
  
  // Check if currently listening
  bool get isListening => _speech.isListening;
  
  // Get available locales
  Future<List<stt.LocaleName>> getLocales() async {
    return await _speech.locales();
  }
  
  // Dispose
  void dispose() {
    _speech.stop();
    _transcriptionController?.close();
  }
}
