import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/screen/onboarding/profile_setup/name_page.dart';

/// The onboarding name field had no validation at all — an empty name sailed
/// through and was posted to the profile. The design spec closes that: at least
/// one character, at most 30, letters/spaces/hyphens only.
///
/// These drive the real widget rather than a copy of the rules, so they fail if
/// the formatters are dropped from the TextField.
void main() {
  Future<void> pumpNamePage(
    WidgetTester tester, {
    String initialName = '',
    VoidCallback? onContinue,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NamePage(
            initialName: initialName,
            onNameChanged: (_) {},
            onContinue: onContinue ?? () {},
          ),
        ),
      ),
    );
  }

  ElevatedButton continueButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  group('Continue is gated on having a name', () {
    testWidgets('starts disabled when nothing has been typed', (tester) async {
      await pumpNamePage(tester);
      expect(continueButton(tester).onPressed, isNull);
    });

    testWidgets('enables once a name is entered', (tester) async {
      await pumpNamePage(tester);
      await tester.enterText(find.byType(TextField), 'Julie');
      await tester.pump();
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('whitespace alone does not count as a name', (tester) async {
      await pumpNamePage(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(continueButton(tester).onPressed, isNull);
    });

    testWidgets('tapping Continue advances the flow', (tester) async {
      var advanced = false;
      await pumpNamePage(tester, onContinue: () => advanced = true);
      await tester.enterText(find.byType(TextField), 'Julie');
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      expect(advanced, isTrue);
    });
  });

  group('what the field accepts', () {
    Future<String> typed(WidgetTester tester, String input) async {
      await pumpNamePage(tester);
      await tester.enterText(find.byType(TextField), input);
      await tester.pump();
      return tester.widget<TextField>(find.byType(TextField)).controller!.text;
    }

    testWidgets('keeps letters, spaces and hyphens', (tester) async {
      expect(await typed(tester, 'Mary-Jane Watson'), 'Mary-Jane Watson');
    });

    testWidgets('rejects digits', (tester) async {
      expect(await typed(tester, 'Julie123'), 'Julie');
    });

    testWidgets('rejects symbols', (tester) async {
      expect(await typed(tester, r'Julie@#$!'), 'Julie');
    });

    testWidgets('keeps accented and non-Latin letters', (tester) async {
      // Unicode-aware on purpose — the app ships Español, and an ASCII-only
      // filter would quietly eat half of a real name.
      expect(await typed(tester, 'José Đorđe'), 'José Đorđe');
    });

    testWidgets('stops at 30 characters', (tester) async {
      final long = 'a' * 40;
      expect((await typed(tester, long)).length, 30);
    });
  });
}
