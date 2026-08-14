import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/services/subscription_service.dart';

/// The reminder a lapsed user sees when they open the app.
///
/// The account is only half closed now — profile, progress and history stay readable — so
/// nothing else on screen announces that the plan has ended. Without this the app would
/// look normal until a quest failed to save, which is a worse way to learn.
///
/// It is a dialog rather than a permanent bar because it has to be noticed, and it carries
/// a plain "Not now" because a reminder with no way out is a trap, not a reminder — stores
/// reject that and it would earn the uninstall it deserves.

/// Whether this launch has already shown it. Process-level, so it fires once per app start
/// and not on every visit to the home screen.
bool _shownThisLaunch = false;

/// Resets the once-per-launch guard. For tests.
@visibleForTesting
void resetLapsedReminderForTest() => _shownThisLaunch = false;

/// Shows the reminder if the user has lapsed and has not seen it yet this launch.
///
/// Safe to call from any screen's first frame; it no-ops for everyone who still has access.
Future<void> maybeShowLapsedReminder(BuildContext context) async {
  if (_shownThisLaunch) return;

  // Defaults to true when nothing is cached, so a fresh install or a failed status call
  // never accuses a paying user of having lapsed.
  final hasAccess = await SubscriptionService.cachedHasAccess();
  if (hasAccess) return;
  if (!context.mounted) return;

  _shownThisLaunch = true;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => const _LapsedReminderDialog(),
  );
}

class _LapsedReminderDialog extends StatelessWidget {
  const _LapsedReminderDialog();

  static const Color _ink = Color(0xFF011F54);
  static const Color _orange = Color(0xFFFF8F26);
  static const Color _muted = Color(0xFF4C586E);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFFEF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR PLAN HAS ENDED',
              style: GoogleFonts.workSans(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            // Says what still works before what does not — the account is paused, not gone.
            Text(
              'Your profile, your progress and everything you have already done are still '
              'here. New quests and calls with Fuzzy are paused until you renew.',
              style: GoogleFonts.workSans(
                color: _muted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutespath.nowliProSubscription);
                },
                style: TextButton.styleFrom(
                  backgroundColor: _orange,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Renew',
                  style: GoogleFonts.workSans(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Not now',
                  style: GoogleFonts.workSans(
                    color: _muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
