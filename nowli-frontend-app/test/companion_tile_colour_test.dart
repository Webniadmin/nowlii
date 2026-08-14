import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/api/nowlii_options_api.dart';

/// The colour behind each companion in the onboarding picker.
///
/// This is the third time the same mistake has been found in this app: art
/// chosen by `(predefined_option - 1) % 6`. Production serves ids
/// **2, 3, 4, 6, 10, 12** — the table was reseeded, so the ids are neither
/// 1-based nor contiguous — and that arithmetic puts five of the six
/// companions on the wrong colour while collapsing two pairs onto one colour
/// each. It was fixed for the *character* on 2026-08-12 and was still live for
/// the *tile* until 2026-08-14.
///
/// So these assert against the real production ids, paired with the real
/// `avatar_logo` filenames, which is what the resolution actually keys off.
void main() {
  /// The six rows as production serves them.
  NowliiOption option(int id, String slug) => NowliiOption(
        id: id,
        name: slug,
        avatarLogo:
            'https://nowlii-media.s3.eu-north-1.amazonaws.com/nowlii_logos/$slug.png',
      );

  const navy = Color(0xFF011F54);
  const orange = Color(0xFFFF8F26);
  const peach = Color(0xFFFAE3CE);
  const paleBlue = Color(0xFFDFEFFF);
  const indigo = Color(0xFF4542EB);

  group('tile colour follows the companion, not the id', () {
    test('milo is navy', () {
      expect(option(2, 'milo').backgroundColor, navy);
    });

    test('knotty is pale blue', () {
      expect(option(3, 'knotty').backgroundColor, paleBlue);
    });

    test('gumo is peach', () {
      expect(option(4, 'gumo').backgroundColor, peach);
    });

    test('bloop is orange', () {
      expect(option(10, 'bloop').backgroundColor, orange);
    });

    test('fizzy is indigo', () {
      expect(option(6, 'fizzy').backgroundColor, indigo);
    });

    test('zee carries the gradient, and only zee', () {
      expect(option(12, 'zee').backgroundGradient, isNotNull);
      for (final slug in ['milo', 'bloop', 'gumo', 'knotty', 'fizzy']) {
        expect(
          option(2, slug).backgroundGradient,
          isNull,
          reason: '$slug should be a flat colour',
        );
      }
    });
  });

  test('the six production companions get six different colours', () {
    // The id arithmetic gave 4 and 10 the same slot, and 6 and 12 the same
    // slot — two pairs of companions sharing a colour between them. Whatever
    // else changes, six rows must never resolve to fewer than six.
    final production = {
      2: 'milo',
      3: 'knotty',
      4: 'gumo',
      6: 'fizzy',
      10: 'bloop',
      12: 'zee',
    };

    final colours = production.entries
        .map((e) => option(e.key, e.value).backgroundColor)
        .toSet();

    expect(colours.length, 6);
  });

  test('falls back to the name when the URL is not a known filename', () {
    // An unseeded backend serves bundled asset paths instead of S3 URLs, and a
    // future one may serve something else again. The preset name is the backup.
    final fromName = NowliiOption(
      id: 99,
      name: 'gumo',
      avatarLogo: 'https://example.test/some/other/path.png',
    );
    expect(fromName.backgroundColor, peach);
  });
}
