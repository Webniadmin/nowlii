import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/screen/onboarding/limited_by_design_screen.dart';
import 'package:nowlii/screen/onboarding/tonights_receipt_screen.dart';
import 'package:nowlii/widget/animated_onboarding_topbar.dart';

/// The two steps added from the updated onboarding design. They were folded into
/// the numbered flow rather than appended after it, which is why the step count
/// moved from 6 to 8 — these pin that down, since a stale counter is the kind of
/// thing that silently survives a redesign.
void main() {
  Future<void> pump(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();
  }

  group('step 7 — Limited by design', () {
    testWidgets('states the daily limit and why it exists', (tester) async {
      await pump(tester, const LimitedByDesignScreen());

      expect(find.text('Limited by design'), findsOneWidget);
      expect(find.text('TWO SHORT\nCALLS A DAY.'), findsOneWidget);
      expect(find.text('YOUR TWO SPARKS'), findsOneWidget);
      expect(find.text('First spark'), findsOneWidget);
      expect(find.text('Second spark'), findsOneWidget);
      expect(find.text('5 min · +2.5 if you need it'), findsNWidgets(2));
    });

    testWidgets('is step 7 of 8', (tester) async {
      await pump(tester, const LimitedByDesignScreen());
      expect(find.text('7/$kOnboardingTotalSteps'), findsOneWidget);
      expect(find.text('7/8'), findsOneWidget);
    });
  });

  group('step 8 — the receipt preview', () {
    testWidgets('previews what comes back after a call', (tester) async {
      await pump(tester, const TonightsReceiptScreen());

      expect(find.text('After every spark'), findsOneWidget);
      expect(find.text('YOU GET YOUR\nOWN WORDS BACK.'), findsOneWidget);
      expect(find.text('Nowlii Receipt'), findsOneWidget);
      expect(find.text('Words you circled around'), findsOneWidget);
    });

    testWidgets('shows sample words, not live data', (tester) async {
      // This screen runs before the user has ever made a call, so there is
      // nothing real to show. If these ever need to come from a transcript, it
      // is the post-call summary screen that should change, not this one.
      await pump(tester, const TonightsReceiptScreen());
      expect(find.text('“should”'), findsOneWidget);
      expect(find.text('“later”'), findsOneWidget);
      expect(find.text('“honestly”'), findsOneWidget);
    });

    testWidgets('is the last step, 8 of 8', (tester) async {
      await pump(tester, const TonightsReceiptScreen());
      expect(find.text('8/$kOnboardingTotalSteps'), findsOneWidget);
      expect(
        kOnboardingTotalSteps,
        8,
        reason: 'the flow ends on this screen — the counter must not overshoot',
      );
    });
  });
}
