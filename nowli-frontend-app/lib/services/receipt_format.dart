/// Formatting rules for the receipt library.
///
/// A receipt is a saved voice-call summary presented as a paper receipt: a serial number,
/// a date, a length, and the user's own words. The backend stores none of that framing —
/// it stores summaries — so the numbering and the wording live here, in one place, rather
/// than being reinvented slightly differently on the list and the detail screen.
///
/// Pure Dart, no Flutter — see `test/receipt_format_test.dart`.
library;

import 'package:intl/intl.dart';

/// The receipt's serial number, oldest-first.
///
/// The API returns summaries newest-first, but a serial number that counts *down* as you
/// scroll back through your history would be meaningless — the first call you ever made
/// is no. 001 and stays no. 001 forever. So the number is derived from the position from
/// the end of the list.
///
/// [index] is the position in the newest-first list; [total] is its length.
int receiptNumber({required int index, required int total}) {
  if (total <= 0) return 0;
  final number = total - index;
  return number < 1 ? 1 : number;
}

/// "014" — zero-padded to three digits, which is what makes it read as a serial number.
/// Numbers past 999 simply get longer rather than being truncated or wrapped.
String receiptNumberLabel(int number) => number.toString().padLeft(3, '0');

/// How long the call lasted, as "04:58".
///
/// This is the call *length*, not a clock time — the design pairs it with the date, where
/// it would be easy to mistake one for the other.
String callLengthLabel(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final minutes = safe ~/ 60;
  final remainder = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}

/// "Tue 27 Jul" — the day a receipt belongs to.
String receiptDateLabel(DateTime? when) =>
    when == null ? '' : DateFormat('EEE d MMM').format(when);

/// The list's headline under "Your words, kept.": "14 receipts · since 3 July".
///
/// Singular is spelled out rather than "1 receipts", and the "since" half is dropped when
/// there is nothing to date it from.
String receiptsSummaryLine({required int count, DateTime? earliest}) {
  final noun = count == 1 ? 'receipt' : 'receipts';
  if (earliest == null) return '$count $noun';
  return '$count $noun · since ${DateFormat('d MMMM').format(earliest)}';
}

/// The uppercase headline on a list card: "NEXT STEP: OPEN THE FILE".
///
/// Returns an empty string when there is no next step, so the caller can fall back rather
/// than printing a bare "NEXT STEP:" with nothing after it.
String receiptCardTitle(String nextStep) {
  final step = nextStep.trim();
  if (step.isEmpty) return '';
  return 'Next step: $step'.toUpperCase();
}

/// A word as it appears on a receipt chip: “should”.
///
/// Curly quotes are the design's, and the word is printed exactly as the user said it —
/// these are quoted back as their own words, so nothing here changes their spelling.
String receiptWordLabel(String word) => '“${word.trim()}”';

/// The same words set as the receipt's headline block: one per line, capitalised, comma
/// separated, and closed with a full stop — “Should”, / “Later”, / “Stuck”.
///
/// Only the first letter is raised. Upper-casing the whole word would change how the user
/// said it, and these are printed as a quotation of them.
List<String> receiptWordLines(List<String> words) {
  final cleaned = words.map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
  return [
    for (int i = 0; i < cleaned.length; i++)
      '“${_capitalise(cleaned[i])}”${i == cleaned.length - 1 ? '.' : ','}',
  ];
}

String _capitalise(String word) =>
    word.length == 1 ? word.toUpperCase() : word[0].toUpperCase() + word.substring(1);
