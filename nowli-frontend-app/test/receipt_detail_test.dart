import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/models/call_summary_history.dart';
import 'package:nowlii/screen/receipts/receipt_detail_screen.dart';

/// A receipt only ever shows what the call actually produced. A short call legitimately
/// yields almost nothing, and the screen has to stay honest about that rather than
/// printing empty frames.
void main() {
  CallSummaryHistoryItem receipt({
    List<String> words = const ['should', 'later', 'stuck'],
    String nextStep = 'Open the file.',
    String tinyQuestion = "What's the first click?",
    String note = '',
  }) =>
      CallSummaryHistoryItem(
        callId: 1,
        startedAt: DateTime(2026, 7, 27, 20, 15),
        durationSeconds: 298,
        nextStep: nextStep,
        wordsCircled: words,
        tinyQuestion: tinyQuestion,
        note: note,
      );

  Future<void> pump(WidgetTester tester, CallSummaryHistoryItem item) =>
      tester.pumpWidget(
        MaterialApp(home: ReceiptDetailScreen(receipt: item, number: 14)),
      );

  testWidgets('prints the serial number, words, step and question', (tester) async {
    await pump(tester, receipt());

    expect(find.text('RECEIPT NO. 014'), findsOneWidget);
    expect(find.text('“Should”,\n“Later”,\n“Stuck”.'), findsOneWidget);
    expect(find.text('“Open the file.”'), findsOneWidget);
    expect(find.text("What's the first click?"), findsOneWidget);
  });

  testWidgets('hides the tiny question when the model had none', (tester) async {
    await pump(tester, receipt(tinyQuestion: ''));

    expect(find.text('TINY QUESTION'), findsNothing);
    // The rest of the receipt is unaffected.
    expect(find.text('“Open the file.”'), findsOneWidget);
  });

  testWidgets('hides the words card when the call was too short', (tester) async {
    await pump(tester, receipt(words: const []));

    expect(find.text('WORDS YOU CIRCLED AROUND'), findsNothing);
  });

  testWidgets('says so plainly when a call produced nothing at all', (tester) async {
    await pump(
      tester,
      receipt(words: const [], nextStep: '', tinyQuestion: ''),
    );

    expect(find.text('Not every call leaves a pattern behind.'), findsOneWidget);
  });

  group('the note', () {
    testWidgets('offers to add one when there is none', (tester) async {
      await pump(tester, receipt());

      expect(find.text('Add a note'), findsOneWidget);
      expect(find.text('YOUR NOTE'), findsNothing);
    });

    testWidgets('is shown back and offers an edit once written', (tester) async {
      await pump(tester, receipt(note: 'Felt lighter after this one.'));

      expect(find.text('YOUR NOTE'), findsOneWidget);
      expect(find.text('Felt lighter after this one.'), findsOneWidget);
      expect(find.text('Edit note'), findsOneWidget);
      expect(find.text('Add a note'), findsNothing);
    });
  });
}
