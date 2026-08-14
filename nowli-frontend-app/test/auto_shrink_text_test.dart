import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/widget/auto_shrink_text.dart';

/// [AutoShrinkText] gives up font size until the text fits its box.
///
/// The trap it shipped with, and the reason for the first group here: it set
/// `overflow: TextOverflow.ellipsis` on every `Text` it built, including the
/// ones with no line cap. That does not mean "wrap freely, trim if it runs
/// out" — with `maxLines: null` it collapses the text onto a single ellipsised
/// line. The tutorial bubbles read "Start here. A good day begi…" across one
/// line with half the bubble empty below it.
void main() {
  const style = TextStyle(fontSize: 20);

  Future<void> pumpIn(
    WidgetTester tester,
    Widget child, {
    Size box = const Size(240, 80),
  }) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: box.width,
                height: box.height,
                child: child,
              ),
            ),
          ),
        ),
      );

  Text builtText(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text));

  group('wrapping', () {
    testWidgets('no line cap means no ellipsis, so the text can wrap',
        (tester) async {
      await pumpIn(
        tester,
        const AutoShrinkText(
          'Start here. A good day begins with rest.',
          style: style,
        ),
      );

      expect(builtText(tester).overflow, TextOverflow.clip);
      expect(builtText(tester).maxLines, isNull);
    });

    testWidgets('it really does take more than one line', (tester) async {
      await pumpIn(
        tester,
        const AutoShrinkText(
          'Start here. A good day begins with rest.',
          style: style,
        ),
      );

      final painted = tester.renderObject<RenderBox>(find.byType(Text));
      final oneLine = builtText(tester).style!.fontSize! * 1.5;
      expect(
        painted.size.height,
        greaterThan(oneLine),
        reason: 'a sentence this long in a 240 box cannot be one line',
      );
    });

    testWidgets('a line cap brings the ellipsis back as the backstop',
        (tester) async {
      await pumpIn(
        tester,
        const AutoShrinkText(
          'Start here. A good day begins with rest.',
          maxLines: 2,
          style: style,
        ),
      );

      expect(builtText(tester).overflow, TextOverflow.ellipsis);
      expect(builtText(tester).maxLines, 2);
    });
  });

  group('shrinking', () {
    testWidgets('gives up size when the box is too short', (tester) async {
      await pumpIn(
        tester,
        const AutoShrinkText(
          'Start here. A good day begins with rest, and a little quiet.',
          style: style,
        ),
        box: const Size(200, 40),
      );

      expect(builtText(tester).style!.fontSize, lessThan(20));
    });

    testWidgets('leaves the size alone when it already fits', (tester) async {
      await pumpIn(
        tester,
        const AutoShrinkText('Hi', style: style),
        box: const Size(300, 200),
      );

      expect(builtText(tester).style!.fontSize, 20);
    });

    testWidgets('stops at the floor rather than shrinking to nothing',
        (tester) async {
      await pumpIn(
        tester,
        const AutoShrinkText(
          'A sentence far longer than any box this small could ever hold, '
          'however small the letters get.',
          style: style,
          minFontSize: 10,
        ),
        box: const Size(80, 20),
      );

      expect(builtText(tester).style!.fontSize, greaterThanOrEqualTo(10));
    });
  });
}
