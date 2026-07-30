// Smoke test for the app shell.
//
// This file used to be the untouched Flutter counter template, asserting a "+" button and a
// counter that NOWLII has never had — so it failed from the initial commit and made
// `flutter test` permanently red. Replaced with something that actually holds.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowlii/main.dart';

void main() {
  setUp(() {
    // The splash screen reads the stored token; without this the plugin channel throws.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('the app boots into its router', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(); // first frame

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The splash holds a 5-second timer and a repeating animation. Let the timer fire and
    // then tear the tree down, or the test ends with both still live and fails on that
    // rather than on anything real. pumpAndSettle is not an option — the animation repeats
    // forever, so it would never return.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
