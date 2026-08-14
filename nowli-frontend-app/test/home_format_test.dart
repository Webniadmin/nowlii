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

  group('progress bar fill', () {
    const track = 300.0;

    test('draws nothing when nothing is done', () {
      // The floor below exists so one-of-five reads as a pill. Applied at zero it painted
      // a pill on an empty day — progress the user had not made.
      expect(progressFillWidth(progress: 0.0, trackWidth: track), 0.0);
    });

    test('draws nothing on a day with no quests at all', () {
      // An empty day arrives here as 0.0 too; it must look empty, not started.
      expect(progressFillWidth(progress: 0.0, trackWidth: track), 0.0);
    });

    test('gives a small share the pill floor rather than a sliver', () {
      // 1/20 of 300 is 15px — narrower than the bar is tall, so it would render as a
      // lopsided nub.
      expect(progressFillWidth(progress: 0.05, trackWidth: track), 24.0);
    });

    test('is proportional once past the floor', () {
      expect(progressFillWidth(progress: 0.5, trackWidth: track), 150.0);
    });

    test('fills the track when the day is done, and never overruns it', () {
      expect(progressFillWidth(progress: 1.0, trackWidth: track), track);
      expect(progressFillWidth(progress: 1.5, trackWidth: track), track);
    });

    test('survives a track narrower than the floor', () {
      // First layout pass can hand out odd constraints; the fill must not exceed them.
      expect(progressFillWidth(progress: 1.0, trackWidth: 10.0), 10.0);
      expect(progressFillWidth(progress: 0.1, trackWidth: 10.0), 10.0);
      expect(progressFillWidth(progress: 0.5, trackWidth: 0.0), 0.0);
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
