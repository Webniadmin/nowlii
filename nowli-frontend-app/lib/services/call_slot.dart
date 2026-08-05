/// Whether a quest can still carry a call on the day it is set for.
///
/// Scheduling never reserves quota — a `ScheduledCall` is a plan, not a booking, and the
/// daily limit is only enforced when a call starts. So nothing stopped a user planning a
/// third call for a day that allows two, or planning one for a day whose sparks were
/// already spent. Both produce the same ending: a reminder fires, the user taps it, and
/// the backend refuses.
///
/// This decides that up front, from the day the quest is on rather than from today —
/// tomorrow's allowance is untouched no matter what today did.
///
/// Pure Dart, no Flutter — see `test/call_slot_test.dart`.
library;

import 'number_words.dart';

enum CallSlotStatus {
  /// A call planned for this day can run.
  open,

  /// Today's sparks are gone. Nothing planned for today can happen.
  spent,

  /// Sparks remain in principle, but every one of them is already promised to a call
  /// planned for that day.
  alreadyPlanned,
}

/// Can this quest still carry a call?
///
/// [remainingToday] is the backend's remaining quota; negative means unlimited (the QA
/// accounts report `-1`). [pendingOnQuestDate] counts calls already planned for
/// [questDate]. [dailyLimit] is the day's full allowance, which is what a **future** day
/// gets back — today's is whatever survives in [remainingToday].
CallSlotStatus callSlotStatus({
  required DateTime questDate,
  required DateTime today,
  required int dailyLimit,
  required int remainingToday,
  required int pendingOnQuestDate,
}) {
  // Unlimited accounts have no day to run out of.
  if (remainingToday < 0) return CallSlotStatus.open;

  final isToday = questDate.year == today.year &&
      questDate.month == today.month &&
      questDate.day == today.day;

  // A day in the past cannot hold a call at all, and the create screen refuses those
  // separately; treat it as today would be treated.
  if (isToday || questDate.isBefore(today)) {
    if (remainingToday <= 0) return CallSlotStatus.spent;
    if (pendingOnQuestDate >= remainingToday) {
      return CallSlotStatus.alreadyPlanned;
    }
    return CallSlotStatus.open;
  }

  // A future day starts again from the full allowance.
  if (pendingOnQuestDate >= dailyLimit) return CallSlotStatus.alreadyPlanned;
  return CallSlotStatus.open;
}

/// The line shown under the greyed-out toggle, or null when the toggle is usable.
///
/// It names the reason rather than saying "unavailable", because the two reasons have
/// different ways out: spent sparks need another day, a full day needs a different hour or
/// one of the planned calls cancelled.
String? callSlotMessage(
  CallSlotStatus status, {
  required int dailyLimit,
  required bool isToday,
}) {
  switch (status) {
    case CallSlotStatus.open:
      return null;
    case CallSlotStatus.spent:
      return dailyLimit == 2
          ? "Both of today's sparks are spent — a call can't run today. "
              'Pick another day.'
          : "All ${numberWord(dailyLimit)} of today's sparks are spent — a call "
              "can't run today. Pick another day.";
    case CallSlotStatus.alreadyPlanned:
      return isToday
          ? "Today's remaining sparks are already promised to calls you planned. "
              'Pick another day, or cancel one of them.'
          : 'That day already has ${numberWord(dailyLimit)} calls planned — '
              'the most a day allows.';
  }
}
