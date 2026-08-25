import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:nowlii/models/scheduled_call.dart';
import 'package:nowlii/services/display_name.dart';
import 'package:nowlii/services/quest_service.dart';
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

  /// How long before a scheduled call its reminder fires.
  ///
  /// Public because three screens quote it back to the user in copy ("we'll remind you N
  /// minutes before"). Those numbers were written out by hand and said **10** while this
  /// said 5, so the app promised a reminder it never gave.
  static const int leadMinutes = 5;

  /// How long before a quest's own time its alarm fires.
  ///
  /// A quest alarm used to fire *at* the quest's time, which is the one moment a warning is
  /// already too late to act on. This is the calendar's behaviour instead: a few minutes'
  /// notice. Public for the same reason [leadMinutes] is — the copy quotes it rather than
  /// typing the number, which is how three screens came to promise ten minutes for a
  /// five-minute reminder.
  static const int questAlarmLeadMinutes = 5;


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

  /// Its own channel so a user can silence task alarms while keeping call reminders (or
  /// the reverse) from the system settings, without us shipping a settings screen for it.
  static const AndroidNotificationDetails _androidQuestAlarm = AndroidNotificationDetails(
    'nowlii_quest_alarms',
    'Quest alarms',
    channelDescription: 'Alarms for quests you set a time on.',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Notification ids are shared across the whole app, and call reminders already use the
  /// `ScheduledCall` row id. Quest ids come from a different table and would collide, so
  /// they live in their own block — a quest alarm cancelling a call reminder would be a
  /// silent, data-dependent bug.
  static const int _questAlarmIdBase = 2000000;

  /// How many quest alarms may be pending at once.
  ///
  /// Not a product rule — iOS keeps 64 pending notifications per app and drops the rest
  /// without telling anyone. Call reminders share that budget, so quests take 40 and
  /// leave room for them.
  static const int _maxQuestAlarms = 40;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final VoiceCallService _voiceCalls = VoiceCallService();
  final QuestService _quests = QuestService();

  bool _initialised = false;
  bool _canScheduleExact = false;
  bool _notificationAsked = false;

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

    if (!await _ensureNotificationPermission()) return false;

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

  /// May we post a notification at all — asking once if nobody has yet.
  ///
  /// From Android 13 (and always on iOS) this is a runtime grant, and **nothing in the app
  /// asked for it** except the create-quest screen, behind the "Enable call" toggle. So a
  /// user who only ever set quest alarms, or who granted nothing on that one screen, had
  /// every [sync] return here in silence — no call reminders, no quest alarms, no error,
  /// nothing to notice. That is the "notifications never arrive" report.
  ///
  /// Asked at most once per app run. A permanently-denied permission returns immediately
  /// without showing a dialog, so this is cheap to call on every sync; the user's "no"
  /// stays a no until they change it in Settings.
  Future<bool> _ensureNotificationPermission() async {
    if (await Permission.notification.isGranted) return true;
    if (_notificationAsked) return false;
    _notificationAsked = true;
    return (await Permission.notification.request()).isGranted;
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

    // Nothing can be posted without this, and asking is the whole point — see
    // [_ensureNotificationPermission] for why a silent return was wrong.
    if (!await _ensureNotificationPermission()) return;

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
        lead: const Duration(minutes: leadMinutes),
        horizon: const Duration(days: _horizonDays),
      );
      if (fireAt == null) continue;

      // Today's calls are dead if the quota is already gone. Say so, and offer the way out,
      // instead of inviting the user into a call the backend will refuse.
      final strandedToday = call.isOn(today) && remaining == 0;
      await _schedule(call, fireAt, stranded: strandedToday);
    }

    await _syncQuestAlarms(now);
  }

  /// Lay down an alarm for every scheduled, timed, unfinished quest — however far ahead.
  ///
  /// Runs inside [sync] rather than in a service of its own precisely because [sync]
  /// opens with `cancelAll()`: a second scheduler would have its alarms wiped by whichever
  /// of the two synced last. One owner of the tray, one rebuild.
  ///
  /// **No horizon.** Setting a time on a quest is the user asking to be reminded then, so
  /// a quest set today for next month is armed today. An earlier version armed only
  /// today's, which meant a quest created on Sunday for Monday 17:00 stayed silent unless
  /// the app happened to be opened on Monday — the alarm depended on the user already
  /// having remembered.
  ///
  /// The one real limit is the platform's, not ours: iOS keeps at most 64 pending
  /// notifications and silently drops the rest. So the list is armed nearest-first and
  /// capped at [_maxQuestAlarms]; anything beyond the cap is by definition further away
  /// than 40 other alarms, and gets armed by a later sync as it comes closer.
  Future<void> _syncQuestAlarms(DateTime now) async {
    final List<Quest> quests;
    try {
      quests = await _quests.fetchAllQuests();
    } catch (e) {
      // A failed fetch must not take the call reminders down with it — those are already
      // scheduled by the time we get here.
      print('⚠️ Could not load quests for alarms: $e');
      return;
    }

    // Resolve first, then sort: the cap has to drop the furthest-away alarms, not an
    // arbitrary slice of whatever order the API replied in.
    final due = <(DateTime, Quest)>[];
    for (final quest in quests) {
      final fireAt = questAlarmFireTime(quest, now: now);
      if (fireAt != null) due.add((fireAt, quest));
    }
    due.sort((a, b) => a.$1.compareTo(b.$1));

    if (due.length > _maxQuestAlarms) {
      // Say what was dropped. A silent truncation here reads as "alarms don't work".
      print('ℹ️ ${due.length} quest alarms due, arming the nearest $_maxQuestAlarms; '
          'the rest are armed by a later sync.');
    }

    for (final (fireAt, quest) in due.take(_maxQuestAlarms)) {
      final title = quest.task.trim();

      // When the quest actually begins — never `fireAt`, which is the warning. The two are
      // the same length apart as [questAlarmLeadMinutes] except for a quest created inside
      // its own lead window, where the notice is shorter; both cases read correctly here
      // because the gap is measured rather than assumed.
      final startsAt = questStartTime(quest) ?? fireAt;
      final at = DateFormat('HH:mm').format(startsAt);
      final minutesLeft = startsAt.difference(fireAt).inMinutes;
      final named = title.isEmpty ? 'One of your quests' : title;

      await _plugin.zonedSchedule(
        _questAlarmIdBase + quest.id,
        minutesLeft >= 1 ? 'Your quest is coming up' : 'Time for your quest',
        minutesLeft >= 1
            ? '$named starts in $minutesLeft '
                '${minutesLeft == 1 ? "minute" : "minutes"} — at $at.'
            : '$named starts now.',
        tz.TZDateTime.from(fireAt, tz.local),
        NotificationDetails(
          android: _androidQuestAlarm,
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: _canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        payload: jsonEncode({
          'type': 'quest_alarm',
          'id': quest.id,
          'questTitle': quest.task,
        }),
      );
    }
  }

  /// When a quest's alarm should fire, or null when it should not exist at all.
  ///
  /// The four reasons for null are the whole rule, kept in one testable place: the user
  /// switched the alarm off, the quest has no time (a quest with a date but no hour has
  /// nothing to ring at), it is already done, or its moment has already passed.
  ///
  /// How far ahead the quest is does **not** appear here — a date next month is as valid
  /// as one this afternoon.
  static DateTime? questAlarmFireTime(Quest quest, {required DateTime now}) {
    if (!quest.setAlarm) return null;
    if (quest.taskDone) return null;

    final startsAt = questStartTime(quest);
    if (startsAt == null) return null;

    // Only ahead of us: scheduling a past instant makes the plugin fire it immediately,
    // which is how "all my alarms go off the moment I open the app" happens. The quest's
    // own time is what decides this, not the reminder's — a quest that has already begun
    // has nothing left to warn about.
    if (!startsAt.isAfter(now)) return null;

    final fireAt =
        startsAt.subtract(const Duration(minutes: questAlarmLeadMinutes));

    // A quest created *inside* its own lead window — "remind me about the thing at 12:30"
    // typed at 12:28 — still gets its warning, right away, rather than none at all. That
    // is what a calendar does, and returning null here would have quietly dropped the
    // alarm for exactly the quests a user is most likely to be in a hurry about.
    return fireAt.isAfter(now) ? fireAt : now.add(const Duration(seconds: 5));
  }

  /// The moment a quest itself begins, or null when it has no usable date and time.
  ///
  /// Separate from [questAlarmFireTime] because the notification has to say when the quest
  /// *starts* while being posted [questAlarmLeadMinutes] earlier — formatting the fire time
  /// instead would tell the user their 12:30 quest is at 12:25.
  static DateTime? questStartTime(Quest quest) {
    final time = _parseWallClock(quest.selectATime);
    if (time == null) return null;

    final date = DateTime.tryParse(quest.selectADate);
    if (date == null) return null;

    return DateTime(date.year, date.month, date.day, time.$1, time.$2);
  }

  /// `"11:24:00"` / `"11:24"` → `(11, 24)`. Null for empty or unparseable input — the
  /// backend's TimeField is nullable and a quest without a time is the normal case.
  static (int, int)? _parseWallClock(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (h, m);
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

    // The companion has whatever name the user gave it, and this notification is the one
    // place the app addressed it by the product's name instead — so the reminder for a
    // companion called Zee still said "Nowlii".
    final companion = await DisplayName.companion();
    final title = stranded ? 'No calls left today' : 'Time to talk to $companion';
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
