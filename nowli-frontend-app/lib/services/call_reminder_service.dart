import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:nowlii/models/scheduled_call.dart';
import 'package:nowlii/services/scheduled_call_state.dart';
import 'package:nowlii/services/voice_call_service.dart';

/// Local reminders for calls the user planned on a quest.
///
/// The only place in the app that touches the notification plugin. Everything else asks it
/// to [sync]; it works out what should be pending and rewrites the lot.
///
/// **Why local notifications and not push:** the daily limit is checked when a call starts
/// regardless, and the app is by definition open whenever a call is spent — so nothing is
/// gained by involving a server, and a Firebase project plus APNs certificates plus a
/// backend scheduler is a lot of moving parts to maintain for that nothing.
class CallReminderService {
  CallReminderService._();
  static final CallReminderService instance = CallReminderService._();

  static const int _leadMinutes = 5;

  /// How far ahead reminders are laid down. iOS allows only 64 pending notifications, and a
  /// repeating quest with a call would otherwise eat that budget; [sync] runs often enough
  /// that a rolling week is always covered.
  static const int _horizonDays = 7;

  static const AndroidNotificationDetails _androidReminder = AndroidNotificationDetails(
    'nowlii_call_reminders',
    'Call reminders',
    channelDescription: 'Reminders for AI calls you scheduled on a quest.',
    importance: Importance.high,
    priority: Priority.high,
  );

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final VoiceCallService _voiceCalls = VoiceCallService();

  bool _initialised = false;
  bool _canScheduleExact = false;

  /// Called when the user taps a reminder. Wired up by the app so this service stays
  /// unaware of routing.
  void Function(int scheduledCallId, String questTitle)? onReminderTapped;

  Future<void> init() async {
    if (_initialised) return;

    tzdata.initializeTimeZones();
    // zonedSchedule needs a real zone, not a fixed offset, or reminders drift across a DST
    // change — the exact case a "same time every day" quest runs into.
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (e) {
      print('⚠️ Could not resolve the device timezone, using UTC: $e');
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Asked for explicitly at first use instead, with context for why.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );

    _initialised = true;
  }

  /// Ask for what we need to put a reminder on the user's lock screen.
  ///
  /// Returns whether notifications are allowed at all. Exact-alarm access is requested
  /// separately and is *not* required — see [_canScheduleExact].
  Future<bool> requestPermissions() async {
    await init();

    final notifications = await Permission.notification.request();
    if (!notifications.isGranted) return false;

    // Android 14+ no longer grants SCHEDULE_EXACT_ALARM on install, and Play policy
    // restricts the auto-granted USE_EXACT_ALARM to alarm-clock and calendar apps — which a
    // wellness reminder is not. So we ask, and quietly accept a minute or two of drift when
    // the answer is no. A late reminder is a small problem; a rejected app is not.
    try {
      final exact = await Permission.scheduleExactAlarm.request();
      _canScheduleExact = exact.isGranted;
    } catch (_) {
      _canScheduleExact = false; // iOS / older Android: the concept does not apply
    }
    return true;
  }

  /// Re-read whether the OS will currently let us set an exact alarm.
  ///
  /// [requestPermissions] used to be the only thing that ever set
  /// [_canScheduleExact], and it runs on the create-quest screen alone. So after
  /// every app restart the flag was back to its `false` default, and [sync]
  /// armed `inexactAllowWhileIdle` for a user who *had* granted the permission —
  /// the reminders quietly degraded until the next time someone happened to open
  /// create-quest. Measured on 2026-08-05: a 12:10 reminder landed at 12:12:45,
  /// a window of 24 minutes.
  ///
  /// This reads the status rather than requesting it, so it shows no prompt and
  /// is safe to run on every sync.
  Future<void> _refreshExactAlarmCapability() async {
    try {
      _canScheduleExact = await Permission.scheduleExactAlarm.isGranted;
    } catch (_) {
      _canScheduleExact = false; // iOS / older Android: the concept does not apply
    }
  }

