import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/models/quest_suggestion_model.dart';
import 'package:nowlii/utils/color_palette/zone_colors.dart';

/// There were five separate zone colour tables, and only Soft steps agreed across all of
/// them: a Power move was red on the Quests tab, coral in the suggestions list and lilac
/// on the Soft steps screen. A colour code that means something different on each screen
/// is not a code — it is decoration that looks like information.
void main() {
  group('the four zones', () {
    test('each has its own colour', () {
      final colours = {
        zoneColor('Soft steps'),
        zoneColor('Elevated'),
        zoneColor('Stretch zone'),
        zoneColor('Power move'),
      };
      expect(colours.length, 4, reason: 'two zones share a colour');
    });

    test('are the values the app already shipped on Quests', () {
      expect(zoneColor('Soft steps'), const Color(0xFFA0E871));
      expect(zoneColor('Elevated'), const Color(0xFFFF8F26));
      expect(zoneColor('Stretch zone'), const Color(0xFF3D87F5));
      expect(zoneColor('Power move'), const Color(0xFFD53D40));
    });
  });

  group('however the name arrives', () {
    test('the suggestion endpoints send it lower-cased', () {
      // quest_suggestions_list and the suggestion model both looked up
      // `zone.toLowerCase()`, while the my_quests screens matched the exact string. One
      // table has to answer both.
      expect(zoneColor('power move'), zoneColor('Power move'));
      expect(zoneColor('SOFT STEPS'), zoneColor('Soft steps'));
    });

    test('stray whitespace does not change the answer', () {
      expect(zoneColor('  Stretch zone '), zoneColor('Stretch zone'));
    });

    test('an unknown zone falls back to the gentlest, not to nothing', () {
      // A zone the app does not know is still a quest the user can see.
      expect(zoneColor('Hyperdrive'), kSoftStepsColor);
      expect(zoneColor(''), kSoftStepsColor);
    });
  });

  group('what is written on the badge', () {
    test('the warm zones carry the dark navy', () {
      // Two screens derived this from luminance instead, and the arithmetic put white on
      // the orange — legible, but not the design, and not what the other three screens
      // were showing for the same badge.
      expect(zoneTextColor('Soft steps'), const Color(0xFF011F54));
      expect(zoneTextColor('Elevated'), const Color(0xFF011F54));
    });

    test('the dark zones carry the light text', () {
      expect(zoneTextColor('Stretch zone'), const Color(0xFFEEEEEE));
      expect(zoneTextColor('Power move'), const Color(0xFFFFFDF7));
    });

    test('is never the same as the badge behind it', () {
      for (final zone in [
        'Soft steps',
        'Elevated',
        'Stretch zone',
        'Power move',
      ]) {
        expect(zoneTextColor(zone), isNot(zoneColor(zone)), reason: zone);
      }
    });

    test('follows the same case-insensitive lookup as the colour', () {
      expect(zoneTextColor('power move'), zoneTextColor('Power move'));
      expect(zoneTextColor('Hyperdrive'), zoneTextColor('Soft steps'));
    });
  });

  group('the hex form agrees with the colour form', () {
    test('for every zone', () {
      for (final zone in [
        'Soft steps',
        'Elevated',
        'Stretch zone',
        'Power move',
      ]) {
        expect(
          zoneColorHex(zone),
          '#${(zoneColor(zone).toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
          reason: '$zone disagrees between its Color and its hex string',
        );
      }
    });

    test('and the suggestion model reads from the same table', () {
      // It used to carry its own copy, which is how a Power move became #FF6B6B here and
      // #D53D40 three screens away.
      final suggestion = QuestSuggestion(
        task: 'Walk',
        zone: 'Power move',
        description: '',
        suggestedTime: '10:00',
      );
      expect(suggestion.getZoneColor(), zoneColorHex('Power move'));
    });
  });
}
