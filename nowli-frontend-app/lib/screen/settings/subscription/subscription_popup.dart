import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/subscription_service.dart';

/// The free-trial intro screen — `PopupProTrial_StartAfterOnboarding` in the design.
///
/// Shown once automatically when a new user's 7-day trial starts (from the splash,
/// gated on `seen_trial_intro`), and reachable any time from Settings.
///
/// Deliberately **dark**: client-approved, and it matches the tone of the active-call
/// screen. Equally deliberately, the month-by-month pricing breakdown is *not* here —
/// per the design notes that detail belongs on the Pro/paywall screen only, so
/// [BillingExplainer] stays on `nowli_pro_subscription.dart` and this screen carries
/// just the Day 0 / Day 5 / Day 6 timeline.
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
  bool _starting = false;

  static const Color _bg = Color(0xFF011F54);
  static const Color _card = Color(0xFF0C2E6E);
  static const Color _ink = Color(0xFFFFFCF1);
  static const Color _inkMuted = Color(0xFFA8BEE0);
  static const Color _accent = Color(0xFF4A3AFF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _subService.getPlan(),
      _subService.getMyStatus(),
    ]);
    if (!mounted) return;
    setState(() {
      _plan = results[0] as SubscriptionPlan?;
      _status = results[1] as SubscriptionStatus?;
    });
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
  /// used-up trial does not pretend to offer a free week.
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
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Assets.svgIcons.proCrossIcon.svg(width: 34, height: 34),
                onPressed: _dismiss,
              ),
            ),

            // Everything above the CTA scrolls in its own region. On a small
            // screen the content is taller than the viewport, and without this
            // split the primary action ends up below the fold.
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/svg_images/popup_pro_icon.png',
                        width: 190,
                        height: 190,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Seven days. On us.',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 38,
                        fontFamily: 'Wosker',
                        fontWeight: FontWeight.w400,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No card, no reminder emails, no “are you sure”. If it '
                      'isn\'t for you, just stop opening it.',
                      style: GoogleFonts.workSans(
                        color: _inkMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _FeatureCard(
                      iconPath: Assets.svgIcons.dailyTalksWithFuzzy.path,
                      title: 'Two short calls a day',
                      subtitle: '5 min each · +2.5 if you need it',
                    ),
                    const SizedBox(height: 12),
                    _FeatureCard(
                      iconPath: Assets.svgIcons.focusSessions.path,
                      title: 'A receipt after each one',
                      subtitle: 'Your words, kept in the app',
                    ),
                    const SizedBox(height: 12),
                    _FeatureCard(
                      iconPath: Assets.svgIcons.progressInsights.path,
                      title: 'Designed to be outgrown',
                      subtitle: '$_monthlyPrice → \$0 on the calendar',
                    ),

                    const SizedBox(height: 28),
                    Text(
                      'How it works?',
                      style: GoogleFonts.workSans(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _TimelineItem(
                      when: 'Now',
                      title: 'Full Trial Access',
                      description:
                          'Get full access to all features. No card required '
                          'during trial.',
                    ),
                    const _TimelineItem(
                      when: 'Day 5',
                      title: 'Trial Status Update',
                      description: 'Get reminder about the free trial ending.',
                    ),
                    const _TimelineItem(
                      when: 'Day 6',
                      title: 'Your Call to Continue',
                      description:
                          "We'll remind you to continue with Pro access if "
                          'you\'d like.',
                      isLast: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Fixed action — never scrolls out of reach.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton(
                      onPressed: _starting ? null : _startTrial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        disabledBackgroundColor:
                            _accent.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _ctaLabel,
                        style: GoogleFonts.workSans(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Day 8 is $_monthlyPrice/mo. You\'ll see it coming.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: _inkMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

class _FeatureCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: _SubscriptionPageState._card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Image.asset(iconPath, width: 44, height: 44),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.workSans(
                    color: _SubscriptionPageState._inkMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

class _TimelineItem extends StatelessWidget {
  final String when;
  final String title;
  final String description;
  final bool isLast;

  const _TimelineItem({
    required this.when,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: _SubscriptionPageState._accent,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _SubscriptionPageState._accent
                        .withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    when,
                    style: GoogleFonts.workSans(
                      color: _SubscriptionPageState._accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: GoogleFonts.workSans(
                      color: _SubscriptionPageState._ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.workSans(
                      color: _SubscriptionPageState._inkMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
