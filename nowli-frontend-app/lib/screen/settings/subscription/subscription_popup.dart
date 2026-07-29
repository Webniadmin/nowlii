import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';
import 'package:nowlii/models/subscription_model.dart';
import 'package:nowlii/services/subscription_service.dart';
import 'package:nowlii/widget/billing_explainer.dart';

/// The free-trial intro / billing explainer screen.
///
/// Shown once automatically when a new user's 7-day trial starts (from the splash), and
/// reachable any time from Settings. The "How billing works" section is shared with the
/// Pro screen via [BillingExplainer].
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {});
    });
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

  /// "Let's begin 7 days free" — starts (or confirms) the trial, then enters the app.
  /// The backend grants the trial on first contact and never re-grants it, so tapping
  /// this twice is harmless.
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

  /// Button label reflects reality: a running trial says how many days are left, and a
  /// used-up trial doesn't pretend to offer a free week.
  String get _ctaLabel {
    final s = _status;
    if (_starting) return 'Just a moment…';
    if (s == null) return "Let's begin 7 days free";
    if (s.inTrial) return 'Continue — ${s.trialDaysLeft} days left';
    if (s.hasAccess) return 'Continue';
    if (s.trialUsed) return 'See Nowlii Pro';
    return "Let's begin ${s.trialDaysTotal} days free";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background color
          Container(
            width: screenWidth,
            height: screenHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Subscription Popup.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Top image (one.png) — moves up as you scroll down
          // Positioned(
          //   top: -_scrollOffset * 0.4,
          //   right: 0,
          //   child: Opacity(
          //     opacity: (1 - (_scrollOffset / 400)).clamp(0.0, 1.0),
          //     child: Image.asset(
          //       'assets/images/one.png',
          //       width: screenWidth * 0.55,
          //       fit: BoxFit.contain,
          //     ),
          //   ),
          // ),

          // // Bottom image (two.png) — moves down / appears as you scroll down
          // Positioned(
          //   bottom:
          //       -(_scrollOffset * 0.3) +
          //       (_scrollOffset > 200 ? (_scrollOffset - 200) * 0.5 : 0),
          //   left: 0,
          //   child: Opacity(
          //     opacity: (_scrollOffset / 500).clamp(0.0, 1.0),
          //     child: Image.asset(
          //       'assets/images/two.png',
          //       width: screenWidth * 0.6,
          //       fit: BoxFit.contain,
          //     ),
          //   ),
          // ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Close button
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Assets.svgIcons.proCrossIcon.svg(
                            width: 38,
                            height: 38,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      // Logo
                      Center(
                        child: Image.asset(
                          "assets/svg_images/popup_pro_icon.png",
                          width: 240,
                          height: 240,
                        ),
                      ),

                      SizedBox(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'START YOUR ',
                                style: const TextStyle(
                                  fontFamily: 'Wosker',
                                  color: Color(0xFF011F54),
                                  fontSize: 40,
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text: 'FREE NOWLII PRO WEEK 🌱',
                                style: const TextStyle(
                                  fontFamily: 'Wosker',
                                  color: Color(0xFF4542EB),
                                  fontSize: 40,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Center(
                        child: Text(
                          'Enjoy 30 days of full access. Your journey\nto focus and consistency begins today.',
                          textAlign: TextAlign.center,
                          style: AppsTextStyles.passwordUpdateSub,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Container(
                        width: 361,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xffB8FFAB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xff4556F6),
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            /// Orange Badge
                            Positioned(
                              top: -38,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffFF8A00),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'save 26%',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.workSans(
                                    color: const Color(0xFF011F54),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 0.8,
                                  ),
                                ),
                              ),
                            ),

                            /// Main Row Content
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// LEFT SIDE
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Yearly',
                                      style: GoogleFonts.workSans(
                                        color: const Color(0xFF011F54),
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$25.99',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.workSans(
                                        color: const Color(0xFF011F54),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        height: 0.8,
                                      ),
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                /// RIGHT SIDE
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "7 days free",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.workSans(
                                        color: const Color(0xFF4542EB),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text.rich(
                                      TextSpan(
                                        text: "then ",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "\$19.99",
                                            style: GoogleFonts.workSans(
                                              color: const Color(0xFF011F54),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              height: 0.8,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: " / mo",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      Container(
                        width: 361,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left: Monthly
                            Flexible(
                              child: Text(
                                'Monthly',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF011F54),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right: 7 days free and price
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "7 days free",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.workSans(
                                    color: const Color(0xFF4542EB),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'then \$19.99/mo',
                                  style: GoogleFonts.workSans(
                                    color: const Color(0xFF011F54),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Features List
                      Container(
                        decoration: BoxDecoration(
                          color: AppColorsApps.softCream,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFAFFBA3),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "You'll get full access to",
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF011F54),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 15),

                              _buildFeatureItem(
                                iconPath: Assets.svgIcons.focusSessions.path,
                                title: 'Focus sessions',
                              ),
                              _buildFeatureItem(
                                iconPath:
                                    Assets.svgIcons.dailyTalksWithFuzzy.path,
                                title: 'Daily talks with Fuzzy',
                              ),
                              _buildFeatureItem(
                                iconPath: Assets.svgIcons.progressInsights.path,
                                title: 'Progress insights',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // How it works section
                      Text(
                        'How it works?',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 15),

                      _buildTimelineItem(
                        day: 'Now',
                        description:
                            'Get full access to all features. No card required during trial.',
                        color: Colors.orange,
                      ),
                      _buildTimelineItem(
                        day: 'Day 5',
                        description:
                            'Get reminder about the free trial ending.',
                        color: const Color(0xFF5C6BC0),
                      ),
                      _buildTimelineItem(
                        day: 'Day 6',
                        description:
                            'We\'ll remind you to continue with Pro access if you\'d like.',
                        color: const Color(0xFF8BC34A),
                      ),
                      const SizedBox(height: 30),

                      // How billing works (philosophy + decreasing-price phases).
                      // Shared with the Pro screen — one source of pricing copy.
                      BillingExplainer(plan: _plan),
                      const SizedBox(height: 30),

                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: _starting ? null : _startTrial,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3F3CD6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            _ctaLabel,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.workSans(
                              color: const Color(0xFFFFFDF7),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Center(
                        child: Text(
                          'No credit card required. Cancel anytime.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({required String iconPath, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Image.asset(iconPath, width: 60, height: 60),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: -0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String day,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsApps.softCream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF4C586E),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: -0.3,
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
