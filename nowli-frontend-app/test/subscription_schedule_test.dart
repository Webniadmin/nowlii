import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/subscription_schedule.dart';

/// The paywall quotes dated future prices, so this arithmetic is a pricing promise.
SubscriptionPlan _plan() => SubscriptionPlan(
      currency: 'USD',
      freeAfterMonth: 12,
      phases: [
        SubscriptionPhase(fromMonth: 1, toMonth: 3, price: 19.99),
        SubscriptionPhase(fromMonth: 4, toMonth: 6, price: 14.99),
        SubscriptionPhase(fromMonth: 7, toMonth: 9, price: 9.99),
        SubscriptionPhase(fromMonth: 10, toMonth: 12, price: 4.99),
      ],
    );

void main() {
  group('schedule', () {
    final steps = buildPriceSchedule(
      plan: _plan(),
      anchor: DateTime(2026, 7, 27),
    );

    test('opens on the stage being sold, then every change after it', () {
      // The opening stage is a row of its own even though its price is also the headline:
      // without it the ladder reads as though the plan begins at the second step.
      expect(steps.map((s) => s.price), [19.99, 14.99, 9.99, 4.99, 0]);
    });

    test('dates each change from the day the plan starts', () {
      expect(steps[0].dateLabel, '27 Jul'); // month 1 = the day they subscribe
      expect(steps[1].dateLabel, '27 Oct'); // month 4 = +3
      expect(steps[2].dateLabel, '27 Jan'); // month 7 = +6
      expect(steps[3].dateLabel, '27 Apr'); // month 10 = +9
    });

    test('names the stages as the design does', () {
      expect(steps.map((s) => s.stage),
          ['Spark', 'Rhythm', 'Independence', 'Release', 'Graduated']);
    });

    test('dates the free stage by month, not by day', () {
      // A precise day a year out implies a precision the schedule does not have.
      expect(steps.last.isFinalFree, isTrue);
      expect(steps.last.dateLabel, 'Jul 2027');
      expect(steps.last.priceLabel, '\$0.00');
    });

    test('the opening stage is what is on offer', () {
      expect(steps.first.status, PriceStepStatus.starting);
      expect(steps.first.badgeLabel, 'NEXT');
    });

    test('marks the first two changes confirmed and the rest provisional', () {
      // Counted from the row after the opening one — adding that row must not demote a
      // stage that used to read as settled.
      expect(steps.map((s) => s.status), [
        PriceStepStatus.starting,
        PriceStepStatus.confirmed,
        PriceStepStatus.confirmed,
        PriceStepStatus.provisional,
        PriceStepStatus.provisional,
      ]);
      expect(steps.map((s) => s.confirmed), [true, true, true, false, false]);
    });

    test('is empty when the plan has not loaded', () {
      // The card is hidden rather than filled with invented prices.
      expect(buildPriceSchedule(plan: null, anchor: DateTime(2026, 7, 27)), isEmpty);
    });
  });

  group('addMonths', () {
    test('keeps the day of the month', () {
      expect(addMonths(DateTime(2026, 7, 27), 3), DateTime(2026, 10, 27));
    });

    test('crosses the year boundary', () {
      expect(addMonths(DateTime(2026, 7, 27), 6), DateTime(2027, 1, 27));
    });

    test('clamps instead of rolling into the following month', () {
      // Naive DateTime(y, m + n, 31) turns 31 Jan + 1 month into 3 March, which would
      // show someone who subscribed on the 31st a price change in the wrong month.
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2026, 8, 31), 1), DateTime(2026, 9, 30));
    });

    test('handles a leap February', () {
      expect(addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    });
  });

  group('a subscriber sees where they are', () {
    final plan = SubscriptionPlan(
      currency: 'USD',
      freeAfterMonth: 12,
      graduatedStage: 'Graduated',
      phases: [
        SubscriptionPhase(fromMonth: 1, toMonth: 3, price: 19.99, stage: 'Spark'),
        SubscriptionPhase(fromMonth: 4, toMonth: 6, price: 14.99, stage: 'Rhythm'),
        SubscriptionPhase(
            fromMonth: 7, toMonth: 9, price: 9.99, stage: 'Independence'),
        SubscriptionPhase(
            fromMonth: 10, toMonth: 12, price: 4.99, stage: 'Release'),
      ],
    );
    final anchor = DateTime(2026, 8, 3);

    List<PriceStep> at(int month) => buildPriceSchedule(
          plan: plan, anchor: anchor, currentMonth: month,
        );

    test('the opening stage appears once subscribed', () {
      // The bug this fixes: Spark was missing from its own timeline, so the screen showed
      // everything except the thing being paid for.
      expect(at(1).first.stage, 'Spark');
      expect(at(1), hasLength(5));
    });

    test('someone still deciding is shown the stage on offer, but is not on it', () {
      final steps = buildPriceSchedule(plan: plan, anchor: anchor);
      expect(steps.first.stage, 'Spark');
      expect(steps.first.status, PriceStepStatus.starting);
      // Being offered a stage is not standing on one — nothing may read as CURRENT PLAN
      // until they have actually paid.
      expect(steps.any((s) => s.current), isFalse);
    });

    test('every stage becomes current in its own months', () {
      expect(at(1).firstWhere((s) => s.current).stage, 'Spark');
      expect(at(3).firstWhere((s) => s.current).stage, 'Spark');
      expect(at(4).firstWhere((s) => s.current).stage, 'Rhythm');
      expect(at(7).firstWhere((s) => s.current).stage, 'Independence');
      expect(at(10).firstWhere((s) => s.current).stage, 'Release');
      expect(at(12).firstWhere((s) => s.current).stage, 'Release');
    });

    test('exactly one stage is current at a time', () {
      for (final month in [1, 4, 7, 10, 13, 25]) {
        expect(at(month).where((s) => s.current).length, 1, reason: 'month $month');
      }
    });

    test('stages behind you read as completed', () {
      final steps = at(7);
      expect(steps[0].badgeLabel, 'COMPLETED');   // Spark
      expect(steps[1].badgeLabel, 'COMPLETED');   // Rhythm
      expect(steps[2].badgeLabel, 'CURRENT PLAN');
      expect(steps[3].badgeLabel, 'NEXT PLAN');
      expect(steps[4].badgeLabel, 'PROVISIONAL'); // Graduated
    });

    test('after the year, Graduated is where you live and it is free', () {
      final steps = at(13);
      final graduated = steps.last;
      expect(graduated.stage, 'Graduated');
      expect(graduated.current, isTrue);
      expect(graduated.badgeLabel, 'CURRENT PLAN');
      expect(graduated.priceLabel, '\$0.00');
      expect(graduated.isFinalFree, isTrue);
      // Everything paid is behind them.
      expect(steps.take(4).every((s) => s.completed), isTrue);
    });

    test('Graduated stays current forever, not just in month 13', () {
      expect(at(60).last.current, isTrue);
    });

    test('the last paid stage promotes Graduated to next', () {
      expect(at(10).last.badgeLabel, 'NEXT PLAN');
    });
  });
}
