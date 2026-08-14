import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/core/responsive/responsive_text.dart';
import 'package:nowlii/screen/onboarding/limited_by_design_screen.dart';
import 'package:nowlii/screen/onboarding/nowli_how_to_use.dart';
import 'package:nowlii/screen/onboarding/onboarding_features/onboarding_features.dart';
import 'package:nowlii/screen/onboarding/onboarding_flow_file/onboarding_flow.dart';
import 'package:nowlii/screen/onboarding/profile_setup/gender_page.dart';
import 'package:nowlii/screen/onboarding/tonights_receipt_screen.dart';

/// The 320dp sweep, for the screens a device cannot be driven to.
///
/// Most of the app was checked by hand on the emulator at exactly 320.0dp
/// (`wm size 840x1867` at density 420 — 840 / 2.625). Onboarding is the gap:
/// it only runs once, on an account that has just been created, so reaching it
/// again means a brand-new user and an email OTP. These screens pump
/// standalone, so the width can be checked here instead — and unlike a manual
/// pass, it keeps being checked.
///
/// What is asserted is a RenderFlex overflow. Overflow is reported through
/// `FlutterError.onError` at paint time rather than thrown, so it is invisible
/// to an ordinary `pumpWidget` — which is exactly why it went unnoticed on
/// these screens for so long. Errors that are *not* overflows are collected
/// too and reported separately, rather than forwarded to the framework: the
/// framework's own handler records a pending exception that then trips an
/// assertion on the next `expect`, which reads as a failure in the harness
/// instead of naming the screen that broke.
///
/// **Read a failure here as a suspicion, and a pass as strong evidence.** The
/// test binding has neither Work Sans (`google_fonts` cannot fetch in a test)
/// nor the bundled `Wosker`, so every string is measured in the fallback test
/// font, whose glyphs are square em boxes — appreciably wider than what ships.
/// The measurement is therefore a conservative upper bound: anything that fits
/// here fits on a device, while a failure means the row has no slack left and
/// wants a look, not necessarily that it breaks today.
void main() {
  // The emulator profile the manual sweep uses: 840 x 1867 at 2.625x.
  const narrowPhone = Size(320, 711);

  /// Mirrors `main.dart`'s harness: ScreenUtil at the 375x812 design size, and
  /// `ResponsiveText` on MaterialApp's own builder. Without the latter the type
  /// would render at full size on a 320 screen, which is not what ships — the
  /// test would then fail on overflows that the shipped app does not have.
  Future<List<String>> overflowsOn(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = narrowPhone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflows = <String>[];
    final others = <String>[];
    final reportToFramework = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      (message.contains('overflowed') ? overflows : others)
          .add(message.split('\n').first);
    };

    await tester.pumpWidget(
      ScreenUtilInit(
        minTextAdapt: true,
        splitScreenMode: true,
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => ResponsiveText(child: child!),
          home: screen,
        ),
      ),
    );
    // Two frames: ScreenUtilInit builds its child on the second one.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Back to normal before the first expect — see the note above.
    FlutterError.onError = reportToFramework;

    // A screen that silently failed to build would report no overflows and
    // pass. Insist that something was actually laid out, and that nothing else
    // went wrong on the way.
    expect(
      find.byType(Scaffold),
      findsWidgets,
      reason: 'the screen did not render, so the width was never tested',
    );
    expect(others, isEmpty, reason: 'the screen raised a non-layout error');

    return overflows;
  }

  group('onboarding at 320dp', () {
    testWidgets('step 1-2 — name and gender', (tester) async {
      expect(await overflowsOn(tester, const OnboardingFlow()), isEmpty);
    });

    testWidgets('the gender page on its own', (tester) async {
      // Reached through a PageView above, which only lays out the visible page.
      expect(
        await overflowsOn(
          tester,
          GenderPage(
            // A long name is the realistic worst case: the heading interpolates
            // it, and the field accepts more than fits.
            userName: 'Konstantina',
            selectedGender: '',
            onGenderSelected: (_) {},
          ),
        ),
        isEmpty,
      );
    });

    testWidgets('how to use', (tester) async {
      expect(await overflowsOn(tester, const NowliHowToUse()), isEmpty);
    });

    testWidgets('the feature tour', (tester) async {
      expect(await overflowsOn(tester, const OnboardingFeatures()), isEmpty);
    });

    testWidgets('step 7 — limited by design', (tester) async {
      expect(await overflowsOn(tester, const LimitedByDesignScreen()), isEmpty);
    });

    testWidgets('step 8 — tonight\'s receipt', (tester) async {
      expect(await overflowsOn(tester, const TonightsReceiptScreen()), isEmpty);
    });
  });
}
