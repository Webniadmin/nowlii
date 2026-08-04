import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/subscription_schedule.dart';

/// The profile card names the plan a subscriber is on. `/me/` reports the phase as a month
/// range, not a name, so the name is looked up in the plan the backend serves — these pin
/// that lookup, including the two cases where naming a stage would be a guess.
void main() {
  SubscriptionPlan planWith({int freeAfterMonth = 12}) => SubscriptionPlan(
        currency: 'USD',
        freeAfterMonth: freeAfterMonth,
        graduatedStage: 'Graduated',
        phases: [
          SubscriptionPhase(fromMonth: 1, toMonth: 3, price: 19.99, stage: 'Spark'),
          SubscriptionPhase(fromMonth: 4, toMonth: 6, price: 14.99, stage: 'Rhythm'),
          SubscriptionPhase(fromMonth: 7, toMonth: 9, price: 9.99, stage: 'Independence'),
          SubscriptionPhase(fromMonth: 10, toMonth: 12, price: 4.99, stage: 'Release'),
        ],
      );

  group('stageForMonth', () {
    test('names the stage covering the billing month', () {
      final plan = planWith();
      expect(stageForMonth(plan, 1), 'Spark');
      expect(stageForMonth(plan, 3), 'Spark');
      expect(stageForMonth(plan, 4), 'Rhythm');
      expect(stageForMonth(plan, 9), 'Independence');
      expect(stageForMonth(plan, 12), 'Release');
    });

    test('past the paid year the stage is the free one', () {
      expect(stageForMonth(planWith(), 13), 'Graduated');
      expect(stageForMonth(planWith(), 40), 'Graduated');
    });

    test('month 0 has no stage — a trial user is not on a paid plan yet', () {
      // The card must fall back to "Nowlii Pro" here rather than announce a stage the user
      // has not bought.
      expect(stageForMonth(planWith(), 0), isNull);
    });

    test('no plan yet means no name, not a guessed one', () {
      expect(stageForMonth(null, 4), isNull);
    });

    test('a phase the backend served without a name yields null, not a local guess', () {
      final unnamed = SubscriptionPlan(
        currency: 'USD',
        freeAfterMonth: 12,
        phases: [SubscriptionPhase(fromMonth: 1, toMonth: 3, price: 19.99)],
      );
      expect(stageForMonth(unnamed, 2), isNull);
    });
  });
}
