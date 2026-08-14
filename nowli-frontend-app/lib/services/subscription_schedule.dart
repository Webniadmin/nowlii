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

/// Fallback names, used only when the backend serves a phase without one. The real names
/// come from `/plan/` — the backend owns the schedule, so it owns the labels too.
const List<String> kPriceStepNames = ['Spark', 'Rhythm', 'Independence', 'Release'];

/// The name for the final, free-forever stage.
const String kGraduatedStageName = 'Graduated';

/// How many upcoming steps are presented as settled rather than indicative.
const int kConfirmedSteps = 2;

/// Where a stage sits relative to the subscriber.
///
/// A prospective subscriber only ever sees [confirmed] and [provisional] — they are being
/// quoted a schedule. A subscriber sees the whole journey, including the stages behind them,
/// because the question changes from "what will this cost" to "where am I".
enum PriceStepStatus {
  completed,
  current,
  next,
  confirmed,
  provisional,

  /// The stage a prospective subscriber would start on — the first row of their timeline.
  ///
  /// Its own value rather than reusing [next]: a subscriber's *next* stage is drawn as an
  /// outline, because it has not been reached. This one is the thing being offered, and the
  /// design gives it the green badge.
  starting,
}

class PriceStep {
  /// "Rhythm", "Independence", "Release", "Graduated".
  final String stage;

  /// The day this price takes effect.
  final DateTime startsOn;

  final double price;

  final PriceStepStatus status;

  /// The free-forever stage, which is dated by month rather than by day — nobody needs
  /// the exact date of something a year out, and quoting one implies a precision the
  /// schedule does not have.
  final bool isFinalFree;

  const PriceStep({
    required this.stage,
    required this.startsOn,
    required this.price,
    required this.status,
    required this.isFinalFree,
  });

  bool get completed => status == PriceStepStatus.completed;
  bool get current => status == PriceStepStatus.current;

  /// Settled rather than indicative — drives the darker ink in the timeline.
  bool get confirmed =>
      status == PriceStepStatus.completed ||
      status == PriceStepStatus.current ||
      status == PriceStepStatus.next ||
      status == PriceStepStatus.confirmed ||
      status == PriceStepStatus.starting;

  /// The badge on the right of the row.
  String get badgeLabel {
    switch (status) {
      case PriceStepStatus.completed:
        return 'COMPLETED';
      case PriceStepStatus.current:
        return 'CURRENT PLAN';
      case PriceStepStatus.next:
        return 'NEXT PLAN';
      case PriceStepStatus.confirmed:
        return 'CONFIRMED';
      case PriceStepStatus.provisional:
        return 'PROVISIONAL';
      case PriceStepStatus.starting:
        return 'NEXT';
    }
  }

  String get priceLabel => '\$${price.toStringAsFixed(2)}';

  String get dateLabel => isFinalFree
      ? DateFormat('MMM yyyy').format(startsOn)
      : DateFormat('d MMM').format(startsOn);
}

