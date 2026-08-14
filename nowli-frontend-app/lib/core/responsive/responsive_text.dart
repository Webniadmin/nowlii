import 'package:flutter/material.dart';

/// One global lever for text size, so narrow phones stop breaking the layout.
///
/// The app was drawn at 375pt and almost every `fontSize:` in it is a raw
/// literal — roughly 900 of them across 118 files, against ~27 that use `.sp`.
/// Rewriting all of those was never going to happen safely, but Flutter applies
/// [MediaQueryData.textScaler] to *every* `Text` in the subtree regardless of
/// how its size was written, so one override at the root reaches all of them.
///
/// Two things are clamped here:
///
/// * **Screen width.** At 375 and up nothing changes — the design is untouched.
///   Below that the type shrinks in proportion, bottoming out at 320 (0.85),
///   the narrowest phone we support. This is what stops headings and button
///   labels from wrapping to a second line and blowing out fixed-height pills.
/// * **The OS font-size slider.** It used to pass through unbounded, which is a
///   bigger source of overflow than screen width: a user on 130% text broke the
///   layout even on a 375 device. Capped at 1.15 so accessibility scaling still
///   does something without destroying the design.
///
/// Note this scales *text only*. Fixed paddings, `SizedBox` widths and hard
/// container heights are unaffected, so a handful of spots still need local
/// `Flexible`/`maxLines` treatment — this just reduces them from a hundred to a
/// handful.
class ResponsiveText extends StatelessWidget {
  const ResponsiveText({super.key, required this.child});

  /// The width the whole app was designed at. Matches `ScreenUtilInit`'s
  /// `designSize` in main.dart — keep the two in step.
  static const double designWidth = 375;

  /// Narrowest screen we support. Below this the type stops shrinking, because
  /// past ~0.85 it starts being genuinely hard to read.
  static const double minWidth = 320;

  /// Bounds on the OS text-size setting.
  static const double minUserScale = 0.85;
  static const double maxUserScale = 1.15;

  final Widget child;

  /// The width factor on its own, for the rare widget that needs to size
  /// something non-textual to match (an icon beside a shrunk label, say).
  static double fitFactor(BuildContext context) =>
      (MediaQuery.sizeOf(context).width / designWidth)
          .clamp(minWidth / designWidth, 1.0);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    // 375+ -> 1.0, 360 -> 0.96, 320 -> 0.853.
    final fit = (mq.size.width / designWidth).clamp(minWidth / designWidth, 1.0);

    // Bound the OS font-size setting, then apply the width fit on top.
    //
    // Deliberately NOT `TextScaler.linear(fit * someFactor)`: since Android 14 the
    // platform scaler is *non-linear* — body text grows with the accessibility slider
    // while headings barely move, which is the behaviour users on large-text settings
    // rely on. Flattening it to a single factor threw that curve away. Verified on an
    // emulator: at `font_scale=1.3`, sampling the scaler at a heading size reports ~1.0,
    // so a naive factor would have silently applied *no* enlargement anywhere.
    //
    // `clamp` keeps the platform curve and only bounds its result; `_FittedTextScaler`
    // then multiplies by the width fit.
    final bounded = mq.textScaler.clamp(
      minScaleFactor: minUserScale,
      maxScaleFactor: maxUserScale,
    );

    return MediaQuery(
      data: mq.copyWith(
        textScaler: fit == 1.0 ? bounded : _FittedTextScaler(bounded, fit),
      ),
      child: child,
    );
  }
}

/// Applies the narrow-screen shrink on top of the platform's own text scaler,
/// preserving whatever curve the platform uses rather than replacing it.
@immutable
class _FittedTextScaler extends TextScaler {
  const _FittedTextScaler(this.inner, this.fit);

  final TextScaler inner;
  final double fit;

  @override
  double scale(double fontSize) => inner.scale(fontSize) * fit;

  @override
  double get textScaleFactor =>
      // ignore: deprecated_member_use
      inner.textScaleFactor * fit;

  // Overridden so text widgets do not rebuild when an equal scaler is rebuilt —
  // the base class compares by identity, and this one is constructed per build.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FittedTextScaler && other.inner == inner && other.fit == fit);

  @override
  int get hashCode => Object.hash(inner, fit);

  @override
  String toString() => 'fitted(${fit}x of $inner)';
}
