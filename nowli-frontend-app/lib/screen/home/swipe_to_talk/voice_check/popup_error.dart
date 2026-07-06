import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

import 'package:nowlii/screen/home/swipe_to_talk/screen_flow_controller.dart';

class PoupError extends StatefulWidget {
  const PoupError({super.key});

  @override
  State<PoupError> createState() => _PoupErrorState();
}

class _PoupErrorState extends State<PoupError> with ScreenFlowMixin {
  String selectedLanguage = "";
  String selectedVoice = "";

  @override
  FlowScreen get flowScreen => FlowScreen.poupError;

  @override
  void initState() {
    super.initState();
    // Initialize automatic navigation flow (3 seconds delay)
    initializeFlow(context);
  }

  // -------------------------------
  // LANGUAGE BOTTOM SHEET
  // -------------------------------

  // -------------------------------
  // VOICE BOTTOM SHEET
  // -------------------------------

  // -------------------------------
  // MAIN SCREEN UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Assets.svgImages.popupScreeLiner.image().image,
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    // ✅ FIXED HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side - Profile/Avatar
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset(
                                "assets/images/blu_cross.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),

                        // Right side - AI Label
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 8),
                            Image.asset(
                              "assets/images/AI.png",
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    SizedBox(height: 40),
                    SizedBox(
                      width: 324.39,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 25,
                        children: [
                          SizedBox(
                            width: 273,
                            child: Text(
                              'SHARE HOW YOU',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(
                                  0xFF011F54,
                                ) /* Text-text-default */,
                                fontSize: 52,
                                fontFamily: 'Wosker',
                                fontWeight: FontWeight.w400,
                                height: 0.80,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 324.39,
                            child: Text(
                              'Tell me how you feel today - no pressure, just say it out loud. 🎧',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(
                                  0xFF011F54,
                                ) /* Text-text-default */,
                                fontSize: 18,
                                fontFamily: 'Work Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.40,
                                letterSpacing: -0.50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TITLE + IMAGES + BUTTONS
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: Assets.svgImages.popupSpeking.image().image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Assets.svgImages.popUpSpekingTwoCarton.image(
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),
                  Text(
                    'You didn’t say anything?\nHold and speak again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4542EB),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: -0.90,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
