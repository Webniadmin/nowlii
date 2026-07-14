import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to Apps/subscriptions on the Django backend. The backend owns the
/// decreasing-price-then-free lifecycle; this service just fetches/activates it.
/// Payment is a Phase-1 MOCK (activate) — real Apple IAP / Google Play Billing comes later.
class SubscriptionService {
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': ApiConstants.contentType,
        'Accept': ApiConstants.accept,
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      };

  /// The public price schedule (phases + free-after-month) for the paywall UI.
  Future<SubscriptionPlan?> getPlan() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionPlan}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        return SubscriptionPlan.fromJson(jsonDecode(res.body));
      }
      print('❌ getPlan failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('❌ getPlan error: $e');
      return null;
    }
  }

  /// The caller's current subscription status (phase, price, access).
  Future<SubscriptionStatus?> getMyStatus() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionMe}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        return SubscriptionStatus.fromJson(jsonDecode(res.body));
      }
      print('❌ getMyStatus failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('❌ getMyStatus error: $e');
      return null;
    }
  }

  /// Phase-1 MOCK activation (no real charge). Returns the updated status.
  Future<SubscriptionStatus?> activateMock() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionActivate}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        return SubscriptionStatus.fromJson(jsonDecode(res.body));
      }
      print('❌ activate failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('❌ activate error: $e');
      return null;
    }
  }

  /// Cancel a paid subscription (lifetime-free access is kept). Returns the updated status.
  Future<SubscriptionStatus?> cancel() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionCancel}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        return SubscriptionStatus.fromJson(jsonDecode(res.body));
      }
      print('❌ cancel failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('❌ cancel error: $e');
      return null;
    }
  }
}
