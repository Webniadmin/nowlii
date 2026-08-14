/// Parses a datetime as this API can actually emit it.
///
/// The backend sets a project-wide DRF `DATETIME_FORMAT` of `"%d-%m-%Y %H:%M:%S"`
/// (`core/settings.py`). That is not ISO-8601: `DateTime.parse` throws on it and
/// `DateTime.tryParse` returns null. Anything reading a date straight through therefore
/// lost it silently — receipt dates rendered blank, and `ScheduledCall.fromJson` threw,
/// which the service caught and turned into an empty list, so planned calls looked like
/// they did not exist.
///
/// The offending fields now serialize as ISO-8601 explicitly, but this stays tolerant of
/// both: an app build can outlive a backend deploy, and other endpoints still use the
/// project-wide format.
///
/// Pure Dart, no Flutter — see `test/api_date_test.dart`.
library;

/// Returns null for null, non-strings, blanks and anything unparseable — never throws.
///
/// The legacy `dd-MM-yyyy HH:mm:ss` form carries **no timezone**, and the server renders
/// UTC, so it is read as UTC and converted. Guessing local there would shift every value
/// by the device's offset, which is exactly how the reminders drifted.
DateTime? parseApiDate(dynamic value) {
  if (value is! String) return null;
  final raw = value.trim();
  if (raw.isEmpty) return null;

  // ISO-8601 first: it is what the fixed endpoints send, and it carries an offset.
  final iso = DateTime.tryParse(raw);
  if (iso != null) return iso.toLocal();

  final match = _legacy.firstMatch(raw);
  if (match == null) return null;

  int group(int i) => int.parse(match.group(i)!);
  final day = group(1);
  final month = group(2);
  final year = group(3);
  final hour = match.group(4) == null ? 0 : group(4);
  final minute = match.group(5) == null ? 0 : group(5);
  final second = match.group(6) == null ? 0 : group(6);

  final built = DateTime.utc(year, month, day, hour, minute, second);
  // DateTime silently rolls overflow forward — DateTime.utc(9999, 99, 99) is a real date,
  // and 31 February quietly becomes 2 or 3 March. Round-tripping is what turns nonsense
  // into null instead of a confidently wrong timestamp.
  if (built.year != year ||
      built.month != month ||
      built.day != day ||
      built.hour != hour ||
      built.minute != minute ||
      built.second != second) {
    return null;
  }
  return built.toLocal();
}

/// `31-07-2026 09:30:37`, with the time optional.
final RegExp _legacy = RegExp(
  r'^(\d{1,2})-(\d{1,2})-(\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
);
