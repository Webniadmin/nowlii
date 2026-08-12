import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/services/companion_avatar.dart';

/// The pose art is addressed by string (`assets/companions/<id>_<pose>.png`), so a
/// missing file, a typo, or a folder left out of `pubspec.yaml` fails silently at
/// runtime — the slot just falls back to the neutral tile and looks merely wrong
/// rather than broken. These tests catch all three at build time.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const poses = [
    CompanionPose.sleeping,
    CompanionPose.reading,
    CompanionPose.speaking,
    CompanionPose.waving,
  ];

  test('neutral has no bundled path — it is the profile picture', () {
    const companion = CompanionIdentity(optionId: 3);
    expect(companion.posePath(CompanionPose.neutral), isNull);
  });

  test('every companion has every pose, and each one loads from the bundle',
      () async {
    for (var id = 1; id <= 6; id++) {
      for (final pose in poses) {
        final path = CompanionIdentity(optionId: id).posePath(pose);
        expect(path, 'assets/companions/${id}_${pose.name}.png');

        // rootBundle, not dart:io — this fails if the asset exists on disk but the
        // folder was never declared in pubspec.yaml, which is the likelier mistake.
        final bytes = await rootBundle.load(path!);
        expect(bytes.lengthInBytes, greaterThan(0),
            reason: '$path is registered but empty');
      }
    }
  });

  group('the character is identified by the picture, not the primary key', () {
    // These are the six rows production actually serves. The ids are neither 1-based
    // nor contiguous — the table was reseeded — so `(id - 1) % 6` maps five of the six
    // to the wrong character and collides 4 with 10 and 6 with 12. Anything keyed off
    // the id alone will fail this group, which is the point of it.
    const live = {
      2: ['milo', 1],
      10: ['bloop', 2],
      4: ['gumo', 3],
      3: ['knotty', 4],
      6: ['Fizzy', 5], // capital F on S3 — the match has to be case-insensitive
      12: ['zee', 6],
    };

    test('every production companion resolves to its own art', () {
      live.forEach((id, v) {
        final slug = v[0] as String;
        final slot = v[1] as int;
        final companion = CompanionIdentity(
          optionId: id,
          imageUrl:
              'https://nowlii.s3.eu-north-1.amazonaws.com/nowlii_logos/$slug.png',
        );
        expect(companion.posePath(CompanionPose.reading),
            'assets/companions/${slot}_reading.png',
            reason: '$slug (id $id) drew the wrong character');
      });
    });

    test('the preset name carries it when there is no picture', () {
      expect(
        const CompanionIdentity(optionId: 2, presetName: 'Milo')
            .posePath(CompanionPose.sleeping),
        'assets/companions/1_sleeping.png',
      );
    });

    test('renaming the companion does not change the character', () {
      // The naming screen invites a rename, and matching on the display name is a bug
      // this app has already shipped once.
      const renamed = CompanionIdentity(
        optionId: 12,
        imageUrl: 'https://nowlii.s3.eu-north-1.amazonaws.com/nowlii_logos/zee.png',
        presetName: 'Zee',
        name: 'Bobo',
      );
      expect(renamed.posePath(CompanionPose.speaking),
          'assets/companions/6_speaking.png');
    });

    test('an unrecognised companion still renders something', () {
      expect(const CompanionIdentity().posePath(CompanionPose.speaking),
          'assets/companions/1_speaking.png');
      expect(
        const CompanionIdentity(optionId: 99, imageUrl: 'https://x/y/unknown.png')
            .posePath(CompanionPose.waving),
        isNotNull,
      );
    });
  });
}