/// The name of the stage a subscriber is currently in — "Spark", "Rhythm", … or the
/// graduated stage once the paid year is behind them.
///
/// `/me/` reports `phase` as a month *range* ("1-3"), not a name, so the name is looked up
/// in the plan the backend already serves. Deriving it here rather than shipping a second
/// list is the same reason [kPriceStepNames] is only a fallback: the backend owns the
/// schedule, so it owns the labels.
///
/// Returns null while the plan is still loading, or for someone whose paid schedule has not
/// started ([monthIndex] 0) — they are not *in* a stage yet, and naming one would be a
/// guess about a plan they have not bought.
String? stageForMonth(SubscriptionPlan? plan, int monthIndex) {
  if (plan == null || monthIndex <= 0) return null;
  for (final phase in plan.phases) {
    if (phase.fromMonth <= monthIndex && monthIndex <= phase.toMonth) {
      return phase.stage.isNotEmpty ? phase.stage : null;
    }
  }
  // Past the last paid phase: free forever.
  if (monthIndex > plan.freeAfterMonth) {
    return plan.graduatedStage.isNotEmpty ? plan.graduatedStage : kGraduatedStageName;
  }
  return null;
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
  int? currentMonth,
}) {
  if (plan == null || plan.phases.isEmpty) return const [];

  // Both lists now start at the first phase, for different reasons.
  //
  // A subscriber is asking "where am I?" — and the answer has to include the stage they are
  // on, or the screen shows them everything except the thing they are paying for.
  //
  // Someone still deciding used to have the opening stage omitted, on the grounds that the
  // headline above already quotes its price. Changed 2026-08-04 at the client's request: the
  // headline is a number, the row is a *named stage with a date*, and leaving Spark out made
  // the timeline read as though the plan began at Rhythm. It is marked [starting] rather than
  // repeated as a plain row, so it reads as the thing being offered.
  final subscribed = currentMonth != null;
  const firstIndex = 0;

  final steps = <PriceStep>[];
  final lastPaidMonth = plan.phases.last.toMonth;

  for (var i = firstIndex; i < plan.phases.length; i++) {
    final phase = plan.phases[i];
    steps.add(PriceStep(
      stage: phase.stage.isNotEmpty
          ? phase.stage
          : (i < kPriceStepNames.length ? kPriceStepNames[i] : 'Step ${i + 1}'),
      // from_month is 1-based: month 4 begins 3 months after the start.
      startsOn: addMonths(anchor, phase.fromMonth - 1),
      price: phase.price,
      isFinalFree: false,
      status: _statusFor(
        subscribed: subscribed,
        currentMonth: currentMonth,
        fromMonth: phase.fromMonth,
        toMonth: phase.toMonth,
        position: steps.length,
        confirmedSteps: confirmedSteps,
      ),
    ));
  }

  steps.add(PriceStep(
    stage: plan.graduatedStage.isNotEmpty
        ? plan.graduatedStage
        : kGraduatedStageName,
    startsOn: addMonths(anchor, plan.freeAfterMonth),
    price: 0,
    isFinalFree: true,
    status: _statusFor(
      subscribed: subscribed,
      currentMonth: currentMonth,
      fromMonth: lastPaidMonth + 1,
      // Free forever, so it has no end. Nobody ever moves past this one.
      toMonth: 1 << 30,
      position: steps.length,
      confirmedSteps: confirmedSteps,
    ),
  ));

  _promoteNext(steps);
  return steps;
}

/// Mark the stage immediately after the current one as [PriceStepStatus.next].
///
/// Done by position rather than by arithmetic on months: phases are three months long
/// today, and a schedule change should not quietly relabel the wrong row.
void _promoteNext(List<PriceStep> steps) {
  final currentIndex = steps.indexWhere((s) => s.current);
  final nextIndex = currentIndex + 1;
  if (currentIndex == -1 || nextIndex >= steps.length) return;
  final next = steps[nextIndex];
  steps[nextIndex] = PriceStep(
    stage: next.stage,
    startsOn: next.startsOn,
    price: next.price,
    isFinalFree: next.isFinalFree,
    status: PriceStepStatus.next,
  );
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


/// Where one stage sits relative to the subscriber.
///
/// For someone still deciding there is no "here", so the old confirmed/provisional split is
/// kept: the near steps are settled, the far ones are a projection.
PriceStepStatus _statusFor({
  required bool subscribed,
  required int? currentMonth,
  required int fromMonth,
  required int toMonth,
  required int position,
  required int confirmedSteps,
}) {
  if (!subscribed || currentMonth == null) {
    // Row 0 is the stage they would start on. The near steps after it stay settled and the
    // far ones remain a projection, so [confirmedSteps] is counted from row 1 — otherwise
    // adding the opening row would have quietly demoted one stage to PROVISIONAL.
    if (position == 0) return PriceStepStatus.starting;
    return position <= confirmedSteps
        ? PriceStepStatus.confirmed
        : PriceStepStatus.provisional;
  }
  if (currentMonth > toMonth) return PriceStepStatus.completed;
  if (currentMonth >= fromMonth) return PriceStepStatus.current;
  // Everything ahead starts out provisional; the one immediately after the current stage is
  // promoted to `next` afterwards, by position rather than by guessing a phase length.
  return PriceStepStatus.provisional;
}
