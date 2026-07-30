import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_constant.dart';
import 'storage.dart';

/// Keeps the user signed in without them noticing.
///
/// Every service used to read `access_token` straight out of storage and send it. Nothing
/// handled a 401 and the stored refresh token was never spent, so when the access token
/// expired the app did not log the user out — it let them in and then failed every request
/// silently: empty quests, empty Insights, refused calls, and no hint that signing in again
/// would fix it.
///
/// Now services ask [accessToken] instead. It checks the token's own expiry locally and
/// refreshes first when needed, so the 401 mostly never happens. [refreshNow] is still there
/// for the case where the server rejects a token we believed was fine (clock skew, a
/// password change, a blacklisted session).
class Session {
  Session._();

  /// Refresh this long before the token actually expires, so a request that takes a moment
  /// to reach the server does not arrive with a just-expired token.
  static const Duration _renewBefore = Duration(minutes: 2);

  static final StorageService _storage = StorageService();

  /// In-flight refresh, shared by every caller.
  ///
  /// This matters more than it looks: the backend rotates refresh tokens and blacklists the
  /// old one. Two refreshes at once and the second presents a token the first has already
  /// blacklisted — which logs the user out. Screens fire several requests together, so this
  /// is the normal case, not an edge case.
  static Future<bool>? _inFlight;

  /// Called when the session is definitively over and the user must sign in again.
  /// Set once at app start so this file stays unaware of routing.
  static void Function()? onSignedOut;

  /// A usable access token, refreshing first if the stored one is expired or nearly so.
  /// Returns null when there is no session at all, or when refreshing failed.
  static Future<String?> accessToken() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return null;
    if (!_isExpiringSoon(token)) return token;

    final refreshed = await refreshNow();
    if (!refreshed) return null;
    return _storage.getAccessToken();
  }

  /// Spend the refresh token for a new pair. Safe to call concurrently — callers share one
  /// request. Returns false when the session cannot be recovered, having signed the user out.
  static Future<bool> refreshNow() {
    return _inFlight ??= _doRefresh().whenComplete(() => _inFlight = null);
  }

  /// A request we believed was authenticated came back 401. Try to recover; sign out if not.
  ///
  /// Checking expiry is not enough on its own. A token can be **rejected while still being
  /// unexpired** — the server's `SECRET_KEY` was rotated (which happened on 2026-07-30 and
  /// broke every installed build), the session was blacklisted, the password changed, or the
  /// account was deleted on another device. In all of those the local `exp` still looks fine,
  /// so nothing would ever trigger a refresh and the app would sit there failing every
  /// request in silence — the exact "app looks broken" symptom this whole file exists to
  /// prevent.
  ///
  /// Returns true if the caller should retry.
  static Future<bool> reportUnauthorized() async {
    // If the token was rejected for a reason that also invalidates the refresh token (a key
    // rotation does), this refresh fails with 401 and signs the user out — which is right.
    return refreshNow();
  }

  static Future<bool> _doRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _endSession();
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tokenRefresh}'),
            headers: {
              'Content-Type': ApiConstants.contentType,
              'accept': ApiConstants.accept,
            },
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final access = data['access'] as String?;
        // Rotation is on, so a new refresh token comes back with it. Storing the old one
        // would leave the app holding a token the server has already blacklisted.
        final rotated = (data['refresh'] as String?) ?? refreshToken;
        if (access == null || access.isEmpty) {
          await _endSession();
          return false;
        }
        await _storage.saveTokens(access, rotated);
        return true;
      }

      // 401 means the refresh token itself is expired, blacklisted or invalid — the session
      // really is over. Any other status is more likely the server having a bad moment, so
      // keep the session and let the caller retry later.
      if (response.statusCode == 401) {
        print('🔒 Refresh token rejected — signing out');
        await _endSession();
      } else {
        print('⚠️ Token refresh failed with ${response.statusCode}; keeping the session');
      }
      return false;
    } catch (e) {
      // Offline or a timeout. Do NOT sign out — the user has done nothing wrong and their
      // session is probably fine; they just have no network right now.
      print('⚠️ Token refresh could not reach the server: $e');
      return false;
    }
  }

  static Future<void> _endSession() async {
    await _storage.clearAll();
    onSignedOut?.call();
  }

  /// Whether this JWT is past its `exp`, or close enough that it will be by the time the
  /// request lands. A malformed token counts as expiring, so we try to refresh rather than
  /// send something the server will reject anyway.
  static bool _isExpiringSoon(String jwt) {
    final expiry = expiryOf(jwt);
    if (expiry == null) return true;
    return DateTime.now().toUtc().add(_renewBefore).isAfter(expiry);
  }

  /// The `exp` claim, or null if the token cannot be read.
  ///
  /// Decoded locally — no network, no extra package. The signature is NOT verified here and
  /// does not need to be: this only decides whether to refresh early. The server is what
  /// actually validates the token.
  static DateTime? expiryOf(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }
}
