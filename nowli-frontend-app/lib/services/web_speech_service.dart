import 'package:flutter/foundation.dart' show kIsWeb;

class WebSpeechService {
  static bool isSupported() {
    // Only available on web
    return false;
  }

  static void speak(String text) {
    // Not supported on mobile
    print('⚠️ Web TTS not available on mobile');
  }

  static void stopSpeaking() {
    // Not supported on mobile
  }

  static Future<String?> startListening() async {
    // Not supported on mobile
    print('⚠️ Web Speech Recognition not available on mobile');
    return null;
  }
}
