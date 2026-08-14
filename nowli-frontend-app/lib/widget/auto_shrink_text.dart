import 'package:flutter/material.dart';

/// Text that gives up font size, a little at a time, until it fits the box it
/// was handed — instead of wrapping to an extra line, spilling out, or being
/// sliced in half by a parent's clip.
///
/// The app is drawn at 375pt and almost every `fontSize:` in it is a literal.
/// `ResponsiveText` already shrinks all of them in proportion on a narrow
/// screen, but that is a single global factor: it cannot know that *this*
/// sentence, in *this* card, needs one more line than the card has room for.
/// This closes that gap locally, and is the right tool wherever a fixed-height
/// box holds text whose length is not fixed — a card, a pill, a button label.
///
/// **Why not `FittedBox(fit: BoxFit.scaleDown)`.** That is the obvious answer
/// and it is wrong for anything that wraps: `FittedBox` hands its child
/// *unbounded* width, so a `Text` inside it lays out as one very long line and
/// is then scaled down to fit — the result is legible only under a magnifying
/// glass. `FittedBox` stays correct for a single-line label, which is why the
/// buttons in this app use it; multi-line copy needs this instead.
///
/// Measuring is done with the same [TextScaler] the surrounding widgets get, so
/// what is measured is what is painted, including the OS font-size setting.
///
/// **Do not put this inside `IntrinsicWidth` or `IntrinsicHeight`.** It is a
/// [LayoutBuilder], which cannot answer an intrinsic-size query, so the parent
/// measures it as nothing and the whole subtree collapses — silently, with no
/// error to point at it. That happened to the fourth tutorial bubble: the
/// screen dimmed and drew nothing at all.
class AutoShrinkText extends StatelessWidget {
  const AutoShrinkText(
    this.data, {
    super.key,
    required this.style,
    this.maxLines,
    this.textAlign,
    this.minFontSize = 9,
    this.stepSize = 0.5,
  });

  final String data;
  final TextStyle style;
  final int? maxLines;
  final TextAlign? textAlign;

  /// The floor. Past this, shrinking further trades one unreadable result for
  /// another, so the text is allowed to ellipsise instead.
  final double minFontSize;

  /// How much to give up per attempt. Smaller is closer to the largest size
  /// that fits, at the cost of more measuring passes.
  final double stepSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final startingSize = style.fontSize ?? 14;
        var size = startingSize;

        // An unbounded height means nothing is forcing the text to be short —
        // only the width and the line cap matter.
        final maxHeight = constraints.maxHeight;
        final hasHeightLimit = maxHeight.isFinite;
        final scaler = MediaQuery.textScalerOf(context);
        final direction = Directionality.of(context);

        // An ellipsis only belongs where there is a line cap to put it on.
        //
        // Setting `TextOverflow.ellipsis` with `maxLines: null` does not mean
        // "wrap freely, trim if it runs out of room" — it collapses the text to
        // a single ellipsised line. The tutorial bubbles read
        // "Start here. A good day begi…" across one line with half the bubble
        // empty underneath, and the measuring pass below could not see it
        // coming because *it* had no ellipsis: it measured two lines, decided
        // they fit, and never shrank anything.
        final ellipsis = maxLines == null ? null : '…';

        while (size > minFontSize) {
          final painter = TextPainter(
            text: TextSpan(text: data, style: style.copyWith(fontSize: size)),
            maxLines: maxLines,
            textAlign: textAlign ?? TextAlign.start,
            textDirection: direction,
            textScaler: scaler,
            ellipsis: ellipsis,
          )..layout(maxWidth: constraints.maxWidth);

          final tooManyLines = painter.didExceedMaxLines;
          final tooTall = hasHeightLimit && painter.height > maxHeight;
          if (!tooManyLines && !tooTall) break;

          size -= stepSize;
        }

        return Text(
          data,
          style: style.copyWith(fontSize: size),
          maxLines: maxLines,
          textAlign: textAlign,
          // Matches the measuring pass above. With a line cap, the ellipsis is
          // the backstop for text still too long at the floor size; without
          // one, the text wraps to as many lines as it needs and the shrinking
          // is what keeps it inside the box.
          overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
        );
      },
    );
  }
}
