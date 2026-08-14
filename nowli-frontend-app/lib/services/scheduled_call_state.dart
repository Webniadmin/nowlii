/// Works out what a scheduled call actually means to the user right now.
///
/// The daily limit (2 calls) is enforced by the backend at call start and is **never
/// reserved in advance** — scheduling is a plan, not a booking. So a row that looks
/// perfectly fine on the server can be impossible to act on, and the difference matters:
///
///  * schedule three calls in a day and the third can never run;
///  * use one call, keep one scheduled for 17:00, then swipe on the home screen — that
///    swipe spends the last call and the 17:00 one is stranded.
///
/// Rather than scatter those rules through the widgets, everything lands here: one row plus
/// the remaining quota plus the current time resolves to exactly one state.
///
/// Pure Dart, no Flutter — see `test/scheduled_call_state_test.dart`.
library;

enum ScheduledCallState {
  /// Still ahead, and the user has a call to spend on it.
  upcoming,

  /// Due now (or within the grace window) and startable.
  dueNow,

  /// Time has not passed, but the daily calls are gone — it cannot run today.
  locked,

  /// The time came and went without the call being taken.
  missed,

  /// The call happened.
  completed,

  /// The user turned the quest's call toggle off.
  cancelled,
}

/// How long after its time a call still counts as "due now" rather than missed.
///
/// The reminder lands 5 minutes early and a user may take a while to get to a quiet spot,
/// so snapping to missed the instant the clock ticks past would be hostile.
const Duration kDueGrace = Duration(minutes: 15);

/// Resolve the state of one scheduled call.
///
/// [remainingCalls] is today's remaining quota from the backend; pass a negative value for
/// unlimited (QA accounts report `-1`, matching `/voice-calls/quota/`).
/// [serverStatus] is the status the backend resolved: `pending`, `completed`, `cancelled`
/// or `missed`.
ScheduledCallState resolveScheduledCallState({
  required String serverStatus,
  required DateTime scheduledFor,
  required DateTime now,
  required int remainingCalls,
  Duration grace = kDueGrace,
}) {
  switch (serverStatus) {
    case 'completed':
      return ScheduledCallState.completed;
    case 'cancelled':
      return ScheduledCallState.cancelled;
  }

  final unlimited = remainingCalls < 0;
  final hasQuota = unlimited || remainingCalls > 0;
  final dueSince = now.difference(scheduledFor);

  // Past the grace window: gone, whatever the quota says. Calling it "locked" here would
  // imply it could still run if only they had a call left, which is no longer true.
  if (dueSince > grace) return ScheduledCallState.missed;

  // Out of calls. Reported even while the call is still in the future, so the quest card can
  // warn ahead of time instead of at the moment of failure.
  if (!hasQuota) return ScheduledCallState.locked;

  return dueSince >= Duration.zero
      ? ScheduledCallState.dueNow
      : ScheduledCallState.upcoming;
}

/// Whether tapping this call should try to start it.
bool isStartable(ScheduledCallState state) =>
    state == ScheduledCallState.dueNow || state == ScheduledCallState.upcoming;

/// Whether the user should be offered "move to tomorrow".
bool canReschedule(ScheduledCallState state) =>
    state == ScheduledCallState.locked || state == ScheduledCallState.missed;

/// When a reminder for [scheduledFor] should actually fire, or null if it should not.
///
/// Normally [lead] before the call. Two edges matter:
///  * the call itself has already passed → no reminder; the quest card shows it as missed
///    and a notification would only be noise;
///  * the call is closer than [lead] (a quest created at 17:58 for 18:00) → nudge almost
///    immediately rather than dropping the reminder silently, which is what a naive
///    "skip anything in the past" check does.
DateTime? reminderFireTime({
  required DateTime scheduledFor,
  required DateTime now,
  Duration lead = const Duration(minutes: 5),
  Duration horizon = const Duration(days: 7),
}) {
  if (!scheduledFor.isAfter(now)) return null;

  final fireAt = scheduledFor.subtract(lead);
  if (fireAt.isAfter(now.add(horizon))) return null;
  if (fireAt.isBefore(now)) return now.add(const Duration(seconds: 5));
  return fireAt;
}

/// Whether starting a call *right now* would strand something already scheduled.
///
/// Drives the confirmation on the home-screen swipe: spending the day's last call is fine,
/// but the user should know it costs them the call they planned for later.
///
/// [scheduledLaterToday] are the times of still-pending calls left today.
bool wouldStrandAScheduledCall({
  required int remainingCalls,
  required List<DateTime> scheduledLaterToday,
  required DateTime now,
}) {
  if (remainingCalls < 0) return false; // unlimited
  // Only the *last* call is a dilemma; with two left, both plans survive.
  if (remainingCalls != 1) return false;
  return scheduledLaterToday.any((t) => t.isAfter(now));
}

/// The same wall-clock time, one day later — where a stranded call is offered a new home.
///
/// Built from the calendar fields rather than `add(Duration(days: 1))`, which adds 24 hours
/// and lands an hour out either side of a DST change. A 17:00 call the user planned is a
/// 17:00 call tomorrow.
DateTime sameTimeNextDay(DateTime when) => DateTime(
      when.year,
      when.month,
      when.day + 1,
      when.hour,
      when.minute,
      when.second,
    );
