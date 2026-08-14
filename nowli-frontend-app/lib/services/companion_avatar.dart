import 'package:flutter/material.dart';
import 'package:nowlii/api/profile_model.dart';

/// What the companion is doing in a given slot.
///
/// [neutral] is not a picture — it means "whatever the profile carries", which is the
/// S3 URL the backend copies from the chosen option. Every other value is bundled art
/// in `assets/companions/`, one file per character per pose, because the backend serves
/// a single neutral picture and knows nothing about poses.
enum CompanionPose {
  neutral,

  /// Out of sparks. The day is over.
  sleeping,

  /// The home quest card — the companion reading, as the original art did.
  reading,

  /// Mid-sentence: the voice check, the speaking popups and the live call.
  speaking,

  /// Arms out, greeting. Shipped and usable; no slot claims it yet.
  waving,
}

/// Which companion the user picked, resolved once and readable from anywhere.
///
/// The pick itself is `Profile.predefined_option`; the backend copies that option's
/// picture into `Profile.avatar_logo` (an S3 URL) on save, so the URL is the thing to
/// render and the id is the offline fallback. Both arrive on the profile we already
/// cache in [SecureStorage], so nothing here costs a request.
///
/// Screens used to hardcode a picture instead, which is why a user who picked, say, the
/// green companion still met an orange one on the home card and in every call.
@immutable
class CompanionIdentity {
  const CompanionIdentity({
    this.imageUrl,
    this.optionId,
    this.name = 'Nowlii',
    this.presetName = '',
  });

  /// Whatever the profile carries — usually an S3 URL, but onboarding briefly stores a
  /// bundled asset path here, so [isAsset] decides how to render it.
  final String? imageUrl;

  /// `NowliiPredefinedOption` id. 1–6 in every environment we ship, but treated as
  /// possibly-anything because it is a database primary key.
  final int? optionId;

  /// The companion's name, renamed by the user if they chose to. Display only — never
  /// identify the character with this, see [_slot].
  final String name;

  /// The option's own name (`Milo`, `Zee`, …), untouched by the user's rename. Used to
  /// identify the character when the picture URL is missing.
  final String presetName;

  static const CompanionIdentity fallback = CompanionIdentity();

  /// The six bundled companions, in option-id order: milo, bloop, gumo, knotty, fizzy, zee.
  static const List<String> _assets = [
    'assets/svg_images/A.png',
    'assets/svg_images/B.png',
    'assets/svg_images/C.png',
    'assets/svg_images/D.png',
    'assets/svg_images/E.png',
    'assets/svg_images/F.png',
  ];

  /// Background baked into each tile. Five of the six PNGs are fully opaque with a solid
  /// colour behind the character (only fizzy/E has real transparency), so anything drawing
  /// one on a light surface has to clip it — see `NowliiAvatar`. Matching the colour here
  /// lets a placeholder or a ring blend with the art instead of flashing white.
  static const List<Color> _backgrounds = [
    Color(0xFF011F54), // milo  — navy
    Color(0xFFFF8F26), // bloop — orange
    Color(0xFFADA59C), // gumo  — warm grey
    Color(0xFFDFEFFF), // knotty— pale blue
    Color(0xFF4542EB), // fizzy — indigo (the art itself is transparent)
    Color(0xFF3BB64B), // zee   — green
  ];

  /// The six companions in bundled order, by the filename the backend gives each one.
  /// This is the identity that survives a reseed; the primary key is not.
  static const List<String> _slugs = [
    'milo',
    'bloop',
    'gumo',
    'knotty',
    'fizzy',
    'zee',
  ];

  /// Zero-based slot for this companion.
  ///
  /// **Not the option id.** Production serves ids `2, 3, 4, 6, 10, 12` — the table has
  /// been reseeded and the rows are neither 1-based nor contiguous — so the old
  /// `(id - 1) % 6` resolved five of the six companions to the wrong character, and
  /// collided ids 4 with 10 and 6 with 12 onto one slot each. It went unnoticed because
  /// it only fed the offline fallback tile, and the QA account is Zee, the one id the
  /// arithmetic happened to get right. Poses read this on every draw, so it matters now.
  ///
  /// Resolved from the picture the backend copied off the option
  /// (`…/nowlii_logos/zee.png`), which is not user-editable; then the preset name; then
  /// the old id arithmetic, kept only so an unrecognised companion still renders
  /// something rather than nothing.
  int get _slot =>
      slotFor(imageUrl: imageUrl, presetName: presetName, optionId: optionId);

