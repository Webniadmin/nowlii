/// Wording for the home screen's two data-driven lines.
///
/// Both are small, and both are easy to get quietly wrong: a label that says "Yesterday"
/// about something said this morning, or a count that reads "1 steps left". Keeping them
/// here makes both testable.
///
/// Pure Dart, no Flutter — see `test/home_format_test.dart`.
library;

import 'package:intl/intl.dart';

/// The eyebrow above the last thing the user told their companion.
///
/// The design says "Yesterday you said", but the quote comes from the most recent call,
/// which may well have been today — so the label follows the actual day rather than
/// asserting one. Anything older than yesterday is dated outright, because "a while ago"
/// is less useful than a date.
String saidWhenLabel(DateTime when, {DateTime? now}) {
  final today = _dayOf(now ?? DateTime.now());
  final said = _dayOf(when);
  final daysAgo = today.difference(said).inDays;

  if (daysAgo <= 0) return 'Today you said';
  if (daysAgo == 1) return 'Yesterday you said';
  return 'On ${DateFormat('d MMMM').format(when)} you said';
}

/// "One step left" — how much of today's quest is outstanding.
///
/// Spelled out at one, because "1 step left" next to a hand-lettered headline reads like a
/// placeholder. Zero is a finished quest and says so.
String stepsLeftLabel(int remaining) {
  if (remaining <= 0) return 'All done';
  if (remaining == 1) return 'One step left';
  return '$remaining steps left';
}

/// The line beside the spark pills.
///
/// [known] false means the quota could not be read — it says so rather than guessing a
/// number, because the pills beside it would be guessing too.
String sparksAvailableLabel({
  required int remaining,
  required bool unlimited,
  required bool known,
  bool paused = false,
}) {
  // Checked before [known]: a lapsed user has a definite answer, and leaving them on
  // "Checking…" would be waiting for one that never arrives.
  if (paused) return 'Calls paused';
  if (!known) return 'Checking your sparks…';
  if (unlimited) return 'Unlimited sparks';
  if (remaining <= 0) return 'No sparks left today';
  if (remaining == 1) return '1 spark available';
  return '$remaining sparks available';
}

/// How wide the "Todays progress" fill should be, in pixels.
///
/// Two rules pull against each other. A day with one quest of five done must still read as
/// a rounded pill rather than a sliver, so the fill has a floor of its own height
/// ([barHeight]). But a day with nothing done must draw **nothing** — a floor applied at
/// zero paints a pill that says work happened when none did, which is the same untruth as
/// a ring drawn full for a single completion.
double progressFillWidth({
  required double progress,
  required double trackWidth,
  double barHeight = 24.0,
}) {
  if (progress <= 0 || trackWidth <= 0) return 0.0;
  return (trackWidth * progress).clamp(
    barHeight.clamp(0.0, trackWidth),
    trackWidth,
  );
}

DateTime _dayOf(DateTime value) => DateTime(value.year, value.month, value.day);
