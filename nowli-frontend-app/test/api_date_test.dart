import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/api_date.dart';

/// The backend's project-wide DRF DATETIME_FORMAT is "%d-%m-%Y %H:%M:%S", which is not
/// ISO-8601. Reading it with DateTime.parse threw; DateTime.tryParse returned null. Both
/// failures were silent in their own way, so these pin the parser down.
void main() {
  test('reads ISO-8601 with an offset', () {
    final parsed = parseApiDate('2026-07-31T09:30:37Z');
    expect(parsed, isNotNull);
    expect(parsed!.toUtc(), DateTime.utc(2026, 7, 31, 9, 30, 37));
  });

  test('reads the legacy day-first format as UTC', () {
    // "31-07-2026 09:30:37" is 31 July, not 7 January — and it is UTC, because the server
    // renders UTC without saying so. Treating it as local shifted every reminder by the
    // device's offset.
    final parsed = parseApiDate('31-07-2026 09:30:37');
    expect(parsed, isNotNull);
    expect(parsed!.toUtc(), DateTime.utc(2026, 7, 31, 9, 30, 37));
  });

  test('reads the legacy format without a time', () {
    final parsed = parseApiDate('02-08-2026');
    expect(parsed!.toUtc(), DateTime.utc(2026, 8, 2));
  });

  test('does not confuse day-first with month-first', () {
    // 12-08 must be 12 August. Read the other way round it would be 8 December.
    final parsed = parseApiDate('12-08-2026 18:00:00');
    expect(parsed!.toUtc().month, 8);
    expect(parsed.toUtc().day, 12);
  });

  test('returns null instead of throwing on junk', () {
    // ScheduledCall.fromJson used to throw here, the service swallowed it, and the whole
    // list came back empty — planned calls looked like they did not exist.
    for (final junk in [null, '', '   ', 'tomorrow', 42, <String>[], '99-99-9999']) {
      expect(parseApiDate(junk), isNull, reason: 'for $junk');
    }
  });

  test('converts to the device clock', () {
    final parsed = parseApiDate('31-07-2026 09:30:37');
    expect(parsed!.isUtc, isFalse);
  });
}
