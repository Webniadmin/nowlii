import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/widget/animated_onboarding_topbar.dart';

/// Section heading inside the blue tips sheet.
///
/// `small` is for the two sub-headings under "A couple of honest truths" — they
/// sit a level below it, so they must not compete with it visually.
Widget _sectionHeading(String text, double screenWidth, {bool small = false}) {
  return Text(
    text,
    style: GoogleFonts.workSans(
      color: const Color(0xFFFFFCF1),
      fontSize: screenWidth * (small ? 0.042 : 0.05),
      fontWeight: FontWeight.w900,
      height: 1.25,
      letterSpacing: -0.10,
    ),
  );
}

Widget _sectionBody(String text, double screenWidth) {
  return Text(
    text,
    style: GoogleFonts.workSans(
      color: const Color(0xFFFFFCF1),
      fontSize: screenWidth * 0.04,
      fontWeight: FontWeight.w500,
      height: 1.50,
      letterSpacing: -0.10,
    ),
  );
}

class NowliHowToUse extends StatelessWidget {
  const NowliHowToUse({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallDevice = screenHeight < 700;
    final isMediumDevice = screenHeight >= 700 && screenHeight < 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  AnimatedOnboardingTopbar(
                    currentStep: 4,
                    totalSteps: kOnboardingTotalSteps,
                    backRoute: "/onbordingFetures",
                    skipRoute: "/avatarLogo",
                    isSmallDevice: isSmallDevice,
                    isMediumDevice: isMediumDevice,
                    screenWidth: screenWidth,
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Card with icon and text
                  Container(
                    height: screenHeight * 0.19,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA0E871),
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: screenWidth * 0.35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.03,
                            ),
                          ),
                          child: Assets.svgIcons.nowliHowToUse.svg(
                            height: screenHeight * 0.15,
                            width: screenWidth * 0.28,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: Text(
                            'Nowlii is like a car, it is your toll that will bring where you are headed to! 🌱 like a domino effect in your life actions.',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF011F54),
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w900,
                              height: 1.7,
                              letterSpacing: -0.10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          'Our biggest goal is you to stop\nto use Nowlii after 12 months.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.workSans(
                            fontWeight: FontWeight.w900,
                            fontSize: screenWidth * 0.055,
                            height: 1.4,
                            color: const Color(0xFF011F54),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),

                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),

          // Bottom Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.55),
              padding: EdgeInsets.only(
                left: screenWidth * 0.06,
                right: screenWidth * 0.06,
                top: screenHeight * 0.018,
                bottom: screenHeight * 0.03,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF4542EB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.06),
                  topRight: Radius.circular(screenWidth * 0.06),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SOME OF OUR TIPS AND\nTRICKS HOW TO USE\nNOWLII 🛋️💡',
                        maxLines: 3,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFFFFFCF1),
                          fontSize: screenWidth * 0.062,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                          letterSpacing: -0.10,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    _sectionHeading('TIME IT RIGHT', screenWidth),
                    SizedBox(height: screenHeight * 0.012),

                    // ✅ Description - Fixed 5 lines all devices
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: screenWidth * 0.88,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                    'We recommend booking the call with Nowlii when you are putting an alarm at night,',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFFFFFCF1),
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w500,
                                  height: 1.50,
                                  letterSpacing: -0.10,
                                ),
                              ),
                              TextSpan(
                                text: ' 10 minutes after the alarm',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFFFFFCF1),
                                  fontSize: screenWidth * 0.047,
                                  fontWeight: FontWeight.w700,
                                  height: 1.40,
                                  letterSpacing: -0.50,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' so Nowlii will be there to start the day with you ✨',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFFFFFCF1),
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.w500,
                                  height: 1.50,
                                  letterSpacing: -0.50,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 5,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.035),

                    // ── "A couple of honest truths" ──
                    // Added 2026-07-31 from the updated onboarding design; this
                    // section is why the screen now scrolls rather than fitting a
                    // single viewport.
                    _sectionHeading('A COUPLE OF HONEST TRUTHS', screenWidth),
                    SizedBox(height: screenHeight * 0.02),

                    _sectionHeading(
                      'CLOSE TO YOURSELF, CLOSER TO OTHERS',
                      screenWidth,
                      small: true,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    _sectionBody(
                      'We all carry heavy loads. Sometimes the biggest act of love '
                      'to yourself and others is to first talk it out with yourself '
                      'and let your voice lead your way.',
                      screenWidth,
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    _sectionHeading(
                      "YOUR EASY IS SOMEONE'S HARD. AND OTHER WAY AROUND.",
                      screenWidth,
                      small: true,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    _sectionBody(
                      'Making a quick phone call can feel like climbing a mountain. '
                      'Running a marathon can feel like a breeze. We all have '
                      'different hard. No judgment, no comparison — know and be '
                      'honest with yourself.',
                      screenWidth,
                    ),

                    SizedBox(height: screenHeight * 0.035),

                    // Next Button
                    GestureDetector(
                      onTap: () => context.go("/avatarLogo"),
                      child: Container(
                        width: double.infinity,
                        height: screenHeight * 0.13,
                        padding: EdgeInsets.only(
                          top: screenHeight * 0.008,
                          left: screenWidth * 0.08,
                          right: screenWidth * 0.02,
                          bottom: screenHeight * 0.008,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFFF8F26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          shadows: [
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
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Next text
                            Expanded(
                              child: Text(
                                'Next',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF011F54),
                                  fontSize: screenWidth * 0.07,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ),

                            // Arrow icon
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.035),
                              decoration: ShapeDecoration(
                                color: const Color(0xFF011F54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: SvgPicture.asset(
                                Assets.svgIcons.startLetsGo.path,
                                width: screenWidth * 0.13,
                                height: screenWidth * 0.13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
