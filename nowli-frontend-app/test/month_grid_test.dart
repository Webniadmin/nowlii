import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/month_grid.dart';

/// The Monthly Overview grid used to drop the backend's list of days straight into a
/// 7-wide layout, so the 1st always landed under **Mo**. August 2026 starts on a Saturday,
/// which put every mark in the month two columns to the right of the day it belonged to —
/// a quest finished on Monday the 3rd was drawn on Wednesday.
void main() {
  List<String> month(int year, int monthNo) {
    final days = DateTime(year, monthNo + 1, 0).day;
    return [
      for (var d = 1; d <= days; d++)
        DateTime(year, monthNo, d).toIso8601String().split('T').first,
    ];
  }

  group('the 1st starts in its own column', () {
    test('a month beginning on Saturday is padded by five', () {
      // August 2026: the reported case.
      final cells = monthGridCells(month(2026, 8));
      expect(cells.take(5), everyElement(isNull));
      expect(cells[5], 0);
    });

    test('a month beginning on Monday needs no padding', () {
      // June 2026 starts on a Monday — the only case the old code got right.
      expect(DateTime(2026, 6, 1).weekday, DateTime.monday);
      expect(monthGridCells(month(2026, 6)).first, 0);
    });

    test('a month beginning on Sunday is padded by six', () {
      expect(DateTime(2026, 3, 1).weekday, DateTime.sunday);
      final cells = monthGridCells(month(2026, 3));
      expect(cells.take(6), everyElement(isNull));
      expect(cells[6], 0);
    });
  });

  group('every day lands on its real weekday', () {
    test('August 2026 puts Monday the 3rd in the Monday column', () {
      final dates = month(2026, 8);
      final cells = monthGridCells(dates);
      final position = cells.indexOf(2); // the 3rd is index 2 in the source list

      expect(DateTime(2026, 8, 3).weekday, DateTime.monday);
      expect(position % 7, 0, reason: 'column 0 is Monday');
    });

    test('holds for every day of several differently-starting months', () {
      for (final m in [1, 2, 3, 6, 8, 11]) {
        final dates = month(2026, m);
        final cells = monthGridCells(dates);
        for (var i = 0; i < cells.length; i++) {
          final dayIndex = cells[i];
          if (dayIndex == null) continue;
          final date = DateTime.parse(dates[dayIndex]);
          expect(
            i % 7,
            date.weekday - 1,
            reason: '$date should sit in column ${date.weekday - 1}',
          );
        }
      }
    });

    test('the grid holds the padding plus every day, and nothing else', () {
      final dates = month(2026, 8);
      final cells = monthGridCells(dates);
      expect(cells.length, 5 + 31);
      expect(cells.whereType<int>().length, 31);
    });
  });

  group('bad input does not take the tab down', () {
    test('an empty calendar is an empty grid', () {
      expect(monthGridCells(const []), isEmpty);
    });

    test('an unparseable first date falls back to no padding', () {
      final cells = monthGridCells(['not-a-date', '2026-08-02']);
      expect(cells.length, 2);
      expect(cells.first, 0);
    });
  });

  group('the number printed in a cell', () {
    test('is the day of the month, not the position in the list', () {
      expect(dayOfMonth('2026-08-16', fallbackIndex: 15), 16);
    });

    test('falls back to the position when the date is unreadable', () {
      expect(dayOfMonth('rubbish', fallbackIndex: 15), 16);
    });
  });
}
