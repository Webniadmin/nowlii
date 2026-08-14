/// Small numbers spelled out, for copy that reads as a sentence.
///
/// Several screens quote counts the backend owns — the daily spark allowance
/// (`VOICE_CALL_DAILY_LIMIT`, an env var) and the trial length (`TRIAL_DAYS`). They used to
/// be written into the copy as words: "Two short calls a day", "SEVEN DAYS. ON US.",
/// "First spark / Second spark". Change the setting and those sentences quietly become
/// false, while the home screen and the call screen — which read the same values from the
/// API — go on telling the truth beside them.
///
/// Pure Dart, no Flutter — see `test/number_words_test.dart`.
library;

const List<String> _words = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six',
  'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve',
];

const List<String> _ordinals = [
  '', 'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth',
  'Seventh', 'Eighth', 'Ninth', 'Tenth', 'Eleventh', 'Twelfth',
];

/// "two" for 2, falling back to digits past the point where words help.
String numberWord(int n) =>
    (n >= 0 && n < _words.length) ? _words[n] : '$n';

/// "Two" — the same word, capitalised for the start of a sentence.
String capitalisedNumberWord(int n) {
  final word = numberWord(n);
  return word[0].toUpperCase() + word.substring(1);
}

/// "Two short calls a day" / "One short call a day" — the count spelled out with the noun
/// agreeing with it. Getting this wrong reads as a bug even when the number is right.
String countedPhrase(int n, String singular, String plural) =>
    '${capitalisedNumberWord(n)} ${n == 1 ? singular : plural}';

/// "Second" for 2, falling back to "2nd"-style digits beyond the table.
String ordinalWord(int n) {
  if (n > 0 && n < _ordinals.length) return _ordinals[n];
  if (n <= 0) return '$n';
  // 11th–13th are the usual exceptions to the suffix rule.
  final suffix = (n % 100 >= 11 && n % 100 <= 13)
      ? 'th'
      : switch (n % 10) { 1 => 'st', 2 => 'nd', 3 => 'rd', _ => 'th' };
  return '$n$suffix';
}
