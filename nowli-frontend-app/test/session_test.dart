import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/api/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The JWT expiry reading that decides whether to refresh.
///
/// Getting this wrong is silent in both directions: read it too eagerly and the app
/// refreshes on every request (and, with rotation + blacklist on the server, risks logging
/// the user out); read it too late and every request goes out with a dead token — which is
/// exactly the "app looks broken after 31 days" bug this replaces.
String _jwtWithExp(DateTime expiry) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final header = seg({'alg': 'HS256', 'typ': 'JWT'});
  final payload = seg({
    'token_type': 'access',
    'user_id': 1,
    'exp': expiry.millisecondsSinceEpoch ~/ 1000,
  });
  return '$header.$payload.not-a-real-signature';
}

void main() {
  final now = DateTime.now().toUtc();

  group('deciding whether there is a session at all', () {
    // The route guard runs on every navigation and cannot wait on the network, so this
    // decision is made from the tokens alone. Getting it wrong is severe in both
    // directions: too strict and everyone is thrown out hourly; too lax and a signed-out
    // user roams an app where every screen fails — which is what used to happen, because
    // any non-empty string counted as a session.
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> store({String? access, String? refresh}) async {
      SharedPreferences.setMockInitialValues({
        if (access != null) 'access_token': access,
        if (refresh != null) 'refresh_token': refresh,
      });
    }

    test('no tokens at all', () async {
      expect(await Session.localState(), SessionState.none);
    });

    test('a live access token means signed in', () async {
      await store(
        access: _jwtWithExp(now.add(const Duration(hours: 1))),
        refresh: _jwtWithExp(now.add(const Duration(days: 90))),
      );
      expect(await Session.localState(), SessionState.active);
    });

    test('an expired access token with a live refresh token is renewable', () async {
      // The ordinary state every hour once access tokens are short-lived. Treating this as
      // signed out would bounce every user to the login screen hourly.
      await store(
        access: _jwtWithExp(now.subtract(const Duration(minutes: 5))),
        refresh: _jwtWithExp(now.add(const Duration(days: 89))),
      );
      expect(await Session.localState(), SessionState.renewable);
    });

    test('both expired means the session is over', () async {
      await store(
        access: _jwtWithExp(now.subtract(const Duration(days: 100))),
        refresh: _jwtWithExp(now.subtract(const Duration(days: 10))),
      );
      expect(await Session.localState(), SessionState.expired);
    });

    test('an unreadable token counts as dead, not as a session', () async {
      await store(access: 'garbage', refresh: 'also-garbage');
      expect(await Session.localState(), SessionState.expired);
    });

    test('a refresh token alone can still revive the session', () async {
      await store(refresh: _jwtWithExp(now.add(const Duration(days: 30))));
      expect(await Session.localState(), SessionState.renewable);
    });

    test('an access token alone, still live, is enough for now', () async {
      await store(access: _jwtWithExp(now.add(const Duration(hours: 1))));
      expect(await Session.localState(), SessionState.active);
    });
  });

  group('reading a token expiry', () {
    test('reads exp from a well-formed token', () {
      final expiry = now.add(const Duration(hours: 3));
      final read = Session.expiryOf(_jwtWithExp(expiry));
      expect(read, isNotNull);
      // Second precision — `exp` is whole seconds.
      expect(read!.difference(expiry).inSeconds.abs(), lessThanOrEqualTo(1));
    });

    test('survives base64 segments that need padding', () {
      // Payload lengths vary, so the middle segment is often not a multiple of four. A
      // decoder that does not normalise padding throws here.
      for (var i = 1; i < 12; i++) {
        final token = _jwtWithExp(now.add(Duration(minutes: i * 7 + i)));
        expect(Session.expiryOf(token), isNotNull, reason: 'failed at minute offset $i');
      }
    });

    test('returns null for anything that is not a JWT', () {
      for (final junk in ['', 'not-a-jwt', 'a.b', 'a.b.c.d', 'x.!!!not-base64!!!.z']) {
        expect(Session.expiryOf(junk), isNull, reason: 'accepted "$junk"');
      }
    });

    test('returns null when the payload carries no exp', () {
      final payload =
          base64Url.encode(utf8.encode(jsonEncode({'user_id': 1}))).replaceAll('=', '');
      expect(Session.expiryOf('aGVhZGVy.$payload.sig'), isNull);
    });

    test('reads an expiry that has already passed', () {
      final expiry = now.subtract(const Duration(days: 2));
      final read = Session.expiryOf(_jwtWithExp(expiry));
      expect(read, isNotNull);
      expect(read!.isBefore(now), isTrue);
    });
  });
}
