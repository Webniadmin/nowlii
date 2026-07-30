import 'dart:convert';
import 'package:nowlii/api/session.dart';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to Apps/subscriptions on the Django backend. The backend owns the
/// decreasing-price-then-free lifecycle; this service just fetches/activates it.
/// Payment is a Phase-1 MOCK (activate) — real Apple IAP / Google Play Billing comes later.
class SubscriptionService {
  Future<String?> _getAuthToken() async {
    return Session.accessToken();
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

  /// The caller's current subscription status (phase, price, trial, access).
  ///
  /// This is also what STARTS the free trial: the backend grants it on the first
  /// authenticated call, so hitting this right after login begins the 7 days.
  Future<SubscriptionStatus?> getMyStatus() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionMe}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final status = SubscriptionStatus.fromJson(jsonDecode(res.body));
        await cacheAccess(status);
        return status;
      }
      print('❌ getMyStatus failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('❌ getMyStatus error: $e');
      return null;
    }
  }

  /// Explicitly begin the free trial (the "Let's begin 7 days free" button).
  /// Idempotent — it never re-grants or extends a trial the user already had.
  Future<SubscriptionStatus?> startTrial() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionStartTrial}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final status = SubscriptionStatus.fromJson(jsonDecode(res.body));
        await cacheAccess(status);
        return status;
      }
      print('❌ startTrial failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('❌ startTrial error: $e');
      return null;
    }
  }

  // ── Access cache ────────────────────────────────────────────────────────────
  // The router guard runs on every navigation and cannot afford a network round-trip,
  // so the last known entitlement is cached. The BACKEND is still the authority — it
  // returns 402 on every gated endpoint regardless of what this cache says.

  static const String _kHasAccess = 'sub_has_access';
  static const String _kInTrial = 'sub_in_trial';
  static const String _kTrialDaysLeft = 'sub_trial_days_left';

  Future<void> cacheAccess(SubscriptionStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasAccess, status.hasAccess);
    await prefs.setBool(_kInTrial, status.inTrial);
    await prefs.setInt(_kTrialDaysLeft, status.trialDaysLeft);
  }

  /// Cached entitlement. Defaults to **true** when nothing is cached yet so a slow or
  /// failed status call never locks a paying user out — the backend 402 is the real gate.
  static Future<bool> cachedHasAccess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasAccess) ?? true;
  }

  static Future<int> cachedTrialDaysLeft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kTrialDaysLeft) ?? 0;
  }

  static Future<bool> cachedInTrial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kInTrial) ?? false;
  }

  /// Called when a gated endpoint answers 402 — flips the cache so the next navigation
  /// redirects to the paywall without waiting for a status refresh.
  static Future<void> markAccessRevoked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasAccess, false);
    await prefs.setBool(_kInTrial, false);
    await prefs.setInt(_kTrialDaysLeft, 0);
  }

  /// Wipe the cache on logout so the next account starts clean.
  static Future<void> clearAccessCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHasAccess);
    await prefs.remove(_kInTrial);
    await prefs.remove(_kTrialDaysLeft);
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
        final status = SubscriptionStatus.fromJson(jsonDecode(res.body));
        await cacheAccess(status);      // purchase restores access immediately
        return status;
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
        final status = SubscriptionStatus.fromJson(jsonDecode(res.body));
        await cacheAccess(status);
        return status;
      }
      print('❌ cancel failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('❌ cancel error: $e');
      return null;
    }
  }
}
