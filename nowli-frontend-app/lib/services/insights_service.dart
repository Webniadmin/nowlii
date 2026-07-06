import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/insights_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightsService {
  // Helper to print long strings in chunks
  void _printLongString(String text) {
    final pattern = RegExp('.{1,800}'); // 800 chars per line
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<InsightsResponse?> getInsights() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token found');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getInsights}');
      
      print('\n========== INSIGHTS API ==========');
      print('🌐 URL: $url');
      print('🔑 Token: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body:');
      _printLongString(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Insights data received');
        print('==========================================\n');
        return InsightsResponse.fromJson(data);
      } else {
        print('❌ Failed to fetch insights: ${response.statusCode}');
        print('==========================================\n');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching insights: $e');
      print('==========================================\n');
      return null;
    }
  }
}
