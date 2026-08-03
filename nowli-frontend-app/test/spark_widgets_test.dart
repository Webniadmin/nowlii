import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/screen/home/sparks/out_of_sparks_card.dart';
import 'package:nowlii/screen/home/swipe_to_talk/swipe_button_widget.dart';
import 'package:nowlii/services/spark_state.dart';

/// The two screens the user actually sees once the day's sparks are gone.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: child)),
      );

  group('out-of-sparks card', () {
    testWidgets('closes the day out rather than reporting a failure',
        (tester) async {
      await pump(
        tester,
        const OutOfSparksCard(sparks: SparkState(limit: 2, remaining: 0)),
      );

      expect(find.text('THAT\'S\nENOUGH\nFOR TODAY.'), findsOneWidget);
      expect(find.text('BOTH SPARKS USED'), findsOneWidget);
      expect(
        find.text(
          'You said it. You picked the next step. Nowlii will be back tomorrow.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the eyebrow follows the real daily limit', (tester) async {
      await pump(
        tester,
        const OutOfSparksCard(sparks: SparkState(limit: 3, remaining: 0)),
      );

      expect(find.text('ALL SPARKS USED'), findsOneWidget);
      expect(find.text('BOTH SPARKS USED'), findsNothing);
    });
  });

  group('swipe button', () {
    testWidgets('invites a call while sparks remain', (tester) async {
      await pump(tester, SwipeButtonWidget(onSwipe: () {}));

      expect(find.text('Swipe to start a spark'), findsOneWidget);
      expect(find.text('See you tomorrow'), findsNothing);
    });

    testWidgets('stops inviting one once they are spent', (tester) async {
      // The swipe must be gone, not merely greyed out: swiping would only reach the
      // backend's refusal, so leaving a draggable knob invites people to keep trying.
      await pump(tester, SwipeButtonWidget(onSwipe: () {}, spent: true));

      expect(find.text('See you tomorrow'), findsOneWidget);
      expect(find.text('Swipe to start a spark'), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
