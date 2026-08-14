/// Laying a month's days out under Mo–Su column headers.
///
/// The backend sends one entry per day of the month, in order, starting at the 1st. The
/// grid drew them straight into a 7-wide layout, so the 1st always landed under **Mo** and
/// every mark in the month sat under the wrong weekday — August 2026 starts on a Saturday,
/// so a quest finished on Monday the 3rd showed up on a Wednesday.
///
/// Pure Dart, no Flutter — see `test/month_grid_test.dart`.
library;

/// Where each day of the month goes, as offsets into the source list.
///
/// The result is the grid read left-to-right, top-to-bottom: leading `null`s are the empty
/// cells before the 1st, and every other entry is an index into [isoDates]. Columns are
/// Monday-first, matching the headers above the grid.
///
/// An unparseable or empty first date gives no padding rather than throwing — a calendar
/// off by a few columns is a bug, a crashed Insights tab is worse.
List<int?> monthGridCells(List<String> isoDates) {
  if (isoDates.isEmpty) return const [];

  final first = DateTime.tryParse(isoDates.first);
  // DateTime.weekday is 1 for Monday through 7 for Sunday, so this is the column the 1st
  // belongs in and equally the number of blanks before it.
  final leadingBlanks = first == null ? 0 : first.weekday - 1;

  return [
    ...List<int?>.filled(leadingBlanks, null),
    ...List<int?>.generate(isoDates.length, (i) => i),
  ];
}

/// The day-of-month number to print in a cell, from its ISO date.
///
/// Falls back to the day's position in the month, which is right for every calendar the
/// backend actually sends (it always starts at the 1st).
int dayOfMonth(String isoDate, {required int fallbackIndex}) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed != null) return parsed.day;
  return fallbackIndex + 1;
}
