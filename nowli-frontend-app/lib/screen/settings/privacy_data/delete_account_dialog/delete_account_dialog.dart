// Delete Account Confirmation Dialog
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/api/auth_service.dart';
import 'package:nowlii/api/storage.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/services/call_reminder_service.dart';
import 'package:nowlii/themes/text_styles.dart';

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key, Future<bool> Function()? deleteAccount})
      : _deleteAccount = deleteAccount;

  /// Overrides the delete call. Production never passes this — it exists so a test can hold
  /// the request open across the dialog's exit animation, which is the only window in which
  /// the bug this widget was carrying is visible at all. Left to the real `AuthService` the
  /// call resolves in a single microtask under a mocked store, the dialog is still mounted
  /// when the result lands, and the broken code passes.
  final Future<bool> Function()? _deleteAccount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5E5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                Assets.svgIcons.deleteMyAccount.path,
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Delete Your Account?',
              style: AppsTextStyles.textDefaultStyle,
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'This will erase all your reflections, call history, and AI learning data.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Nowlii will forget everything it knows about you - and personalization will reset.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            const Text(
              'Are you sure you want to continue?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: Color(0xFF1E3A8A),
                        width: 2,
                      ),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppsTextStyles.textDefaultStyle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Everything that has to outlive this dialog is captured BEFORE the
                      // pop. `context` belongs to the dialog, and once it is gone every
                      // `context.mounted` check downstream is false — see the note on
                      // _handleDeleteAccount for what that used to cost.
                      final router = GoRouter.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context, rootNavigator: true);

                      Navigator.pop(context);
                      _handleDeleteAccount(
                        navigator: navigator,
                        messenger: messenger,
                        router: router,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Delete',
                      style: AppsTextStyles.textDefaultStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Actually delete the account.
  ///
  /// This used to show "Account deletion initiated" and do nothing whatsoever — no request,
  /// no endpoint. Now it deletes on the server, clears everything stored on the device and
  /// sends the user back to the sign-in screen, because there is no longer an account for
  /// them to return to.
  ///
  /// Takes no `BuildContext` on purpose. It used to take the confirmation dialog's, which
  /// the caller had already popped — so by the time the delete request came back that
  /// context was unmounted, `if (!context.mounted) return` fired, and the blocking spinner
  /// below was never dismissed. The account really was deleted; the user just sat watching
  /// a loader forever, on the one flow both app stores require. A `NavigatorState`, a
  /// `ScaffoldMessengerState` and a `GoRouter` all live above the dialog and outlive it, so
  /// there is nothing left to go stale mid-request.
  Future<void> _handleDeleteAccount({
    required NavigatorState navigator,
    required ScaffoldMessengerState messenger,
    required GoRouter router,
  }) async {
    // Blocking spinner: this is irreversible, so the user must not be able to tap it twice
    // or wander off mid-request.
    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final deleted = await (_deleteAccount ?? AuthService().deleteAccount)();

    // Unconditional: the spinner is modal, so failing to dismiss it strands the user.
    if (navigator.mounted) navigator.pop();

    if (!deleted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete your account. Please check your connection and try again."),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    // The account is gone, so every stored token and cached profile is meaningless. This one
    // is awaited on purpose: the router's guard reads those tokens, so navigating with them
    // still in place would bounce the user straight back into an app they no longer have an
    // account for.
    try {
      await StorageService().clearAll();
    } catch (e) {
      debugPrint('⚠️ could not clear local storage after deletion: $e');
    }

    // Reminders point at calls that no longer exist — but cancelling them runs through
    // `CallReminderService.init()`, which awaits two platform channels (the timezone plugin
    // and the notifications plugin). Awaiting that put the whole exit behind a plugin: if
    // either one hangs, the user is stranded *after* their account has already been deleted,
    // which is the failure this method exists to prevent. Fired and not awaited, with its own
    // error sink so a rejection cannot surface as an unhandled async error.
    unawaited(
      CallReminderService.instance.cancelAll().catchError(
        (Object e) => debugPrint('⚠️ could not cancel reminders after deletion: $e'),
      ),
    );

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Your account and all of your data have been permanently deleted.'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
    router.go(AppRoutespath.signInScreen);
  }
}
