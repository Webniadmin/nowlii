import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/services/call_duration.dart';
import 'package:nowlii/services/number_words.dart';
import 'package:nowlii/services/voice_call_service.dart';
import 'package:nowlii/widget/animated_onboarding_topbar.dart';
import 'package:nowlii/widget/onboarding_continue_button.dart';

/// Step 7 — sets the expectation that the daily limit is a product decision, not
/// a paywall: two calls a day, five minutes each.
///
/// The mock draws no progress bar on this screen (it was authored later, with
/// different chrome), but it was decided this belongs inside the numbered flow,
/// so it carries the same topbar as every other step.
class LimitedByDesignScreen extends StatefulWidget {
  const LimitedByDesignScreen({super.key});

  @override
  State<LimitedByDesignScreen> createState() => _LimitedByDesignScreenState();
}

class _LimitedByDesignScreenState extends State<LimitedByDesignScreen> {
  /// The allowance the backend actually enforces. `VOICE_CALL_DAILY_LIMIT` is an env var,
  /// and the home and call screens already read it — writing "two" into this screen's copy
  /// meant onboarding could contradict the rest of the app after a config change.
  ///
  /// Starts at the published figure so the screen reads correctly before the call lands
  /// (and if it fails), rather than flashing a spinner over a sentence.
  int _callsPerDay = 2;

  @override
  void initState() {
    super.initState();
    _loadLimit();
  }

  Future<void> _loadLimit() async {
    final quota = await VoiceCallService().getQuota();
    if (!mounted || quota == null) return;
    // Unlimited test accounts report -1, which is not a number of rows to draw.
    if (quota.limit > 0) setState(() => _callsPerDay = quota.limit);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = screenHeight < 700;
    final isMediumDevice = screenHeight >= 700 && screenHeight < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: AnimatedOnboardingTopbar(
                  currentStep: 7,
                  totalSteps: kOnboardingTotalSteps,
                  backRoute: AppRoutespath.avatarLogoAndName,
                  skipRoute: AppRoutespath.tonightsReceipt,
                  isSmallDevice: isSmallDevice,
                  isMediumDevice: isMediumDevice,
                  screenWidth: screenWidth,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Limited by design',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${numberWord(_callsPerDay).toUpperCase()} SHORT\n'
                        'CALL${_callsPerDay == 1 ? '' : 'S'} A DAY.',
                        style: TextStyle(
                          color: const Color(0xFF011F54),
                          fontSize: isSmallDevice ? 38 : 46,
                          fontFamily: 'Wosker',
                          fontWeight: FontWeight.w400,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Because the goal is not to keep you here. Five minutes '
                        'is enough to say it out loud and pick one next step.',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF4C586E),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SparksCard(count: _callsPerDay),
                      const SizedBox(height: 18),
                      Text(
                        'No wrong time to use them — morning, midnight, or both.',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF4C586E),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              OnboardingContinueButton(
                onPressed: () => context.go(AppRoutespath.tonightsReceipt),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparksCard extends StatelessWidget {
  /// How many sparks a day the backend actually grants.
  final int count;

  const _SparksCard({required this.count});

  @override
  Widget build(BuildContext context) {
    // The mock shows a mascot peeking over this card. Rather than hardcode one
    // of the six companion assets, show the companion the user just picked and
    // named two screens ago — by this point they always have one.
    final avatar = OnboardingData().avatarLogo;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          decoration: ShapeDecoration(
            color: const Color(0xFFC3DBFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR ${numberWord(count).toUpperCase()} '
                'SPARK${count == 1 ? '' : 'S'}',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF4C586E),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              // One row per spark the user actually gets, rather than two written out.
              for (int i = 1; i <= count; i++) ...[
                if (i > 1) const Divider(color: Color(0x334C586E), height: 24),
                _SparkRow(number: '$i', title: '${ordinalWord(i)} spark'),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (avatar != null && avatar.isNotEmpty)
          Positioned(
            top: -26,
            right: -6,
            // The companion assets are square and carry their own coloured
            // background, so an unclipped one reads as a stray rectangle sitting on
            // the card's corner. Rounding it makes it a deliberate tile, matching how
            // the same art is framed in the picker two screens back.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 76,
                height: 76,
                child: avatar.startsWith('http')
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : Image.asset(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SparkRow extends StatelessWidget {
  final String number;
  final String title;

  const _SparkRow({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                callLengthCopy,
                style: GoogleFonts.workSans(
                  color: const Color(0xFF4C586E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
