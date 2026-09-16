import 'dart:convert';
import 'dart:ui' as ui;

import 'package:nowlii/api/session.dart';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Talks to Apps/subscriptions on the Django backend. The backend owns the
/// decreasing-price-then-free lifecycle; this service reads it and starts purchases.
///
/// Payment is **Stripe Checkout on the web**, not Apple IAP or Google Play Billing. The
/// reason is the price ladder: it steps down four times over a year, a Play offer carries at
/// most two pricing phases and an Apple introductory offer one, and neither store can move a
/// subscriber to a cheaper plan from the server. A Stripe subscription schedule does all of
/// it. See docs/stripe-payments.md.
///
/// Nothing in this app ever touches a card number — the backend returns a URL and the
/// device's browser does the rest.
class SubscriptionService {
  Future<String?> _getAuthToken() async {
    return Session.accessToken();
  }

  /// The storefront this device is in, e.g. "US". The backend uses it to decide whether a
  /// payment link may be shown at all: linking out to an outside payment page is permitted
  /// in the US and forbidden in most storefronts, so that call belongs on the server.
  ///
  /// Taken from the device's own locale rather than an IP lookup — it is what the user set,
  /// it needs no geo database on the server, and a VPN does not change it.
  static String get _region {
    final locale = ui.PlatformDispatcher.instance.locale;
    return (locale.countryCode ?? '').toUpperCase();
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': ApiConstants.contentType,
        'Accept': ApiConstants.accept,
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
        if (_region.isNotEmpty) 'X-Nowlii-Region': _region,
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
      if (res.statusCode == 401) await Session.reportUnauthorized();
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

  // ── Paying ──────────────────────────────────────────────────────────────────

  /// Start a purchase and open Stripe Checkout in the device's browser.
  ///
  /// Returns null when the browser has taken over, and a message to show when it could not
  /// start. Access does **not** change here: a checkout URL is an invitation to pay, and
  /// only the backend's webhook knows a charge succeeded. The screen that calls this
  /// refreshes the status when the app comes back into focus.
  ///
  /// `LaunchMode.externalApplication` is deliberate and must stay. An outside payment page
  /// has to open in the real browser; an in-app webview is exactly what the stores' rules on
  /// linking out forbid, and shipping one risks the app being pulled.
  Future<String?> startCheckout() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return 'Please sign in again.';
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionCheckout}'),
        headers: _headers(token),
      );
      if (res.statusCode != 200) {
        print('❌ checkout failed: ${res.statusCode} ${res.body}');
        final body = jsonDecode(res.body);
        return (body is Map && body['detail'] is String)
            ? body['detail'] as String
            : 'Could not start checkout. Please try again.';
      }
      final url = (jsonDecode(res.body) as Map)['url'] as String?;
      if (url == null || url.isEmpty) return 'Could not start checkout.';
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      return opened ? null : 'Could not open the payment page.';
    } catch (e) {
      print('❌ checkout error: $e');
      return 'Could not start checkout. Please check your connection.';
    }
  }

  /// Open Stripe's billing portal — cards, invoices and cancelling — in the browser.
  ///
  /// Every page there is Stripe's own, so card details never reach this app and a
  /// cancellation made there is the real one rather than a flag we set and hope matches what
  /// the user is still being charged.
  Future<String?> openBillingPortal() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return 'Please sign in again.';
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionPortal}'),
        headers: _headers(token),
      );
      if (res.statusCode != 200) {
        print('❌ portal failed: ${res.statusCode} ${res.body}');
        return 'Could not open billing. Please try again.';
      }
      final url = (jsonDecode(res.body) as Map)['url'] as String?;
      if (url == null || url.isEmpty) return 'Could not open billing.';
      final opened =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return opened ? null : 'Could not open the billing page.';
    } catch (e) {
      print('❌ portal error: $e');
      return 'Could not open billing. Please check your connection.';
    }
  }

  /// Call off a cancellation that has not taken effect yet.
  ///
  /// Only meaningful between cancelling and the end of the paid period. Someone who
  /// cancelled by accident should not have to lose the rest of the month and buy the plan
  /// again at a rung they had already climbed past.
  Future<SubscriptionStatus?> resume() async {
    try {
      final token = await _getAuthToken();
      if (token == null) return null;
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.subscriptionResume}'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final status = SubscriptionStatus.fromJson(jsonDecode(res.body));
        await cacheAccess(status);
        return status;
      }
      print('❌ resume failed: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      print('❌ resume error: $e');
      return null;
    }
  }

  /// MOCK activation — no real charge. The backend refuses it unless a dev box has
  /// deliberately enabled it, so it does nothing in production. Real purchases go through
  /// [startCheckout].
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
