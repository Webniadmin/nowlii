import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/completion_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The banner that drops in on a completed quest made two claims, both hardcoded, and
/// both false after the first tick: "your first task completed" and "+1 streak". The
/// second was the worse of the two — a streak day is only earned when every quest for
/// the date is done, so the first of three quests advanced nothing at all.
void main() {
  group('the headline', () {
    test('celebrates the first completion as the first', () {
      expect(
        completionBannerTitle(lifetimeCompletions: 1, completedToday: 1),
        'Boom, your first task completed!',
      );
    });

    test('never calls a later one the first again', () {
      for (final n in [2, 3, 7, 40]) {
        expect(
          completionBannerTitle(lifetimeCompletions: n, completedToday: 1),
          isNot(contains('first')),
        );
      }
    });

    test('marks the second differently from the rest', () {
      expect(
        completionBannerTitle(lifetimeCompletions: 2, completedToday: 2),
        contains('Two done'),
      );
    });

    test('counts the day once more than one is done in it', () {
      expect(
        completionBannerTitle(lifetimeCompletions: 12, completedToday: 3),
        "That's three done today.",
      );
    });

    test('says simply one more when today has only this one', () {
      expect(
        completionBannerTitle(lifetimeCompletions: 12, completedToday: 1),
        'One more done.',
      );
    });
  });

  group('the badge', () {
    test('claims the streak only when the day is finished', () {
      expect(
        completionBannerBadge(completedToday: 3, totalToday: 3),
        '+1 streak',
      );
    });

    test('does not claim it on the first of three', () {
      // The old banner said "+1 streak" here. /api/quests/streak/ counts only dates where
      // total == done, so nothing had been earned.
      expect(
        completionBannerBadge(completedToday: 1, totalToday: 3),
        '2 to go',
      );
    });

    test('counts down what is left', () {
      expect(completionBannerBadge(completedToday: 2, totalToday: 3), '1 to go');
    });

    test('survives a count that overshoots the total', () {
      expect(
        completionBannerBadge(completedToday: 4, totalToday: 3),
        '+1 streak',
      );
    });
  });

  group('the lifetime counter', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CompletionCounter.reset();
    });

    test('starts at one and climbs', () async {
      expect(await CompletionCounter.record(), 1);
      expect(await CompletionCounter.record(), 2);
      expect(await CompletionCounter.record(), 3);
    });

    test('so the first-completion copy is shown exactly once', () async {
      final titles = <String>[];
      for (var i = 0; i < 4; i++) {
        final n = await CompletionCounter.record();
        titles.add(
          completionBannerTitle(lifetimeCompletions: n, completedToday: 1),
        );
      }

      expect(
        titles.where((t) => t.contains('first')).length,
        1,
        reason: 'only the first tick may call itself the first',
      );
    });
  });
}
