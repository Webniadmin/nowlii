import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/streak_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<StreakResponse?> getStreak() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ No auth token found');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getStreak}');
      
      print('\n========== STREAK API ==========');
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
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Streak data received: ${data['streak']}');
        print('==========================================\n');
        return StreakResponse.fromJson(data);
      } else {
        print('❌ Failed to fetch streak: ${response.statusCode}');
        print('==========================================\n');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching streak: $e');
      print('==========================================\n');
      return null;
    }
  }
}
