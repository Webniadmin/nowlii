import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/call_summary_model.dart';

class CallSummaryService {
  Future<CallSummaryResponse?> getSummary(String sessionId) async {
    try {
      final url = Uri.parse('${ApiConstants.aiBaseUrl}/api/v1/chat/summary');
      
      print('\n========== CALL SUMMARY API ==========');
      print('🌐 URL: $url');
      print('📤 Session ID: $sessionId');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'session_id': sessionId,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Summary request timeout after 15 seconds');
          throw Exception('Request timed out');
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Summary data received');
        print('==========================================\n');
        return CallSummaryResponse.fromJson(data);
      } else {
        print('❌ Failed to fetch summary: ${response.statusCode}');
        print('==========================================\n');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching summary: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        print('🔌 Network issue: Please check if AI server is running');
      }
      print('==========================================\n');
      return null;
    }
  }
}
