import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/api/api_constant.dart';

class SubtaskService {
  // Env-driven base URL (set via --dart-define BASE_URL; see ApiConstants).
  static const String baseUrl = '${ApiConstants.baseUrl}/api';

  /// Reads the logged-in user's JWT from storage (saved at login).
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  /// Generate subtasks based on quest category/title
  /// 
  /// [category] - The quest title/category to generate subtasks for
  /// 
  /// Returns a list of generated subtask strings, or null if failed
  Future<List<String>?> generateSubtasks(String category) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/subtasks/generate/');

      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'category': category,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract tasks array from response
        if (data['tasks'] != null && data['tasks'] is List) {
          return List<String>.from(data['tasks']);
        }
        
        return null;
      } else {
        // Failed to generate subtasks
        return null;
      }
    } catch (e) {
      // Error generating subtasks
      return null;
    }
  }
}
