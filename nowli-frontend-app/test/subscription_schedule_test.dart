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

    test('starts at the first change, not the price being quoted', () {
      // $19.99 is the big number at the top of the screen; repeating it as an upcoming
      // "change" would be wrong.
      expect(steps.map((s) => s.price), [14.99, 9.99, 4.99, 0]);
    });

    test('dates each change from the day the plan starts', () {
      expect(steps[0].dateLabel, '27 Oct'); // month 4 = +3
      expect(steps[1].dateLabel, '27 Jan'); // month 7 = +6
      expect(steps[2].dateLabel, '27 Apr'); // month 10 = +9
    });

    test('names the stages as the design does', () {
      expect(steps.map((s) => s.stage),
          ['Rhythm', 'Independence', 'Release', 'Graduated']);
    });

    test('dates the free stage by month, not by day', () {
      // A precise day a year out implies a precision the schedule does not have.
      expect(steps.last.isFinalFree, isTrue);
      expect(steps.last.dateLabel, 'Jul 2027');
      expect(steps.last.priceLabel, '\$0.00');
    });

    test('marks the first two changes confirmed and the rest provisional', () {
      expect(steps.map((s) => s.confirmed), [true, true, false, false]);
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
}