  /// Rebuild every pending reminder from the backend's schedule.
  ///
  /// Call this whenever the schedule OR the remaining quota can have changed: after login,
  /// after a quest is created/edited/deleted, **after any call ends**, and on app resume.
  /// That last set is what keeps the out-of-calls wording honest — the app is the only thing
  /// that can spend a call, so it is always running at the moment the quota drops.
  Future<void> sync() async {
    await init();

    // Never scheduled anything, and can't — nothing to rebuild.
    if (!await Permission.notification.isGranted) return;

    // Before arming anything: the permission may have been granted in a session
    // that has since ended, or revoked in Settings while the app was closed.
    await _refreshExactAlarmCapability();

    final scheduled = await _voiceCalls.getScheduledCalls();
    final quota = await _voiceCalls.getQuota();
    // On a failed quota fetch, assume calls are available: a reminder the user cannot act on
    // is a smaller failure than silently withholding one they could have.
    final remaining = quota?.remaining ?? 1;

    await _plugin.cancelAll();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final call in scheduled) {
      if (!call.isPending) continue;

      final fireAt = reminderFireTime(
        scheduledFor: call.scheduledFor,
        now: now,
        lead: const Duration(minutes: _leadMinutes),
        horizon: const Duration(days: _horizonDays),
      );
      if (fireAt == null) continue;

      // Today's calls are dead if the quota is already gone. Say so, and offer the way out,
      // instead of inviting the user into a call the backend will refuse.
      final strandedToday = call.isOn(today) && remaining == 0;
      await _schedule(call, fireAt, stranded: strandedToday);
    }
  }

  Future<void> _schedule(ScheduledCall call, DateTime fireAt,
      {required bool stranded}) async {
    // Everything below is built from this call's own time — nothing about the copy is
    // fixed to a particular hour.
    final at = DateFormat('HH:mm').format(call.scheduledFor);
    final quest = call.questTitle.trim();
    final named = quest.isEmpty ? 'Your $at call' : '"$quest" at $at';

    // How long the user really has when the reminder lands. Normally the full lead time,
    // but less when the quest was created moments before its own start.
    final minutesLeft = call.scheduledFor.difference(fireAt).inMinutes;

    final title = stranded ? 'No calls left today' : 'Time to talk to Nowlii';
    final body = stranded
        ? "You've used both of today's calls, so $named can't run. Tap to move it to tomorrow."
        : minutesLeft >= 1
            ? '$named starts in $minutesLeft ${minutesLeft == 1 ? "minute" : "minutes"}.'
            : '$named is starting now.';

    await _plugin.zonedSchedule(
      call.id, // reusing the row id keeps re-syncs idempotent
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      NotificationDetails(
        android: _androidReminder,
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: _canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          // Still `allowWhileIdle`: without it Doze can hold a reminder back for hours,
          // which is a different problem from being a couple of minutes late.
          : AndroidScheduleMode.inexactAllowWhileIdle,
      // Fire at the wall-clock time the user picked. `absoluteTime` would drift by an hour
      // across a DST change for a quest that repeats all week.
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      payload: jsonEncode({
        'type': 'scheduled_call',
        'id': call.id,
        'questTitle': call.questTitle,
      }),
    );
  }

  void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      if (data['type'] != 'scheduled_call') return;
      onReminderTapped?.call(
        data['id'] as int,
        (data['questTitle'] ?? '') as String,
      );
    } catch (e) {
      print('⚠️ Bad reminder payload: $e');
    }
  }

  /// The reminder that launched the app from cold, if any. Read once from the splash
  /// screen — a tap that starts the process never reaches [_handleResponse].
  Future<NotificationResponse?> launchReminder() async {
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details!.notificationResponse;
  }

  /// Decode a payload into `(scheduledCallId, questTitle)`, or null if it isn't ours.
  static (int, String)? parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      if (data['type'] != 'scheduled_call') return null;
      return (data['id'] as int, (data['questTitle'] ?? '') as String);
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
