import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/home_format.dart';

/// The home hero states two things as fact — when you said something, and how much of
/// today's quest is left. Both are easy to get quietly, embarrassingly wrong.
void main() {
  group('when you said it', () {
    final now = DateTime(2026, 8, 1, 14, 0);

    test('says today when the call was today', () {
      // The design's label is "Yesterday you said", but the quote comes from the most
      // recent call — which is often this morning.
      expect(
        saidWhenLabel(DateTime(2026, 8, 1, 9, 30), now: now),
        'Today you said',
      );
    });

    test('says yesterday when it was yesterday', () {
      expect(
        saidWhenLabel(DateTime(2026, 7, 31, 22, 0), now: now),
        'Yesterday you said',
      );
    });

    test('counts calendar days, not 24-hour spans', () {
      // 23:50 last night is "yesterday" even though it is under a day ago.
      expect(
        saidWhenLabel(DateTime(2026, 7, 31, 23, 50), now: now),
        'Yesterday you said',
      );
    });

    test('dates anything older outright', () {
      expect(
        saidWhenLabel(DateTime(2026, 7, 3, 12, 0), now: now),
        'On 3 July you said',
      );
    });
  });

  group('steps left', () {
    test('spells out a single step', () {
      // "1 step left" next to a display headline reads like a placeholder.
      expect(stepsLeftLabel(1), 'One step left');
    });

    test('counts the rest', () {
      expect(stepsLeftLabel(3), '3 steps left');
    });

    test('says so when the quest is finished', () {
      expect(stepsLeftLabel(0), 'All done');
      expect(stepsLeftLabel(-1), 'All done');
    });
  });

  group('sparks label', () {
    test('matches the pills beside it', () {
      expect(
        sparksAvailableLabel(remaining: 2, unlimited: false, known: true),
        '2 sparks available',
      );
    });

    test('does not say "1 sparks"', () {
      expect(
        sparksAvailableLabel(remaining: 1, unlimited: false, known: true),
        '1 spark available',
      );
    });

    test('says the day is over rather than "0 sparks available"', () {
      expect(
        sparksAvailableLabel(remaining: 0, unlimited: false, known: true),
        'No sparks left today',
      );
    });

    test('handles the unlimited test accounts', () {
      // These report -1, which must never reach the label as a number.
      expect(
        sparksAvailableLabel(remaining: -1, unlimited: true, known: true),
        'Unlimited sparks',
      );
    });

    test('admits when the quota could not be read', () {
      expect(
        sparksAvailableLabel(remaining: 0, unlimited: false, known: false),
        'Checking your sparks…',
      );
    });
  });
}
