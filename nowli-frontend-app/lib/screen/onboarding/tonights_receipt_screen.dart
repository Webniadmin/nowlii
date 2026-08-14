import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/widget/animated_onboarding_topbar.dart';
import 'package:nowlii/widget/onboarding_continue_button.dart';

/// Step 8 — previews the receipt the user gets after each call.
///
/// The numbers and words below are an **illustration, not live data**, and have
/// to be: this screen runs during onboarding, before the user has ever made a
/// call. The real receipt — with words actually pulled from the transcript —
/// belongs to `CallSummaryScreen`.
class TonightsReceiptScreen extends StatelessWidget {
  const TonightsReceiptScreen({super.key});

  /// Sample words for the preview card. Taken from the design mock.
  static const List<String> _sampleWords = ['should', 'later', 'honestly'];

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
                  currentStep: 8,
                  totalSteps: kOnboardingTotalSteps,
                  backRoute: AppRoutespath.limitedByDesign,
                  skipRoute: AppRoutespath.popupSpeking,
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
                        'After every spark',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'YOU GET YOUR\nOWN WORDS BACK.',
                        style: TextStyle(
                          color: const Color(0xFF011F54),
                          fontSize: isSmallDevice ? 34 : 42,
                          fontFamily: 'Wosker',
                          fontWeight: FontWeight.w400,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'A small receipt for the words you used. No labels, '
                        'no diagnosis. Just a mirror.',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF4C586E),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _ReceiptPreviewCard(words: _sampleWords),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              OnboardingContinueButton(
                onPressed: () => context.go(AppRoutespath.popupSpeking),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptPreviewCard extends StatelessWidget {
  final List<String> words;

  const _ReceiptPreviewCard({required this.words});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFCF1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flexible because the row has no give otherwise: two bare Texts
              // under `spaceBetween` will overflow rather than wrap the moment
              // the title needs more room than the card has — a wider
              // translation, or the OS font slider at its 1.15 cap. The
              // duration beside it is short and fixed, so the title is the half
              // that should yield.
              Flexible(
                child: Text(
                  'Nowlii Receipt',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '04:58',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF4C586E),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x334C586E), height: 26),
          Text(
            'Words you circled around',
            style: GoogleFonts.workSans(
              color: const Color(0xFF4C586E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final word in words)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFE6F0FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    '“$word”',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
