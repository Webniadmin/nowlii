import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class ProcrastinationScreen extends StatefulWidget {
  const ProcrastinationScreen({super.key});

  @override
  State<ProcrastinationScreen> createState() => _ProcrastinationScreenState();
}

class _ProcrastinationScreenState extends State<ProcrastinationScreen> {
  String selectedLanguage = "English";
  String selectedVoice = "";

  // -------------------------------
  // LANGUAGE BOTTOM SHEET
  // -------------------------------
  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: 40,
            ),
            decoration: ShapeDecoration(
              color: const Color(0xFFDFEFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Handle bar
                Container(
                  width: 38,
                  height: 4,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFBEC3CB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.20,
                          letterSpacing: -0.50,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Language options
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // English
                            _buildLanguageOption('English'),
                            const SizedBox(height: 24),


                            // Español
                            _buildLanguageOption('Español'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });
        Navigator.pop(context);
        // Show voice selection after language is selected
        Future.delayed(const Duration(milliseconds: 300), () {
          _showVoiceBottomSheet();
        });
      },
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              language,
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.40,
                letterSpacing: -0.90,
              ),
            ),
            // Radio button indicator
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedLanguage == language
                      ? const Color(0xFF4542EB)
                      : const Color(0xFFBEC3CB),
                  width: 2,
                ),
              ),
              child: selectedLanguage == language
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4542EB),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------
  // VOICE BOTTOM SHEET
  // -------------------------------
  void _showVoiceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: 40,
            ),
            decoration: ShapeDecoration(
              color: const Color(0xFFDFEFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Handle bar
                Container(
                  width: 38,
                  height: 4,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFBEC3CB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose voice',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.20,
                          letterSpacing: -0.50,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Voice options
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Female
                            _buildVoiceOption('Female'),
                            const SizedBox(height: 24),

                            // Male
                            _buildVoiceOption('Male'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceOption(String voice) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVoice = voice;
        });
        Navigator.pop(context);
      },
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              voice,
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.40,
                letterSpacing: -0.90,
              ),
            ),
            // Radio button indicator
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedVoice == voice
                      ? const Color(0xFF4542EB)
                      : const Color(0xFFBEC3CB),
                  width: 2,
                ),
                color: selectedVoice == voice
                    ? const Color(0xFF4542EB)
                    : Colors.transparent,
              ),
              child: selectedVoice == voice
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

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
              // Close Button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.close, color: Colors.blue),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // TITLE + IMAGES + BUTTONS
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'In one line, how does the procrastination show up to you?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4542EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // IMAGE STACK
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: Assets.svgImages.twoColorPopupSpkeing
                                .image()
                                .image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: Assets.svgImages.popupSpeking.image().image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: ClipOval(
                            child: Assets.svgImages.popUpSpekingTwoCarton.image(
                              width: 120,
                              height: 120,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // BUTTON ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Choose AI voice button
                      GestureDetector(
                        onTap: () {
                          // context.push("/aiVoice");
                          // context.go("");
                          context.push("/popSpkingLoding");
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 3,
                                color: Color(0xFF4542EB),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            'Choose AI voice',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF4542EB),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 0.8,
                            ),
                          ),
                        ),
                      ),

                      // Language selection button
                      GestureDetector(
                        onTap: () {
                          _showLanguageBottomSheet();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 3,
                                color: Color(0xFF4542EB),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            selectedLanguage.isEmpty
                                ? 'English'
                                : selectedLanguage,
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF4542EB),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
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

