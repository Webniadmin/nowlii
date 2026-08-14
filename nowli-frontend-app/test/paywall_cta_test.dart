import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/widget/paywall_cta.dart';

/// The subscribe control is a swipe rather than a tap specifically so that starting to
/// pay cannot happen by accident. These pin that down.
void main() {
  const trackWidth = 320.0;
  // width - knob(56) - padding(8 either side)
  const maxDrag = trackWidth - 56 - 16;

  Future<int> pumpSwipe(
    WidgetTester tester, {
    required double dragBy,
    bool enabled = true,
  }) async {
    var confirms = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: trackWidth,
              child: PaywallSwipeButton(
                label: 'Swipe to Subscribe',
                knobIcon: const SizedBox(width: 14, height: 14),
                enabled: enabled,
                onConfirm: () => confirms++,
              ),
            ),
          ),
        ),
      ),
    );

    final knob = find.descendant(
      of: find.byType(PaywallSwipeButton),
      matching: find.byType(GestureDetector),
    );
    await tester.drag(knob, Offset(dragBy, 0));
    await tester.pumpAndSettle();
    return confirms;
  }

  testWidgets('a full swipe subscribes', (tester) async {
    expect(await pumpSwipe(tester, dragBy: maxDrag), 1);
  });

  testWidgets('a short drag springs back and does not subscribe', (tester) async {
    // A stray touch while scrolling the paywall must not start a subscription.
    expect(await pumpSwipe(tester, dragBy: maxDrag * 0.4), 0);
  });

  testWidgets('a drag just under the threshold does not subscribe', (tester) async {
    expect(await pumpSwipe(tester, dragBy: maxDrag * 0.65), 0);
  });

  testWidgets('swiping twice only subscribes once', (tester) async {
    var confirms = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: trackWidth,
              child: PaywallSwipeButton(
                label: 'Swipe to Subscribe',
                knobIcon: const SizedBox(width: 14, height: 14),
                onConfirm: () => confirms++,
              ),
            ),
          ),
        ),
      ),
    );

    final knob = find.descendant(
      of: find.byType(PaywallSwipeButton),
      matching: find.byType(GestureDetector),
    );
    await tester.drag(knob, const Offset(maxDrag, 0));
    await tester.pumpAndSettle();
    await tester.drag(knob, const Offset(maxDrag, 0));
    await tester.pumpAndSettle();

    expect(confirms, 1);
  });

  testWidgets('a disabled control ignores the swipe', (tester) async {
    // While a purchase is already in flight.
    expect(await pumpSwipe(tester, dragBy: maxDrag, enabled: false), 0);
  });

  testWidgets('the tap button does nothing when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaywallTapButton(
            label: 'Start my free week',
            knobIcon: const SizedBox(width: 24, height: 24),
            onTap: null,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(PaywallTapButton));
    await tester.pumpAndSettle();
    expect(taps, 0);
  });
}
