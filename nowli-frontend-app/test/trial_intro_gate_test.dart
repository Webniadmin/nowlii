import 'package:flutter_test/flutter_test.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/trial_intro_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

SubscriptionStatus _status({
  bool inTrial = true,
  bool hasAccess = true,
  String status = 'trial',
}) =>
    SubscriptionStatus(
      subscribed: false,
      status: status,
      currency: 'USD',
      platform: null,
      startedAt: null,
      monthIndex: 0,
      phase: '',
      currentPrice: 19.99,
      nextPrice: 14.99,
      isFree: false,
      lifetimeFree: false,
      hasAccess: hasAccess,
      inTrial: inTrial,
      trialDaysLeft: 7,
      trialEndsAt: null,
      trialDaysTotal: 7,
      trialUsed: true,
    );

/// Two callers ask this — the end of onboarding and the splash. If they disagreed, a new
/// user would see the trial offer twice or not at all.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('shows for someone whose trial has just started', () async {
    expect(await claimTrialIntro(_status()), isTrue);
  });

  test('only ever shows once, whichever caller gets there first', () async {
    expect(await claimTrialIntro(_status()), isTrue);
    expect(await claimTrialIntro(_status()), isFalse);
  });

  test('does not show to someone who is not on a trial', () async {
    // A paying subscriber does not want to be offered a free week.
    expect(
      await claimTrialIntro(_status(inTrial: false, status: 'active')),
      isFalse,
    );
  });

  test('does not show when the status could not be read', () async {
    expect(await claimTrialIntro(null), isFalse);
  });

  test('claims before showing, so force-quitting on it is not re-nagged', () async {
    await claimTrialIntro(_status());
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kSeenTrialIntroKey), isTrue);
  });
}
