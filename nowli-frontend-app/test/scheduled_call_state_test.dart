import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/scheduled_call_state.dart';

/// A scheduled call is a plan, never a booking — the daily limit of 2 is only enforced when
/// a call actually starts. These tests pin down what the user should see when the plan and
/// the quota disagree.
void main() {
  final now = DateTime(2026, 7, 30, 12, 0);

  ScheduledCallState resolve({
    String status = 'pending',
    required DateTime at,
    int remaining = 2,
  }) =>
      resolveScheduledCallState(
        serverStatus: status,
        scheduledFor: at,
        now: now,
        remainingCalls: remaining,
      );

  group('with calls still available', () {
    test('a future call is upcoming', () {
      expect(resolve(at: now.add(const Duration(hours: 5))),
          ScheduledCallState.upcoming);
    });

    test('a call due right now is startable', () {
      expect(resolve(at: now), ScheduledCallState.dueNow);
    });

    test('a call stays startable through the grace window', () {
      expect(resolve(at: now.subtract(const Duration(minutes: 14))),
          ScheduledCallState.dueNow);
    });

    test('past the grace window it is missed', () {
      expect(resolve(at: now.subtract(const Duration(minutes: 16))),
          ScheduledCallState.missed);
    });
  });

  group('when the daily calls are gone', () {
    test('a future call is locked, not upcoming', () {
      expect(resolve(at: now.add(const Duration(hours: 5)), remaining: 0),
          ScheduledCallState.locked);
    });

    test('a call due now is locked rather than startable', () {
      expect(resolve(at: now, remaining: 0), ScheduledCallState.locked);
    });

    test('a long-past call reads as missed, not locked', () {
      // "Locked" implies it could still run with a spare call; that ship has sailed.
      expect(resolve(at: now.subtract(const Duration(hours: 3)), remaining: 0),
          ScheduledCallState.missed);
    });

    test('an unlimited account is never locked', () {
      expect(resolve(at: now.add(const Duration(hours: 5)), remaining: -1),
          ScheduledCallState.upcoming);
    });
  });

  group('states the server has already decided', () {
    test('completed wins over the clock and the quota', () {
      expect(
        resolve(status: 'completed', at: now.subtract(const Duration(days: 1)), remaining: 0),
        ScheduledCallState.completed,
      );
    });

    test('cancelled wins too', () {
      expect(resolve(status: 'cancelled', at: now.add(const Duration(hours: 1))),
          ScheduledCallState.cancelled);
    });

    test("the server's own 'missed' is respected", () {
      expect(resolve(status: 'missed', at: now.subtract(const Duration(hours: 2))),
          ScheduledCallState.missed);
    });
  });

  group('what the user can do', () {
    test('only upcoming and due calls can be started', () {
      expect(isStartable(ScheduledCallState.dueNow), isTrue);
      expect(isStartable(ScheduledCallState.upcoming), isTrue);
      for (final s in [
        ScheduledCallState.locked,
        ScheduledCallState.missed,
        ScheduledCallState.completed,
        ScheduledCallState.cancelled,
      ]) {
        expect(isStartable(s), isFalse, reason: '$s must not start a call');
      }
    });

    test('locked and missed calls offer a move to tomorrow', () {
      expect(canReschedule(ScheduledCallState.locked), isTrue);
      expect(canReschedule(ScheduledCallState.missed), isTrue);
      expect(canReschedule(ScheduledCallState.completed), isFalse);
      expect(canReschedule(ScheduledCallState.upcoming), isFalse);
    });
  });

  group('warning before the last call is spent', () {
    test('warns when the last call would strand a later one', () {
      expect(
        wouldStrandAScheduledCall(
          remainingCalls: 1,
          scheduledLaterToday: [now.add(const Duration(hours: 5))],
          now: now,
        ),
        isTrue,
      );
    });

    test('stays quiet when both calls are still available', () {
      expect(
        wouldStrandAScheduledCall(
          remainingCalls: 2,
          scheduledLaterToday: [now.add(const Duration(hours: 5))],
          now: now,
        ),
        isFalse,
        reason: 'with two left, the spontaneous call and the plan both fit',
      );
    });

    test('stays quiet when nothing is scheduled', () {
      expect(
        wouldStrandAScheduledCall(
            remainingCalls: 1, scheduledLaterToday: const [], now: now),
        isFalse,
      );
    });

    test('ignores calls whose time has already passed', () {
      expect(
        wouldStrandAScheduledCall(
          remainingCalls: 1,
          scheduledLaterToday: [now.subtract(const Duration(hours: 2))],
          now: now,
        ),
        isFalse,
      );
    });

    test('never warns an unlimited account', () {
      expect(
        wouldStrandAScheduledCall(
          remainingCalls: -1,
          scheduledLaterToday: [now.add(const Duration(hours: 5))],
          now: now,
        ),
        isFalse,
      );
    });

    test('does not warn when there are no calls left at all', () {
      // Nothing to strand — the swipe itself is already blocked by the backend.
      expect(
        wouldStrandAScheduledCall(
          remainingCalls: 0,
          scheduledLaterToday: [now.add(const Duration(hours: 5))],
          now: now,
        ),
        isFalse,
      );
    });
  });

  test("the client's scenario: one call used, one planned, then a swipe", () {
    final planned = now.add(const Duration(hours: 5)); // 17:00

    // One call already made, one left. The swipe should warn first.
    expect(
      wouldStrandAScheduledCall(
          remainingCalls: 1, scheduledLaterToday: [planned], now: now),
      isTrue,
    );
    expect(resolve(at: planned, remaining: 1), ScheduledCallState.upcoming);

    // They swipe anyway — the 17:00 call is now unreachable and must say so.
    expect(resolve(at: planned, remaining: 0), ScheduledCallState.locked);
    expect(canReschedule(resolve(at: planned, remaining: 0)), isTrue);
  });
}
