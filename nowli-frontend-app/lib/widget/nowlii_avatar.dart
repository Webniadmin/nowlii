import 'package:flutter/material.dart';
import 'package:nowlii/services/companion_avatar.dart';

// So a screen that shows the companion needs one import, not two.
export 'package:nowlii/services/companion_avatar.dart' show CompanionPose;

/// The user's chosen companion, wherever a companion is drawn.
///
/// Every screen that shows the character should use this rather than an asset path, so
/// the picture follows the pick — and so the next art drop is a change to one file
/// instead of twenty-five.
///
/// **The companion is never cropped.** The art the backend serves has a transparent
/// background, so it is drawn whole with [BoxFit.contain] and no clip: the character
/// stands on the screen's own background exactly as designed. An earlier version clipped
/// everything to a circle with [BoxFit.cover], which sliced the character's feet off on
/// the call screen.
///
/// The clip is only for the **bundled fallback** tiles in `assets/svg_images/A–F.png`,
/// which are picker art with an opaque colour baked in (five of the six — only fizzy/E is
/// transparent). Drawn raw on a light surface those paint a coloured rectangle over the
/// layout, so [circle] — or [borderRadius] — applies to that path alone.
///
/// Pass a [pose] for the slots that used to hold a *specific* picture — the sleeping
/// companion on the out-of-sparks card, the one reading on the home quest card, the one
/// speaking in a call. Those come from `assets/companions/` and never from the network,
/// because the backend has one picture per companion and no notion of a pose.
class NowliiAvatar extends StatelessWidget {
  const NowliiAvatar({
    super.key,
    required this.size,
    this.height,
    this.pose = CompanionPose.neutral,
    this.circle = true,
    this.fit = BoxFit.contain,
    this.opacity = 1.0,
    this.borderRadius,
  });

  /// What the companion is doing here. Defaults to [CompanionPose.neutral], which is
  /// the profile's own picture — the behaviour every call site had before poses existed.
  final CompanionPose pose;

  /// Rendered width, and the height too unless [height] says otherwise. Nearly every
  /// slot that held a companion was square.
  final double size;

  /// Height, when the slot is not square — the receipt footer's is 32 × 48. Left null
  /// everywhere else, which keeps [size] meaning both dimensions.
  final double? height;

  /// Shape of the **fallback** tile's clip. Has no effect on the served art, which is
  /// transparent and needs no clipping.
  final bool circle;

  /// How the served art fits its box. Defaults to [BoxFit.contain] so the character is
  /// always whole; do not set [BoxFit.cover] here, it crops.
  final BoxFit fit;

  /// Some screens dim the companion behind foreground copy.
  final double opacity;

  /// Clip the fallback tile to a rounded rectangle rather than a circle, for the slots
  /// whose original art was an app-icon-style tile (all-quests-done, missed-talks).
  final BorderRadius? borderRadius;

  double get _h => height ?? size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CompanionIdentity>(
      valueListenable: CompanionAvatar.identity,
      builder: (context, companion, _) {
        Widget image;

        final posed = companion.posePath(pose);

        if (posed != null) {
          // Transparent like the served art, so it is drawn whole and unclipped for the
          // same reason: `cover` plus a circle sliced the character's feet off.
          image = Image.asset(
            posed,
            width: size,
            height: _h,
            fit: fit,
            errorBuilder: (_, __, ___) => _fallback(companion),
          );
        } else if (companion.isNetwork) {
          image = Image.network(
            companion.imageUrl!,
            width: size,
            height: _h,
            fit: fit,
            // Falls back to the *chosen* companion's bundled art. The old fallbacks were
            // a hardcoded A.png, so a failed load showed every user milo.
            errorBuilder: (_, __, ___) => _fallback(companion),
            // A transparent hole rather than a coloured block: this sits on cards of
            // several different colours, and a tinted square flashing in for a frame
            // reads as a rendering fault.
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : SizedBox(width: size, height: _h),
          );
        } else if (companion.isAsset) {
          image = Image.asset(
            companion.imageUrl!,
            width: size,
            height: _h,
            fit: fit,
            errorBuilder: (_, __, ___) => _fallback(companion),
          );
        } else {
          image = _fallback(companion);
        }

        return opacity == 1.0 ? image : Opacity(opacity: opacity, child: image);
      },
    );
  }

  /// The bundled tile, clipped — this is the one path whose art has an opaque background.
  Widget _fallback(CompanionIdentity companion) {
    final image = Image.asset(
      companion.assetPath,
      width: size,
      height: _h,
      // cover, not contain: the tile is meant to fill its clip, and its background is
      // solid colour so nothing meaningful is lost at the edges.
      fit: BoxFit.cover,
    );

    // A circle needs a square box; on a 32 × 48 slot it would letterbox oddly, so an
    // oblong falls back to the rectangle path.
    final asCircle = borderRadius == null && circle && _h == size;
    if (borderRadius == null && !asCircle) return image;

    return Container(
      width: size,
      height: _h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: asCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
      ),
      child: image,
    );
  }
}
