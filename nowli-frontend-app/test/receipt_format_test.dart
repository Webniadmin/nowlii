import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/receipt_format.dart';

/// A receipt's serial number and length are printed as fact, so the arithmetic behind
/// them is worth pinning — especially the direction of the numbering, which the API's
/// ordering works against.
void main() {
  group('serial number', () {
    test('counts from the oldest call, not the newest', () {
      // The API returns newest-first, but your first ever call must stay no. 001.
      expect(receiptNumber(index: 0, total: 14), 14);
      expect(receiptNumber(index: 1, total: 14), 13);
      expect(receiptNumber(index: 13, total: 14), 1);
    });

    test('handles a single receipt and an empty library', () {
      expect(receiptNumber(index: 0, total: 1), 1);
      expect(receiptNumber(index: 0, total: 0), 0);
    });

    test('is zero-padded to three digits so it reads as a serial', () {
      expect(receiptNumberLabel(14), '014');
      expect(receiptNumberLabel(1), '001');
      expect(receiptNumberLabel(999), '999');
    });

    test('grows rather than truncating past 999', () {
      expect(receiptNumberLabel(1234), '1234');
    });
  });

  group('call length', () {
    test('is minutes and seconds, both padded', () {
      expect(callLengthLabel(298), '04:58');
      expect(callLengthLabel(65), '01:05');
      expect(callLengthLabel(0), '00:00');
    });

    test('handles a call longer than ten minutes', () {
      expect(callLengthLabel(7 * 60 + 30), '07:30');
      expect(callLengthLabel(63 * 60), '63:00');
    });

    test('never renders a negative duration', () {
      expect(callLengthLabel(-5), '00:00');
    });
  });

  group('summary line', () {
    test('reads as the design does', () {
      expect(
        receiptsSummaryLine(count: 14, earliest: DateTime(2026, 7, 3)),
        '14 receipts · since 3 July',
      );
    });

    test('does not say "1 receipts"', () {
      expect(
        receiptsSummaryLine(count: 1, earliest: DateTime(2026, 7, 3)),
        '1 receipt · since 3 July',
      );
    });

    test('drops the "since" half when there is no date to use', () {
      expect(receiptsSummaryLine(count: 3), '3 receipts');
    });
  });

  group('card title', () {
    test('prefixes and uppercases the next step', () {
      expect(receiptCardTitle('Open the file'), 'NEXT STEP: OPEN THE FILE');
    });

    test('is empty when there is no next step, so the caller can fall back', () {
      // Otherwise the card would print a bare "NEXT STEP:" with nothing after it.
      expect(receiptCardTitle('   '), '');
    });
  });

  group('words', () {
    test('a chip quotes the word exactly as it was said', () {
      expect(receiptWordLabel('should'), '“should”');
    });

    test('the receipt block capitalises and punctuates each line', () {
      expect(
        receiptWordLines(['should', 'later', 'stuck']),
        ['“Should”,', '“Later”,', '“Stuck”.'],
      );
    });

    test('a single word ends the block rather than trailing a comma', () {
      expect(receiptWordLines(['should']), ['“Should”.']);
    });

    test('only the first letter is raised, so the rest is still their spelling', () {
      expect(receiptWordLines(['iPhone']), ['“IPhone”.']);
    });

    test('blanks are dropped and an empty list stays empty', () {
      expect(receiptWordLines(['  ', 'later']), ['“Later”.']);
      expect(receiptWordLines([]), isEmpty);
    });
  });
}
