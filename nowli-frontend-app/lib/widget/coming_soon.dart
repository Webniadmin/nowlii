import 'dart:ui';

import 'package:flutter/material.dart';

/// Shows a control that exists in the design but is not available yet — blurred, dimmed and
/// inert.
///
/// The point is to be honest rather than tidy. Hiding an unfinished feature makes the app
/// look finished and then surprises the user when it appears; leaving it tappable makes a
/// promise the app cannot keep. Blurring says "this is coming" without pretending it works.
///
/// Taps are swallowed and the control is hidden from screen readers: announcing a button
/// that does nothing is worse than not announcing it.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.child, this.sigma = 1.8});

  final Widget child;

  /// Blur radius. Enough to read the shape and not the detail.
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.55,
          child: ImageFiltered(
            // `decal` stops the blur smearing the edges into whatever sits next to it.
            imageFilter: ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
              tileMode: TileMode.decal,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
