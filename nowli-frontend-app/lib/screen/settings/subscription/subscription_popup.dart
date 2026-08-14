import 'package:nowlii/widget/nowlii_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/call_duration.dart';
import 'package:nowlii/services/number_words.dart';
import 'package:nowlii/services/subscription_service.dart';
import 'package:nowlii/services/voice_call_service.dart';
import 'package:nowlii/widget/paywall_cta.dart';

/// The free-trial intro screen — `PopupProTrial_StartAfterOnboarding` in the design.
///
/// Shown once automatically when a new user's 7-day trial starts (from the splash,
/// gated on `seen_trial_intro`), and reachable any time from Settings.
///
/// Deliberately **dark**: client-approved, and it matches the tone of the active-call
/// screen. Equally deliberately, the month-by-month pricing breakdown is *not* here —
/// per the design notes that detail belongs on the Pro/paywall screen only, so this
/// screen carries just the Now / Day 5 / Day 6 timeline.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final ScrollController _scrollController = ScrollController();
  final SubscriptionService _subService = SubscriptionService();
  SubscriptionPlan? _plan;
  SubscriptionStatus? _status;
  VoiceCallQuota? _quota;
  bool _starting = false;

  static const Color _bg = Color(0xFF011F54);
  static const Color _ink = Color(0xFFFFFEF8);
  static const Color _inkMuted = Color(0xB3FFFEF8); // 70% — body copy
  static const Color _cardFill = Color(0x14FFFEF8); // 8% — feature rows
  static const Color _stepFill = Color(0xFF153161);
  static const Color _stepBorder = Color(0xFF325CA5);
  static const Color _stepBody = Color(0xFFA1A8B8);
  static const Color _featureSub = Color(0xFFC8CBD2);
  static const Color _caption = Color(0xFFADB2BC);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _subService.getPlan(),
      _subService.getMyStatus(),
      // The daily allowance is an env var on the backend, and the home screen already
      // reads it. Quoting "two calls a day" here from memory would contradict it the day
      // anyone changes the setting.
      VoiceCallService().getQuota(),
    ]);
    if (!mounted) return;
    setState(() {
      _plan = results[0] as SubscriptionPlan?;
      _status = results[1] as SubscriptionStatus?;
      _quota = results[2] as VoiceCallQuota?;
    });
  }

  /// Calls per day, as the backend has it. Falls back to the published figure so the copy
  /// still reads as a sentence if the quota call fails; unlimited test accounts report -1,
  /// which must never reach the copy.
  int get _callsPerDay {
    final limit = _quota?.limit ?? 0;
    return limit > 0 ? limit : 2;
  }

  /// Trial length in days, as the backend has it.
  int get _trialDays {
    final total = _status?.trialDaysTotal ?? 0;
    return total > 0 ? total : 7;
  }

  /// Starts (or confirms) the trial, then enters the app. The backend grants the
  /// trial on first contact and never re-grants it, so tapping twice is harmless.
  Future<void> _startTrial() async {
    setState(() => _starting = true);
    final status = await _subService.startTrial();
    if (!mounted) return;
    setState(() {
      _starting = false;
      if (status != null) _status = status;
    });

    if (status == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start your free trial. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (status.hasAccess) {
      context.go(AppRoutespath.homeScreen);
    } else {
      // Trial already used up — send them to the paywall instead of a dead end.
      context.go(AppRoutespath.nowliProSubscription);
    }
  }

  /// Label reflects reality: a running trial says how many days are left, and a
  /// used-up trial does not pretend to offer a free week. The screen is reachable from
  /// Settings at any time, so the design's fixed "Start my free week" would be a false
  /// offer to most of the people who open it.
  String get _ctaLabel {
    final s = _status;
    if (_starting) return 'Just a moment…';
    if (s == null) return 'Start my free week';
    if (s.inTrial) return 'Continue — ${s.trialDaysLeft} days left';
    if (s.hasAccess) return 'Continue';
    if (s.trialUsed) return 'See Nowlii Pro';
    return 'Start my free week';
  }

  /// Price of the first paid month, i.e. what the user is quoted for day 8.
  ///
  /// The plan steps down over the year, so this is the *first* phase, not a flat
  /// monthly rate. Falls back to the published figure when the plan call has not
  /// landed yet — the caption must never render as "null".
  String get _monthlyPrice {
    final phases = _plan?.phases;
    if (phases == null || phases.isEmpty) return '\$19.99';
    return '\$${phases.first.price.toStringAsFixed(2)}';
  }

  void _dismiss() {
    // Reachable both as a once-only popup and from Settings, so pop when there is
    // something to pop back to and fall through to home when there isn't.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutespath.homeScreen);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 20),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0x1FFFFEF8),
                      shape: BoxShape.circle,
                    ),
                    child: Assets.svgIcons.paywallClose.svg(width: 15, height: 15),
                  ),
                ),
              ),
            ),

            // Everything above the CTA scrolls in its own region. On a small
            // screen the content is taller than the viewport, and without this
            // split the primary action ends up below the fold.
            //
            // The fade is what tells you so. The region's edge fell wherever it
            // fell — on a 320dp screen that was through the middle of "How it
            // works?", leaving a row of half-height letters above the button
            // that read as broken rather than as "there is more below".
            Expanded(
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.94, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Transform.rotate(
                        angle: 1.07 * 3.1415926535 / 180,
                        child: const NowliiAvatar(size: 80),
                      ),
                    ),
                    const SizedBox(height: 23.7),
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          // The trial length is a backend value (TRIAL_DAYS, reported as
                          // trial_days_total) — spelling "SEVEN" into the headline made it
                          // a lie the moment anyone changed it.
                          '${numberWord(_trialDays).toUpperCase()} DAYS.\nON US.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Wosker',
                            color: _ink,
                            fontSize: 52,
                            fontWeight: FontWeight.w400,
                            height: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13.2),
                    Text(
                      'No card, no reminder emails, no “are you sure”. If it '
                      'isn\'t for you, just stop opening it.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: _inkMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _FeatureRow(
                      icon: Assets.svgIcons.paywallMic.svg(width: 22, height: 21),
                      iconBackground: const Color(0xFFA0E871),
                      title: countedPhrase(
                        _callsPerDay,
                        'short call a day',
                        'short calls a day',
                      ),
                      subtitle: '$callMinutesLabel min each · '
                          '+$extensionMinutesLabel if you need it',
                    ),
                    const SizedBox(height: 8),
                    _FeatureRow(
                      icon:
                          Assets.svgIcons.paywallReceipt.svg(width: 21, height: 21),
                      iconBackground: const Color(0xFFFF8F26),
                      title: 'A receipt after each one',
                      subtitle: 'Your words, kept in the app',
                    ),
                    const SizedBox(height: 8),
                    _FeatureRow(
                      icon: Assets.svgIcons.paywallChart.svg(width: 21, height: 21),
                      iconBackground: const Color(0xFF4542EB),
                      title: 'Designed to be outgrown',
                      subtitle: '$_monthlyPrice → \$0 on the calendar',
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'How it works?',
                      style: GoogleFonts.workSans(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _TimelineStep(
                      when: 'Now',
                      accent: Color(0xFFA0E871),
                      title: 'Full Trial Access',
                      description:
                          'Get full access to all features. No card required '
                          'during trial.',
                    ),
                    const SizedBox(height: 8),
                    const _TimelineStep(
                      when: 'Day 5',
                      accent: Color(0xFFFF8F26),
                      title: 'Trial Status Update',
                      description: 'Get reminder about the free trial ending.',
                    ),
                    const SizedBox(height: 8),
                    const _TimelineStep(
                      when: 'Day 6',
                      accent: Color(0xFFA9A8F6),
                      title: 'Your Call to Continue',
                      description:
                          "We'll remind you to continue with Pro access if "
                          'you\'d like.',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              ),
            ),

            // Fixed action — never scrolls out of reach.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
              child: Column(
                children: [
                  PaywallTapButton(
                    label: _ctaLabel,
                    knobIcon: Assets.svgIcons.paywallSparkle
                        .svg(width: 24, height: 24),
                    onTap: _starting ? null : _startTrial,
                  ),
                  const SizedBox(height: 13),
                  Text(
                    // The first paid day is the day after the trial ends, so it moves with
                    // the trial length rather than being fixed at 8.
                    'Day ${_trialDays + 1} is $_monthlyPrice/mo. '
                    'You\'ll see it coming.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: _caption,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the three "what you get" rows.
class _FeatureRow extends StatelessWidget {
  final Widget icon;
  final Color iconBackground;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: ShapeDecoration(
        color: _SubscriptionPageState._cardFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    color: _SubscriptionPageState._ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.workSans(
                    color: _SubscriptionPageState._featureSub,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One card in the "How it works?" list. The dot and the eyebrow share a colour, which is
/// what distinguishes the three moments at a glance.
class _TimelineStep extends StatelessWidget {
  final String when;
  final Color accent;
  final String title;
  final String description;

  const _TimelineStep({
    required this.when,
    required this.accent,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: _SubscriptionPageState._stepFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _SubscriptionPageState._stepBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  when.toUpperCase(),
                  style: GoogleFonts.workSans(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.workSans(
                    color: _SubscriptionPageState._stepBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
