import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/number_words.dart';

/// These spell out counts the backend owns — the daily spark allowance (an env var) and
/// the trial length. The copy has to survive those changing, including the awkward values.
void main() {
  test('spells out the small numbers copy actually uses', () {
    expect(numberWord(1), 'one');
    expect(numberWord(2), 'two');
    expect(numberWord(7), 'seven');
  });

  test('falls back to digits past the point where words help', () {
    expect(numberWord(13), '13');
    expect(numberWord(30), '30');
  });

  test('capitalises for the start of a sentence', () {
    expect(capitalisedNumberWord(2), 'Two');
    expect(capitalisedNumberWord(13), '13');
  });

  group('counted phrase', () {
    test('agrees the noun with the number', () {
      expect(
        countedPhrase(2, 'short call a day', 'short calls a day'),
        'Two short calls a day',
      );
      // "One short calls a day" reads as a bug even though the number is right.
      expect(
        countedPhrase(1, 'short call a day', 'short calls a day'),
        'One short call a day',
      );
    });

    test('still agrees past the word table', () {
      expect(countedPhrase(13, 'call', 'calls'), '13 calls');
    });
  });

  group('ordinals', () {
    test('names the sparks in order', () {
      expect(ordinalWord(1), 'First');
      expect(ordinalWord(2), 'Second');
      expect(ordinalWord(3), 'Third');
    });

    test('falls back to suffixed digits beyond the table', () {
      expect(ordinalWord(13), '13th');
      expect(ordinalWord(21), '21st');
      expect(ordinalWord(22), '22nd');
      expect(ordinalWord(23), '23rd');
      expect(ordinalWord(24), '24th');
    });

    test('handles the teens, which break the suffix rule', () {
      // 11th/12th/13th, not 11st/12nd/13rd.
      expect(ordinalWord(111), '111th');
      expect(ordinalWord(112), '112th');
    });
  });
}
