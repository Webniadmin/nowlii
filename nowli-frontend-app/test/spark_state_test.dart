import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/spark_state.dart';

/// The spark counter and the out-of-sparks states are driven entirely by two numbers from
/// the backend, and two of their values are traps: `-1` means unlimited (QA accounts), and
/// a failed read means we know nothing. Both must produce silence rather than a guess.
void main() {
  group('counter', () {
    test('names the call that is currently running', () {
      // `start/` reports the quota *after* counting this call, so 1 left of 2 = spark 1.
      expect(const SparkState(limit: 2, remaining: 1).counterLabel, 'Spark 1 of 2');
      expect(const SparkState(limit: 2, remaining: 0).counterLabel, 'Spark 2 of 2');
    });

    test('is hidden for unlimited accounts rather than reading "of -1"', () {
      const unlimited = SparkState(limit: -1, remaining: -1);
      expect(unlimited.unlimited, isTrue);
      expect(unlimited.counterLabel, isNull);
      expect(unlimited.currentSpark, isNull);
    });

    test('is hidden when the quota could not be read', () {
      expect(const SparkState.unknown().counterLabel, isNull);
    });

    test('never counts past the limit if the backend clamps remaining to 0', () {
      expect(const SparkState(limit: 2, remaining: 0).currentSpark, 2);
    });
  });

  group('spent', () {
    test('is true only when the allowance is actually gone', () {
      expect(const SparkState(limit: 2, remaining: 0).isSpent, isTrue);
      expect(const SparkState(limit: 2, remaining: 1).isSpent, isFalse);
    });

    test('an unknown quota is never spent', () {
      // A dropped request must not close the day down — the backend is the real gate.
      expect(const SparkState.unknown().isSpent, isFalse);
    });

    test('an unlimited account is never spent', () {
      expect(const SparkState(limit: -1, remaining: -1).isSpent, isFalse);
    });
  });

  group('eyebrow copy', () {
    test('says "both" only while there really are two', () {
      expect(const SparkState(limit: 2, remaining: 0).spentEyebrow, 'Both sparks used');
    });

    test('falls back to wording that survives a changed daily limit', () {
      // VOICE_CALL_DAILY_LIMIT is a settings value; "Both sparks used" would be a lie at 3.
      expect(const SparkState(limit: 3, remaining: 0).spentEyebrow, 'All sparks used');
    });
  });

  test('used counts the sparks already started', () {
    expect(const SparkState(limit: 2, remaining: 2).used, 0);
    expect(const SparkState(limit: 2, remaining: 1).used, 1);
    expect(const SparkState(limit: 2, remaining: 0).used, 2);
  });
}
