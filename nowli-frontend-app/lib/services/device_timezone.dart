/// Telling the backend which clock this phone is on.
///
/// Quests store naive wall-clock times — "11:20", with no offset. Something has to decide
/// which 11:20 that is, and until now it was the server, which runs on UTC: a call set for
/// 11:20 in Belgrade was stored as 11:20 UTC and came back as 13:20, so every reminder
/// fired late by the device's whole offset.
///
/// The phone is the only thing that knows the answer, so it reports it. An **IANA name**
/// ("Europe/Belgrade"), not an offset: an offset is only true on the day it was measured,
/// and would put a December call an hour out and a travelling user out immediately.
library;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowlii/api/profile_model.dart';
import 'package:nowlii/api/profile_service.dart';

class DeviceTimezone {
  DeviceTimezone._();

  static const _lastReportedKey = 'reported_timezone';

  /// The zone this device is in, or null if it cannot be read.
  static Future<String?> current() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      return zone.trim().isEmpty ? null : zone.trim();
    } catch (_) {
      // A phone that will not name its zone still gets the old behaviour, which is the
      // server's clock — worse reminders, not a broken app.
      return null;
    }
  }

  /// Report the zone if it has changed since the last successful report.
  ///
  /// Cheap on every launch and correct after a flight. The cache is only written on a
  /// successful save, so a failed report is retried next time rather than remembered as
  /// done. Never throws: this runs on the launch path and a reminder an hour out is a
  /// smaller failure than an app that will not start.
  static Future<void> report() async {
    try {
      final zone = await current();
      if (zone == null) return;

      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_lastReportedKey) == zone) return;

      final result = await ProfileService.updateProfile(
        UpdateProfileRequest(timezone: zone),
      );
      if (result['success'] == true) {
        await prefs.setString(_lastReportedKey, zone);
      }
    } catch (_) {
      // Swallowed on purpose — see above.
    }
  }

  /// Forget what was reported, so the next [report] sends again.
  ///
  /// Called on sign-out: the cache is about this device's *account*, and the next user of
  /// the phone has their own profile to populate.
  static Future<void> forget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastReportedKey);
    } catch (_) {
      // Nothing to do; a stale cache only costs one skipped report.
    }
  }
}
