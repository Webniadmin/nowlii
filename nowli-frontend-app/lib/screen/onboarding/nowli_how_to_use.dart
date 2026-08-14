import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/widget/animated_onboarding_topbar.dart';

/// Step 4 — how to use Nowlii. Rebuilt to the design (Figma `46:10084`).
///
/// **What was wrong.** The blue tips sheet was a `Positioned(bottom: 0)` capped
/// at 55% of the screen, laid *over* the column behind it. On anything shorter
/// than the mock it covered the sentence above it, so "Our biggest goal is you
/// to stop to use Nowlii after 12 months." was sliced through its second line —
/// the screen's whole point, half-hidden. And the three pieces of advice were
/// run together as loose paragraphs; the design gives each one its own card with
/// a round icon, which is what makes the panel readable rather than a wall.
///
/// The page is one scroll now: the sheet follows the heading instead of floating
/// over it, so nothing can cover anything, at any height.
///
/// The three icons are Material glyphs in coloured circles. The design's are
/// custom, but they were never exported, and a clock, a speech bubble and a pair
/// of scales are exactly what these are — worth revisiting if the art arrives.
class NowliHowToUse extends StatelessWidget {
  const NowliHowToUse({super.key});

  static const _cream = Color(0xFFFFFCF1);
  static const _navy = Color(0xFF011F54);
  static const _panelBlue = Color(0xFF4542EB);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isSmallDevice = screenHeight < 700;
    final isMediumDevice = screenHeight >= 700 && screenHeight < 800;
    final gutter = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, screenHeight * 0.015, gutter, 0),
              child: AnimatedOnboardingTopbar(
                currentStep: 4,
                totalSteps: kOnboardingTotalSteps,
                backRoute: "/onbordingFetures",
                skipRoute: "/avatarLogo",
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
                    SizedBox(height: screenHeight * 0.025),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      child: _IntroCard(screenWidth: screenWidth),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter),
                      child: Text(
                        'Our biggest goal is you to stop to use Nowlii after '
                        '12 months.',
                        style: GoogleFonts.workSans(
                          color: _navy,
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    _TipsPanel(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      gutter: gutter,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The green card at the top: the app's mark on white, and the one-line idea.
class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.screenWidth});

  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFA0E871),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: screenWidth * 0.30,
            height: screenWidth * 0.30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.035),
            ),
            child: Center(
              child: Assets.svgIcons.nowliHowToUse.svg(
                width: screenWidth * 0.20,
                height: screenWidth * 0.20,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            // Height is free here — the page scrolls — so the sentence simply
            // takes the lines it needs instead of being trimmed to a box.
            child: Text(
              'Nowlii is like a car, it is your toll that will bring where you '
              'are headed to! 🌱 like a domino effect in your life actions.',
              style: GoogleFonts.workSans(
                color: NowliHowToUse._navy,
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w900,
                height: 1.45,
                letterSpacing: -0.10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The blue sheet: a title, three advice cards, and the way on.
class _TipsPanel extends StatelessWidget {
  const _TipsPanel({
    required this.screenWidth,
    required this.screenHeight,
    required this.gutter,
  });

  final double screenWidth;
  final double screenHeight;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        gutter,
        screenHeight * 0.03,
        gutter,
        screenHeight * 0.03 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: NowliHowToUse._panelBlue,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screenWidth * 0.06),
          topRight: Radius.circular(screenWidth * 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOME OF OUR TIPS AND TRICKS HOW TO USE NOWLII 🛋️💡',
            style: GoogleFonts.workSans(
              color: NowliHowToUse._cream,
              fontSize: screenWidth * 0.062,
              fontWeight: FontWeight.w900,
              height: 1.25,
              letterSpacing: -0.10,
            ),
          ),
          SizedBox(height: screenHeight * 0.025),
          _TipCard(
            screenWidth: screenWidth,
            icon: Icons.schedule_rounded,
            iconBackground: const Color(0xFFFF8F26),
            title: 'TIME IT RIGHT',
            body: TextSpan(
              children: [
                TextSpan(
                  text: 'We recommend booking the call with Nowlii when you '
                      'are putting an alarm at night,',
                  style: _bodyStyle(screenWidth),
                ),
                TextSpan(
                  text: ' 10 minutes after the alarm',
                  style: _bodyStyle(screenWidth).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' so Nowlii will be there to start the day with you ✨',
                  style: _bodyStyle(screenWidth),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.035),
          Text(
            'A COUPLE OF HONEST TRUTHS',
            style: GoogleFonts.workSans(
              color: NowliHowToUse._cream,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w900,
              height: 1.25,
              letterSpacing: -0.10,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          _TipCard(
            screenWidth: screenWidth,
            icon: Icons.chat_bubble_rounded,
            iconBackground: const Color(0xFFC7C6FF),
            iconColor: NowliHowToUse._panelBlue,
            title: 'CLOSE TO YOURSELF, CLOSER TO OTHERS',
            body: TextSpan(
              text: 'We all carry heavy loads. Sometimes the biggest act of '
                  'love to yourself and others is to first talk it out with '
                  'yourself and let your voice lead your way.',
              style: _bodyStyle(screenWidth),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          _TipCard(
            screenWidth: screenWidth,
            icon: Icons.balance_rounded,
            iconBackground: const Color(0xFF7BD87F),
            iconColor: NowliHowToUse._navy,
            title: "YOUR EASY IS SOMEONE'S HARD. AND OTHER WAY AROUND.",
            body: TextSpan(
              text: 'Making a quick phone call can feel like climbing a '
                  'mountain. Running a marathon can feel like a breeze. We all '
                  'have different hard. No judgment, no comparison — know and '
                  'be honest with yourself.',
              style: _bodyStyle(screenWidth),
            ),
          ),
          SizedBox(height: screenHeight * 0.035),
          _NextButton(screenWidth: screenWidth, screenHeight: screenHeight),
        ],
      ),
    );
  }

  static TextStyle _bodyStyle(double screenWidth) => GoogleFonts.workSans(
        color: NowliHowToUse._cream,
        fontSize: screenWidth * 0.044,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: -0.10,
      );
}

/// One piece of advice: round icon, small caps title, body.
class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.screenWidth,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.body,
    this.iconColor = Colors.white,
  });

  final double screenWidth;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final TextSpan body;

  @override
  Widget build(BuildContext context) {
    final iconSize = screenWidth * 0.11;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize * 0.55, color: iconColor),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.workSans(
                    color: NowliHowToUse._cream,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.03),
          Text.rich(body),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.screenWidth, required this.screenHeight});

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go("/avatarLogo"),
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.115,
        padding: EdgeInsets.only(
          top: screenHeight * 0.008,
          left: screenWidth * 0.06,
          right: screenWidth * 0.02,
          bottom: screenHeight * 0.008,
        ),
        decoration: ShapeDecoration(
          color: const Color(0xFFFF8F26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x070A0C12),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Color(0x140A0C12),
              blurRadius: 16,
              offset: Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Next',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.workSans(
                    color: NowliHowToUse._navy,
                    fontSize: screenWidth * 0.07,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: const ShapeDecoration(
                color: NowliHowToUse._navy,
                shape: CircleBorder(),
              ),
              child: SvgPicture.asset(
                Assets.svgIcons.startLetsGo.path,
                width: screenWidth * 0.11,
                height: screenWidth * 0.11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
