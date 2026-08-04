import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/services/spark_state.dart';

/// Takes the place of the "Ready to make today count?" card once both of the day's sparks
/// are spent. The point is that being out is a designed ending rather than a failure —
/// hence the closing line and the sleeping companion, not a lock icon.
///
/// Only ever built when [SparkState.isSpent] is true; it never has to render a
/// "you still have sparks" state, and an unknown quota must not reach it (that would claim
/// the day is over on the strength of a dropped request).
class OutOfSparksCard extends StatelessWidget {
  final SparkState sparks;

  const OutOfSparksCard({super.key, required this.sparks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        gradient: RadialGradient(
          radius: 0.5,
          transform: _FillBoxEllipse(),
          colors: [
            Color(0xFFFFFEF8),
            Color(0xFFD0F3B5),
            Color(0xFFB8EE93),
            Color(0xFFA0E871),
          ],
          stops: [0.17788, 0.58894, 0.79447, 1.0],
        ),
      ),
      child: Stack(
        // The companion sits closer to the card's edge than the padding allows, so it is
        // placed at negative offsets. Stack clips to its own bounds by default, which would
        // shave the art; the outer Container still clips it to the rounded corners.
        clipBehavior: Clip.none,
        children: [
          // It sits behind the copy, which is why the text column is capped at 200 rather
          // than filling the card.
          Positioned(
            right: -7,
            bottom: -9.5,
            child: Opacity(
              opacity: 0.92,
              child: Transform.rotate(
                angle: -1.98 * 3.1415926535 / 180,
                child: Image.asset(
                  Assets.svgIcons.companionSleeping.path,
                  width: 78.885,
                  height: 118.327,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sparks.spentEyebrow.toUpperCase(),
                  style: GoogleFonts.archivo(
                    color: const Color(0xCC011F54),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: 1.32,
                  ),
                ),
                const SizedBox(height: 14.8),
                Text(
                  // A spent day ends by design and says so warmly. A paused plan is not an
                  // ending, and promising Nowlii "will be back tomorrow" would be untrue —
                  // nothing comes back on its own.
                  sparks.paused
                      ? 'CALLS\nARE\nPAUSED.'
                      : 'THAT\'S\nENOUGH\nFOR TODAY.',
                  style: const TextStyle(
                    fontFamily: 'Wosker',
                    color: Color(0xFF011F54),
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 14.8),
                Text(
                  sparks.paused
                      ? 'Everything you have already done is still here. Renew to talk '
                          'to Fuzzy again.'
                      : 'You said it. You picked the next step. Nowlii will be back tomorrow.',
                  style: GoogleFonts.workSans(
                    color: const Color(0xB8011F54),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stretches a radial gradient horizontally so it fills the card as an ellipse.
///
/// Flutter measures `RadialGradient.radius` against the **shortest** side, so on a card that
/// is much wider than it is tall a plain radius of 0.5 paints a circle: the pale centre goes
/// full green well before the left and right edges, and the card reads as a green band
/// rather than the designed glow. Scaling the gradient space by the aspect ratio restores
/// the ellipse the design actually specifies (radii 167.5 × 120.14 on a 335 × 240 card).
class _FillBoxEllipse extends GradientTransform {
  const _FillBoxEllipse();

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    if (bounds.height <= 0 || bounds.width <= 0) return null;
    final wide = bounds.width >= bounds.height;
    final scaleX = wide ? bounds.width / bounds.height : 1.0;
    final scaleY = wide ? 1.0 : bounds.height / bounds.width;
    return Matrix4.identity()
      ..translateByDouble(bounds.center.dx, bounds.center.dy, 0, 1)
      ..scaleByDouble(scaleX, scaleY, 1, 1)
      ..translateByDouble(-bounds.center.dx, -bounds.center.dy, 0, 1);
  }
}
