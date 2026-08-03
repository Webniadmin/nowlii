import 'package:nowlii/models/subscription_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key recording that the "Seven days. On us." screen has been shown.
const String kSeenTrialIntroKey = 'seen_trial_intro';

/// Whether to show the trial intro now — and, if so, records that it has been shown.
///
/// Two places need this answer and they must agree: the end of onboarding (a brand-new
/// account, which is where the design says it belongs) and the splash (an existing install
/// whose trial has just been granted, or someone who closed the app before reaching it).
/// Written once, because the two drifting apart shows the screen twice or never.
///
/// The claim is deliberately made *before* navigating rather than when the screen is
/// dismissed: a user who force-quits on it has still seen the offer, and re-showing it
/// every launch until they tap through would be nagging.
Future<bool> claimTrialIntro(SubscriptionStatus? status) async {
  // Not on a trial — either they never started one, or they already pay. Neither wants
  // to be told about a free week.
  if (status == null || !status.inTrial) return false;

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(kSeenTrialIntroKey) ?? false) return false;

  await prefs.setBool(kSeenTrialIntroKey, true);
  return true;
}
