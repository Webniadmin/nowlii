import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/call_slot.dart';

/// Scheduling a call never reserved quota, so nothing stopped a user planning a third
/// call on a two-call day, or planning one for a day whose sparks were already spent.
/// Both ended the same way: a reminder fires, they tap it, the backend refuses.
void main() {
  final today = DateTime(2026, 8, 5);
  final tomorrow = DateTime(2026, 8, 6);

  CallSlotStatus status({
    DateTime? date,
    int limit = 2,
    int remaining = 2,
    int planned = 0,
  }) =>
      callSlotStatus(
        questDate: date ?? today,
        today: today,
        dailyLimit: limit,
        remainingToday: remaining,
        pendingOnQuestDate: planned,
      );

  group('today', () {
    test('an untouched day takes a call', () {
      expect(status(), CallSlotStatus.open);
    });

    test('a day with both sparks spent takes none', () {
      expect(status(remaining: 0), CallSlotStatus.spent);
    });

    test('one spark left and nothing planned still takes one', () {
      expect(status(remaining: 1), CallSlotStatus.open);
    });

    test('one spark left and one already planned takes no more', () {
      // The reported case: the spark is not spent, but it is spoken for.
      expect(status(remaining: 1, planned: 1), CallSlotStatus.alreadyPlanned);
    });

    test('two sparks left and two planned takes no more', () {
      expect(status(remaining: 2, planned: 2), CallSlotStatus.alreadyPlanned);
    });

    test('spent beats already-planned when both are true', () {
      // Nothing can run today, and "cancel one of your plans" would be useless advice.
      expect(status(remaining: 0, planned: 2), CallSlotStatus.spent);
    });
  });

  group('another day', () {
    test('tomorrow is unaffected by a spent today', () {
      expect(status(date: tomorrow, remaining: 0), CallSlotStatus.open);
    });

    test('tomorrow fills up at the daily limit, not at what is left today', () {
      expect(
        status(date: tomorrow, remaining: 0, planned: 2),
        CallSlotStatus.alreadyPlanned,
      );
      expect(
        status(date: tomorrow, remaining: 0, planned: 1),
        CallSlotStatus.open,
      );
    });
  });

  group('unlimited accounts', () {
    test('never run out, whatever is planned', () {
      expect(status(remaining: -1, planned: 9), CallSlotStatus.open);
      expect(
        status(date: tomorrow, remaining: -1, planned: 9),
        CallSlotStatus.open,
      );
    });
  });

  group('what the user is told', () {
    test('an open day says nothing at all', () {
      expect(
        callSlotMessage(CallSlotStatus.open, dailyLimit: 2, isToday: true),
        isNull,
      );
    });

    test('spent sparks are named as spent, and point at another day', () {
      final message = callSlotMessage(
        CallSlotStatus.spent,
        dailyLimit: 2,
        isToday: true,
      );
      expect(message, contains('sparks are spent'));
      expect(message, contains('another day'));
    });

    test('the wording follows the real limit, not a hardcoded two', () {
      expect(
        callSlotMessage(CallSlotStatus.spent, dailyLimit: 3, isToday: true),
        contains('three'),
      );
    });

    test('a full day offers the way out that actually applies', () {
      expect(
        callSlotMessage(
          CallSlotStatus.alreadyPlanned,
          dailyLimit: 2,
          isToday: true,
        ),
        contains('cancel one'),
      );
      expect(
        callSlotMessage(
          CallSlotStatus.alreadyPlanned,
          dailyLimit: 2,
          isToday: false,
        ),
        contains('two calls planned'),
      );
    });
  });
}
