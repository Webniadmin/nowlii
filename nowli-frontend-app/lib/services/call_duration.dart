/// How long a spark lasts, in one place.
///
/// The call screen owns the clock, but three other screens quote the same numbers back to
/// the user — the trial screen, onboarding step 7, and the quest card's call button. Those
/// were written out as "5 min · +2.5", so shortening the call would have left three
/// screens confidently describing a call that no longer exists.
///
/// Unlike the daily allowance, this is genuinely a client-side product constant: the
/// backend counts calls, it does not time them.
///
/// Pure Dart, no Flutter — see `test/call_duration_test.dart`.
library;

/// A spark's starting length.
const Duration kCallInitialDuration = Duration(minutes: 5);

/// The single extension the user can add near the end.
const Duration kCallExtensionDuration = Duration(minutes: 2, seconds: 30);

/// "5" — whole minutes, for copy.
String get callMinutesLabel => _minutesLabel(kCallInitialDuration);

/// "2.5" — the extension, with a half minute rendered as a decimal rather than "2:30",
/// because it appears mid-sentence.
String get extensionMinutesLabel => _minutesLabel(kCallExtensionDuration);

/// "5 min · +2.5 if you need it".
String get callLengthCopy =>
    '$callMinutesLabel min · +$extensionMinutesLabel if you need it';

String _minutesLabel(Duration d) {
  final minutes = d.inSeconds / 60;
  // Drop a trailing ".0" so five minutes reads "5", not "5.0".
  return minutes == minutes.roundToDouble()
      ? minutes.round().toString()
      : minutes.toStringAsFixed(1);
}
