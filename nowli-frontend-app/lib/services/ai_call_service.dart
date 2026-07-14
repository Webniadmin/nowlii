import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/ai_call_models.dart';

class AiCallService {
  // Create a new session
  Future<AiSession?> createSession({
    required String userName,
    String systemName = 'Aria',
    String language = 'en',
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.aiBaseUrl}${ApiConstants.createSession}');
      
      print('🎯 Creating AI session at: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
        },
        body: jsonEncode({
          'user_name': userName,
          'system_name': systemName,
          'language': language,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Session creation timeout after 10 seconds');
          throw TimeoutException('Session creation timed out');
        },
      );

      print('📡 Session response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Session created: ${data['session_id']}');
        return AiSession.fromJson(data);
      } else {
        print('❌ Failed to create session: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating session: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        print('🔌 Network issue: Please check if AI server is running and ngrok URL is correct');
      }
      return null;
    }
  }

  /// Fetch the 5-category Top-Emotion breakdown for a finished session.
  /// Best-effort: nowli-ai keeps sessions in memory only, so this must run before the
  /// session is dropped (i.e. right at call end). Returns the raw response map
  /// (with `emotion_breakdown` + `dominant_emotion`) or null on any error.
  Future<Map<String, dynamic>?> getEmotionBreakdown(String sessionId) async {
    try {
      final url = Uri.parse(
          '${ApiConstants.aiBaseUrl}${ApiConstants.aiEmotionBreakdown(sessionId)}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      print('⚠️ emotion-breakdown status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ emotion-breakdown error: $e');
      return null;
    }
  }

  /// One GPT-free call at call end returning BOTH the 5-category emotion breakdown and the
  /// canonical low-mood phrases (`emotion_breakdown`, `dominant_emotion`, `low_mood_phrases`).
  /// Best-effort: nowli-ai keeps sessions in memory only, so this must run before the session
  /// is dropped. Returns the raw response map or null on any error.
  Future<Map<String, dynamic>?> getCallInsights(String sessionId) async {
    try {
      final url = Uri.parse(
          '${ApiConstants.aiBaseUrl}${ApiConstants.aiCallInsights(sessionId)}');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      print('⚠️ call-insights status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ call-insights error: $e');
      return null;
    }
  }

  // Stream chat with emotion detection
  Stream<StreamEvent> chatStream({
    required String message,
    required String sessionId,
  }) async* {
    try {
      print('📤 Sending message: "$message" to session: $sessionId');
      
      final url = Uri.parse('${ApiConstants.aiBaseUrl}${ApiConstants.chatStream}');
      
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': ApiConstants.contentType,
        'Accept': ApiConstants.accept,
        'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
      });
      request.body = jsonEncode({
        'message': message,
        'session_id': sessionId,
      });

      print('🌐 Connecting to: $url');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Chat stream timeout after 15 seconds');
          throw TimeoutException('Chat stream timed out');
        },
      );

      print('📡 Response status: ${streamedResponse.statusCode}');
      
      if (streamedResponse.statusCode == 200) {
        String buffer = '';
        int eventCount = 0;
        
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
          print('📥 Received chunk: ${chunk.substring(0, chunk.length > 100 ? 100 : chunk.length)}...');
          buffer += chunk;
          
          // Process complete events
          while (buffer.contains('\n\n')) {
            final eventEnd = buffer.indexOf('\n\n');
            final eventBlock = buffer.substring(0, eventEnd);
            buffer = buffer.substring(eventEnd + 2);
            
            eventCount++;
            print('🎯 Processing event #$eventCount');
            
            // Parse event
            final lines = eventBlock.split('\n');
            if (lines.length >= 2) {
              final eventLine = lines[0];
              final dataLine = lines[1];
              
              if (eventLine.startsWith('event: ') && dataLine.startsWith('data: ')) {
                final eventType = eventLine.substring(7).trim();
                final eventData = dataLine.substring(6).trim();
                
                print('📋 Event type: $eventType');
                print('📋 Event data: ${eventData.substring(0, eventData.length > 100 ? 100 : eventData.length)}...');
                
                if (eventType == 'emotion') {
                  try {
                    final emotionData = EmotionData.fromJson(jsonDecode(eventData));
                    print('😊 Emotion: ${emotionData.emotionKey} (${emotionData.score})');
                    yield StreamEvent(
                      type: StreamEventType.emotion,
                      data: emotionData,
                    );
                  } catch (e) {
                    print('❌ Error parsing emotion data: $e');
                  }
                } else if (eventType == 'word') {
                  print('💬 Word: $eventData');
                  yield StreamEvent(
                    type: StreamEventType.word,
                    data: eventData,
                  );
                } else if (eventType == 'warning') {
                  // Content moderation blocked the user's message; the server sends
                  // this instead of a reply (followed by 'done', no 'word' events).
                  print('⚠️ Moderation warning: $eventData');
                  yield StreamEvent(
                    type: StreamEventType.warning,
                    data: eventData,
                  );
                } else if (eventType == 'done') {
                  try {
                    final doneData = DoneEventData.fromJson(jsonDecode(eventData));
                    print('✅ Done: ${doneData.words} words, turn ${doneData.turn}');
                    yield StreamEvent(
                      type: StreamEventType.done,
                      data: doneData,
                    );
                  } catch (e) {
                    print('❌ Error parsing done data: $e');
                  }
                }
              }
            }
          }
        }
        print('🏁 Stream completed. Total events: $eventCount');
      } else {
        print('❌ Chat stream failed: ${streamedResponse.statusCode}');
        final responseBody = await streamedResponse.stream.bytesToString();
        print('❌ Response body: $responseBody');
      }
    } catch (e) {
      print('❌ Error in chat stream: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        print('🔌 Network issue: Please check if AI server is running and ngrok URL is correct');
      }
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }
}
