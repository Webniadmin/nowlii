import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class AllQuestsDonePopup extends StatelessWidget {
  const AllQuestsDonePopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Quests for today done popup.png',
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Image.asset(
                      Assets.svgIcons.dailyTalksWithFuzzy.path,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Headline
                  SizedBox(
                    width: 337,
                    child: Text(
                      'YOU\u2019VE DONE ALL QUESTS FOR TODAY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF011F54),
                        fontSize: 63.18,
                        fontFamily: 'Wosker',
                        fontWeight: FontWeight.w400,
                        height: 0.80,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Add new quest button
                  Container(
                    width: double.infinity,
                    height: 64,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF4542EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            Assets.images.whitePlus.path,
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Add new quest',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(
                            color: const Color(0xFFFFFDF7),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Close button (top-left X)
          Positioned(
            top: 48,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Image.asset(
                  Assets.images.bluCross.path,
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
