import 'dart:convert';
import 'package:nowlii/api/session.dart';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/insights_models.dart';
import 'package:nowlii/services/subscription_service.dart';

class InsightsService {
  // Helper to print long strings in chunks
  void _printLongString(String text) {
    final pattern = RegExp('.{1,800}'); // 800 chars per line
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  Future<String?> _getAuthToken() async {
    return Session.accessToken();
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
        // 402 = free trial over / not subscribed → flip the cached entitlement so the
        // next navigation lands on the paywall.
        if (response.statusCode == 402) {
          await SubscriptionService.markAccessRevoked();
        }
        return null;
      }
    } catch (e) {
      print('❌ Error fetching insights: $e');
      print('==========================================\n');
      return null;
    }
  }

  /// Mark one or more weekdays as intentional rest days so they're no longer counted as
  /// "skipped" in Insights. Returns true on success. `action` is 'add' (default), 'remove'
  /// or 'set'.
  Future<bool> markRestDays(List<String> days, {String action = 'add'}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.insightsRestDays}'),
            headers: {
              'Content-Type': ApiConstants.contentType,
              'Accept': ApiConstants.accept,
              'Authorization': 'Bearer $token',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'days': days, 'action': action}),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ markRestDays error: $e');
      return false;
    }
  }
}
