// Leaving the app has to actually take you somewhere.
//
// Both exits — "Log out" and "Delete My Account" — are confirmed in a dialog, and both used
// to finish their work with the *dialog's* `BuildContext`. Popping a dialog unmounts that
// context once its exit animation ends, which happens well inside the network round-trip, so
// every `context.mounted` guard downstream was false by the time it was read:
//
//   * Log out cleared the session and never navigated. You stayed on Settings, which read as
//     the button having failed. (The next launch did land on sign-in, which is why it was
//     only ever reported as a UI oddity.)
//   * Delete My Account never dismissed its blocking spinner. The account really was gone,
//     but the screen span forever — on the one flow Google Play and Apple both require.
//
// Neither threw. `context.mounted` returning false is the silent, correct-looking branch, so
// nothing appeared in the log and no test noticed.
//
// ORDERING IS THE WHOLE TEST. On a phone the request outlives the ~150ms exit animation, so
// the context is dead when the result lands. In a widget test the opposite happens by
// default: a mocked store resolves in one microtask, the dialog is still up, and the broken
// code passes. A first draft of this file did exactly that — it went green against the bug.
// So the delete call is held open by a Completer here, released only after pumpAndSettle has
// run the dialog all the way out. Verified to fail against the pre-fix widget.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/screen/settings/privacy_data/delete_account_dialog/delete_account_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// A router with somewhere to land, and a button that opens the real dialog.
  Widget harness({required Future<bool> Function() deleteAccount}) {
    final router = GoRouter(
      initialLocation: '/privacy',
      routes: [
        GoRoute(
          path: '/privacy',
          builder: (context, state) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => DeleteAccountDialog(deleteAccount: deleteAccount),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/signInScreen',
          builder: (context, state) => const Scaffold(body: Text('signed out')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  /// Run the frames out after the request answers.
  ///
  /// Several frames, not one: dismissing the spinner, wiping local storage, cancelling the
  /// reminders and finally routing are each their own async hop. `pumpAndSettle` cannot be
  /// used while the spinner is still up — its animation never ends and settling times out.
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Opens the dialog, confirms, and runs the confirmation all the way off the screen —
  /// leaving the delete request still in flight, which is the state that used to break.
  ///
  /// Explicit pumps, not `pumpAndSettle`: the spinner is a `CircularProgressIndicator`, whose
  /// animation never ends, so settling while it is on screen times out rather than failing on
  /// anything meaningful.
  Future<void> confirmAndLetTheDialogGo(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Delete Your Account?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump(); // pop starts, spinner goes up
    await tester.pump(const Duration(milliseconds: 500)); // exit animation runs out

    // The confirmation is fully gone: its element is unmounted and its context is dead.
    expect(find.text('Delete Your Account?'), findsNothing);
    // The blocking spinner is up and the request has not answered yet.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  testWidgets('a failed deletion never strands the user under the spinner', (tester) async {
    final request = Completer<bool>();
    await tester.pumpWidget(harness(deleteAccount: () => request.future));

    await confirmAndLetTheDialogGo(tester);

    request.complete(false); // the server refused
    await drain(tester);

    // This is the assertion that fails against the old code: the modal barrier stayed up
    // with no way past it.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining("Couldn't delete your account"), findsOneWidget);

    // Nothing was deleted, so signing them out would misreport what happened.
    expect(find.text('signed out'), findsNothing);
  });

  testWidgets('a successful deletion takes the user to sign-in', (tester) async {
    final request = Completer<bool>();
    await tester.pumpWidget(harness(deleteAccount: () => request.future));

    await confirmAndLetTheDialogGo(tester);

    request.complete(true); // the account is gone
    await drain(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // There is no account to go back to, so the user must not be left inside the app.
    expect(find.text('signed out'), findsOneWidget);
  });
}
