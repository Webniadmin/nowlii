import 'package:shared_preferences/shared_preferences.dart';

class EmotionDetectionHelper {
  static const String _lastEmotionDateKey = 'last_emotion_detection_date';
  
  /// Check if emotion detection is needed today
  static Future<bool> shouldShowEmotionDetection() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastEmotionDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    return lastDate != today;
  }
  
  /// Mark emotion detection as completed for today
  static Future<void> markEmotionDetectionComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_lastEmotionDateKey, today);
  }
  
  /// Reset for testing purposes
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastEmotionDateKey);
  }
}