  /// The same resolution, for callers that hold an option rather than a profile —
  /// the onboarding picker, which has a list of `NowliiPredefinedOption`s and no
  /// companion of its own yet.
  ///
  /// Static and shared on purpose. The picker had its own `(id - 1) % 6` for tile
  /// colours, so it repeated this bug in full: on production ids it put milo on
  /// orange instead of navy and gave two pairs of companions the same colour.
  /// Two copies of an ordering rule is one copy too many.
  static int slotFor({
    String? imageUrl,
    String presetName = '',
    int? optionId,
  }) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      final file = url.split('/').last.split('.').first.toLowerCase();
      final bySlug = _slugs.indexOf(file);
      if (bySlug >= 0) return bySlug;
      // Onboarding parks a bundled path here before the profile round-trips.
      if (file.length == 1) {
        final byLetter = file.codeUnitAt(0) - 'a'.codeUnitAt(0);
        if (byLetter >= 0 && byLetter < _assets.length) return byLetter;
      }
    }

    // `presetName`, never `name` — `name` is the user's rename, and picking the
    // character by a name the user is invited to change is a bug this app has already
    // shipped once.
    final byName = _slugs.indexOf(presetName.toLowerCase());
    if (byName >= 0) return byName;

    return (((optionId ?? 1) - 1) % _assets.length).abs();
  }

  /// Bundled art for this companion. Used when there is no URL, and as the error fallback
  /// when the URL will not load — which used to hardcode milo for everybody.
  String get assetPath => _assets[_slot];

  /// Bundled art of this companion doing [pose].
  ///
  /// Poses are **always** bundled, never the profile's URL: the backend stores one
  /// neutral picture per companion, so asking S3 for a sleeping one would return the
  /// standing one and the slot would silently go back to being wrong. Keyed off
  /// [_slot], so it wraps for an unexpected id exactly as the tiles do.
  ///
  /// Returns null for [CompanionPose.neutral] — that slot wants the profile's picture,
  /// which only `NowliiAvatar` can resolve.
  String? posePath(CompanionPose pose) => pose == CompanionPose.neutral
      ? null
      : 'assets/companions/${_slot + 1}_${pose.name}.png';

  Color get backgroundColor => _backgrounds[_slot];

  bool get isAsset => imageUrl != null && imageUrl!.startsWith('assets/');

  bool get isNetwork =>
      imageUrl != null && imageUrl!.startsWith(RegExp('https?://'));

  @override
  bool operator ==(Object other) =>
      other is CompanionIdentity &&
      other.imageUrl == imageUrl &&
      other.optionId == optionId &&
      other.name == name &&
      other.presetName == presetName;

  @override
  int get hashCode => Object.hash(imageUrl, optionId, name, presetName);
}

/// App-wide holder for [CompanionIdentity].
///
/// A plain [ValueNotifier] rather than GetX or Provider because `ProfileController` is
/// constructed per screen and there is no root provider to hang this off — every screen
/// that wanted the avatar was left fetching or hardcoding its own.
class CompanionAvatar {
  CompanionAvatar._();

  static final ValueNotifier<CompanionIdentity> identity =
      ValueNotifier<CompanionIdentity>(CompanionIdentity.fallback);

  static CompanionIdentity get current => identity.value;

  /// Adopt a profile.
  ///
  /// Deliberately *not* called from screens. `StorageService` calls it on every profile
  /// read and write, which is the one place all of them funnel through — so a screen that
  /// saves a profile, or merely loads one, keeps the companion current for free. Sprinkling
  /// refresh calls around instead is how the avatar drifts out of sync again.
  static void adopt(ProfileModel? profile) {
    if (profile == null) return;

    final url = profile.avatarLogo;
    final custom = profile.customNowliiName;
    final preset = profile.nowliiName;

    identity.value = CompanionIdentity(
      imageUrl: (url != null && url.isNotEmpty) ? url : null,
      optionId: profile.predefinedOption,
      presetName: preset ?? '',
      name: (custom != null && custom.isNotEmpty)
          ? custom
          : (preset != null && preset.isNotEmpty)
              ? preset
              : 'Nowlii',
    );
  }

  /// Signing out must drop the companion too, or the next account on the device is
  /// greeted by the previous user's character until their profile loads.
  static void clear() => identity.value = CompanionIdentity.fallback;
}
