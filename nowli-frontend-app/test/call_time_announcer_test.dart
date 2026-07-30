import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/call_time_announcer.dart';

/// Rules under test (client request, 2026-07-30): Nowlii must warn the user *out loud*
/// shortly before the "Add 2.5 minutes" card appears, so they know they can extend — and
/// that the call ends by itself if they don't.
void main() {
  // Production values: card at 60 s left, spoken warning 10 s earlier, context each minute.
  CallTimeAnnouncer make() => CallTimeAnnouncer(
        promptSeconds: 60,
        leadSeconds: 10,
        contextIntervalSeconds: 60,
      );

  /// Drive the announcer second by second, as the call screen's 1 Hz timer does.
  List<CallTimeCue> runFrom(CallTimeAnnouncer a, int fromRemaining, {int to = 0}) {
    final cues = <CallTimeCue>[];
    for (var r = fromRemaining; r >= to; r--) {
      final cue = a.onTick(r);
      if (cue != null) cues.add(cue);
    }
    return cues;
  }

  group('spoken end-of-call warning', () {
    test('fires 10 seconds before the extension card appears', () {
      final a = make();
      expect(a.warnAtSeconds, 70, reason: 'card at 60 s + 10 s lead');

      expect(a.onTick(71), isNot(CallTimeCue.speakEndingSoonCanExtend));
      expect(a.onTick(70), CallTimeCue.speakEndingSoonCanExtend);
    });

    test('fires exactly once, not on every tick', () {
      final a = make();
      final spoken = runFrom(a, 300)
          .where((c) => c == CallTimeCue.speakEndingSoonCanExtend)
          .length;
      expect(spoken, 1);
    });

    test('offers the extension while it is still available', () {
      expect(runFrom(make(), 300), contains(CallTimeCue.speakEndingSoonCanExtend));
    });

    test('still fires if a tick is missed and the clock jumps past the moment', () {
      // A janky frame must not swallow the warning entirely.
      final a = make();
      expect(a.onTick(90), CallTimeCue.sendSilentTimeContext);
      expect(a.onTick(65), CallTimeCue.speakEndingSoonCanExtend);
    });

    test('is silent once the call has run out', () {
      final a = make();
      expect(a.onTick(0), isNull);
      expect(a.onTick(-3), isNull);
    });
  });

  group('after the call is extended', () {
    test('warns again before the new end', () {
      final a = make();
      expect(a.onTick(70), CallTimeCue.speakEndingSoonCanExtend);

      a.onExtended(); // user tapped "Add 2.5 minutes" → 150 s more
      final cues = runFrom(a, 150);
      expect(
        cues.where((c) => c == CallTimeCue.speakEndingSoonFinal).length,
        1,
        reason: 'the user must be told before the real end too',
      );
    });

    test('does not dangle a second extension that does not exist', () {
      final a = make();
      a.onTick(70);
      a.onExtended();
      final cues = runFrom(a, 150);
      expect(cues, isNot(contains(CallTimeCue.speakEndingSoonCanExtend)));
      expect(a.extensionUsed, isTrue);
    });

    test('an untouched extension is never reported as used', () {
      final a = make();
      runFrom(a, 300);
      expect(a.extensionUsed, isFalse);
    });
  });

  group('silent time context', () {
    test('refreshes about once per minute, not every second', () {
      final a = make();
      final contexts = runFrom(a, 300)
          .where((c) => c == CallTimeCue.sendSilentTimeContext)
          .length;
      // 300→71 spans the 5,4,3,2,1-minute buckets.
      expect(contexts, 5);
    });

    test('stops once the spoken warning has gone out', () {
      // Chatter about the clock in the last minute would step on the warning.
      final a = make();
      final tail = <CallTimeCue>[];
      for (var r = 70; r >= 1; r--) {
        final cue = a.onTick(r);
        if (cue != null) tail.add(cue);
      }
      expect(tail, [CallTimeCue.speakEndingSoonCanExtend]);
    });
  });
}
