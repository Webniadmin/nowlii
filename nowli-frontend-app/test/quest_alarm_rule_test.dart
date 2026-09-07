import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/call_reminder_service.dart';
import 'package:nowlii/services/quest_service.dart';

/// The rule for when a quest gets an alarm, exercised without touching the notification
/// plugin: `questAlarmFireTime` is the whole decision, `sync` only acts on it.
Quest _quest({
  required String date,
  String? time,
  bool setAlarm = true,
  bool taskDone = false,
  int id = 1,
}) {
  return Quest(
    id: id,
    subtasks: const [],
    task: 'Walk the dog',
    zone: 'Soft steps',
    selectADate: date,
    selectATime: time,
    enableCall: false,
    repeatQuest: false,
    setAlarm: setAlarm,
    taskDone: taskDone,
  );
}

void main() {
  // A fixed "now" so the test does not drift with the clock it runs on.
  final now = DateTime(2026, 8, 19, 9, 0);
  String today() => '2026-08-19';

  final lead = Duration(minutes: CallReminderService.questAlarmLeadMinutes);

  group('questAlarmFireTime', () {
    test('fires a lead time *before* the quest, the way a calendar does', () {
      // Firing at the quest's own time is the one moment the warning is already too late
      // to act on, which is what the user reported.
      final fireAt = CallReminderService.questAlarmFireTime(
        _quest(date: today(), time: '11:24:00'),
        now: now,
      );
      expect(fireAt, DateTime(2026, 8, 19, 11, 24).subtract(lead));
      expect(fireAt, DateTime(2026, 8, 19, 11, 19));
    });

    test('accepts HH:mm as well as the API\'s HH:mm:ss', () {
      final fireAt = CallReminderService.questAlarmFireTime(
        _quest(date: today(), time: '11:24'),
        now: now,
      );
      expect(fireAt, DateTime(2026, 8, 19, 11, 19));
    });

    test('no time → no alarm', () {
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: today(), time: null),
          now: now,
        ),
        isNull,
      );
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: today(), time: '   '),
          now: now,
        ),
        isNull,
      );
    });

    test('a future day is armed too, however far ahead', () {
      // Setting a time on a quest is the user asking to be reminded then. Arming only
      // today's meant a quest created on Sunday for Monday 17:00 stayed silent unless the
      // app happened to be opened on Monday.
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: '2026-08-20', time: '11:24:00'),
          now: now,
        ),
        DateTime(2026, 8, 20, 11, 19),
      );
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: '2026-09-30', time: '17:00:00'),
          now: now,
        ),
        DateTime(2026, 9, 30, 16, 55),
      );
    });

    test('a quest created inside its own lead window still warns, immediately', () {
      // now 09:00, quest 09:03 — the reminder's moment (08:58) is gone, but the quest's
      // is not. Dropping the alarm here would silently skip exactly the quests a user is
      // most likely to be in a hurry about.
      final fireAt = CallReminderService.questAlarmFireTime(
        _quest(date: today(), time: '09:03:00'),
        now: now,
      );
      expect(fireAt, isNotNull);
      expect(fireAt!.isAfter(now), isTrue);
      expect(fireAt.isBefore(DateTime(2026, 8, 19, 9, 3)), isTrue);
    });

    test('already completed → no alarm', () {
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: today(), time: '11:24:00', taskDone: true),
          now: now,
        ),
        isNull,
      );
    });

    test('alarm switched off → no alarm', () {
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: today(), time: '11:24:00', setAlarm: false),
          now: now,
        ),
        isNull,
      );
    });

    test('a day already gone → no alarm', () {
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: '2026-08-18', time: '11:24:00'),
          now: now,
        ),
        isNull,
      );
    });

    test('the quest\'s own time already passed → no alarm', () {
      // Scheduling a past instant makes the plugin fire it immediately, which reads as
      // "alarms go off the moment I open the app". The *quest's* time decides this, not
      // the reminder's — otherwise the lead time would resurrect quests already underway.
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: today(), time: '08:00:00'),
          now: now,
        ),
        isNull,
      );
      // The current minute counts as passed — it is not *after* now.
      expect(
        CallReminderService.questAlarmFireTime(
          _quest(date: today(), time: '09:00:00'),
          now: now,
        ),
        isNull,
      );
    });

    test('unparseable time is refused rather than guessed', () {
      for (final bad in ['abc', '25:00', '11:99', '11']) {
        expect(
          CallReminderService.questAlarmFireTime(
            _quest(date: today(), time: bad),
            now: now,
          ),
          isNull,
          reason: 'should refuse "$bad"',
        );
      }
    });
  });

  group('questStartTime', () {
    test('is the quest\'s own wall clock, not the reminder\'s', () {
      // The notification says when the quest *starts* while being posted earlier. Reading
      // the fire time instead would tell the user their 11:24 quest is at 11:19.
      expect(
        CallReminderService.questStartTime(
          _quest(date: today(), time: '11:24:00'),
        ),
        DateTime(2026, 8, 19, 11, 24),
      );
    });

    test('null without a usable date and time', () {
      expect(
        CallReminderService.questStartTime(_quest(date: today(), time: null)),
        isNull,
      );
      expect(
        CallReminderService.questStartTime(
          _quest(date: 'not-a-date', time: '11:24:00'),
        ),
        isNull,
      );
    });

    test('ignores the switches that only govern whether it rings', () {
      // Completion and the alarm toggle belong to questAlarmFireTime; a done quest still
      // has a start time, and the copy still has to be able to name it.
      expect(
        CallReminderService.questStartTime(
          _quest(date: today(), time: '11:24:00', taskDone: true, setAlarm: false),
        ),
        DateTime(2026, 8, 19, 11, 24),
      );
    });
  });
}
