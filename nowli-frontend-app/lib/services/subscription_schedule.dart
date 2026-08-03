/// Turns the backend's pricing phases into the dated rows the paywall timeline shows.
///
/// The plan steps the monthly price down every three months and then goes free forever.
/// The backend describes that as month *ranges* (`from_month` / `to_month`), which is the
/// right shape to bill from and the wrong shape to show someone — what a person wants to
/// know is "what will I pay, and when does it change". This converts one into the other.
///
/// The big price at the top of the screen is the phase the user is in *now*, so the
/// timeline deliberately starts at the phase after it: these are the changes still ahead.
///
/// Pure Dart, no Flutter — see `test/subscription_schedule_test.dart`.
library;

import 'package:intl/intl.dart';
import 'package:nowlii/models/subscription_model.dart';

/// The product names for each step down. These live in the design, not in the backend —
/// the API only knows months and prices.
const List<String> kPriceStepNames = ['Rhythm', 'Independence', 'Release'];

/// The name for the final, free-forever stage.
const String kGraduatedStageName = 'Graduate';

/// How many upcoming steps are presented as settled rather than indicative.
const int kConfirmedSteps = 2;

class PriceStep {
  /// "Rhythm", "Independence", "Release", "Graduated".
  final String stage;

  /// The day this price takes effect.
  final DateTime startsOn;

  final double price;

  /// Presented as settled (as opposed to a projection further out).
  final bool confirmed;

  /// The free-forever stage, which is dated by month rather than by day — nobody needs
  /// the exact date of something a year out, and quoting one implies a precision the
  /// schedule does not have.
  final bool isFinalFree;

  const PriceStep({
    required this.stage,
    required this.startsOn,
    required this.price,
    required this.confirmed,
    required this.isFinalFree,
  });

  String get priceLabel => '\$${price.toStringAsFixed(2)}';

  String get dateLabel => isFinalFree
      ? DateFormat('MMM yyyy').format(startsOn)
      : DateFormat('d MMM').format(startsOn);
}

/// The price changes still ahead of [anchor].
///
/// [anchor] is the day the paid subscription starts counting from: `started_at` for
/// someone who has already subscribed, and today for someone still deciding — in which
/// case the dates are an honest "if you subscribe now" projection rather than being
/// anchored to nothing.
///
/// Returns an empty list when the plan has not loaded, so the caller can hide the card
/// rather than render an empty frame or invented prices.
List<PriceStep> buildPriceSchedule({
  required SubscriptionPlan? plan,
  required DateTime anchor,
  int confirmedSteps = kConfirmedSteps,
}) {
  if (plan == null || plan.phases.isEmpty) return const [];

  final steps = <PriceStep>[];

  // Skip phase 1: that is the price being quoted at the top of the screen, not a change.
  for (var i = 1; i < plan.phases.length; i++) {
    final phase = plan.phases[i];
    final nameIndex = i - 1;
    steps.add(PriceStep(
      stage: nameIndex < kPriceStepNames.length
          ? kPriceStepNames[nameIndex]
          : 'Step ${i + 1}',
      // from_month is 1-based: month 4 begins 3 months after the start.
      startsOn: addMonths(anchor, phase.fromMonth - 1),
      price: phase.price,
      confirmed: steps.length < confirmedSteps,
      isFinalFree: false,
    ));
  }

  steps.add(PriceStep(
    stage: kGraduatedStageName,
    startsOn: addMonths(anchor, plan.freeAfterMonth),
    price: 0,
    confirmed: steps.length < confirmedSteps,
    isFinalFree: true,
  ));

  return steps;
}

/// [date] shifted by [months], keeping the day of the month where that day exists.
///
/// `DateTime(y, m + n, d)` alone silently rolls overflow forward — the 31st plus one
/// month becomes the 2nd or 3rd of the month after next, so someone who subscribed on the
/// 31st would be shown price changes in the wrong month entirely. Clamping to the last
/// valid day is what every billing system does and what the user expects.
DateTime addMonths(DateTime date, int months) {
  final target = DateTime(date.year, date.month + months);
  final lastDayOfTarget = DateTime(target.year, target.month + 1, 0).day;
  return DateTime(
    target.year,
    target.month,
    date.day > lastDayOfTarget ? lastDayOfTarget : date.day,
  );
}
