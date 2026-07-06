import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CallSummary extends StatelessWidget {
  const CallSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAE3CE),
                        borderRadius: BorderRadius.circular(750),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFF011F54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Avatar
                SizedBox(
                  width: 100,
                  height: 100,

                  child: Image.asset(
                    'assets/images/great job!.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'GREAT JOB!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF011F54),
                    fontSize: 52,
                    fontFamily: 'Wosker',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  "You nailed it! Here's what Fuzzy noticed during chat.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF4C586E),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.40,
                    letterSpacing: -0.50,
                  ),
                ),

                const SizedBox(height: 24),
                // Info Cards
                _buildInfoCard(
                  icon: 'assets/images/Mood detected.png',
                  title: 'Mood detected',
                  subtitle: 'You sounded calm and optimistic',
                  backgroundColor: const Color(0xFFFAE3CE),
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  icon: 'assets/images/Focus topic.png',
                  title: 'Focus topic',
                  subtitle: 'You talked about ',
                  boldText: 'staying consistent.',
                  backgroundColor: const Color(0xFFDFEFFF),
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  icon: 'assets/images/Energy shift.png',
                  title: 'Energy shift',
                  subtitle: 'You started tired but ended excited',
                  backgroundColor: const Color(0xFFDFEFFF),
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  icon: 'assets/images/Next step.png',
                  title: 'Next step',
                  subtitle: 'Plan your next quest!',
                  backgroundColor: const Color(0xFFDFEFFF),
                ),
                const SizedBox(height: 24),
                // Personal note section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Add personal note',
                      style: GoogleFonts.workSans(
                        color: const Color.fromARGB(255, 17, 17, 17),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.50,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      width: 2,
                      color: const Color(0xFFC3DBFF),
                    ),
                  ),
                  child: TextField(
                    maxLines: 2,

                    decoration: InputDecoration(
                      hintText: 'Write short note to yourself...',
                      hintStyle: GoogleFonts.workSans(
                        color: const Color(0xFF4C586E),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.50,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons - responsive layout using Expanded to avoid overflow
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 64,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 2,
                              color: const Color(0xFF6A68EF),
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Dismiss',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF4542EB),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 0.80,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 64,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF3F3CD6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Save reflection',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.workSans(
                              color: const Color(0xFFFFFDF7),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 0.80,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String icon,
    required String title,
    required String subtitle,
    String? boldText,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,

            child: Center(
              child: Image.asset(
                icon,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image,
                    size: 24,
                    color: Color(0xFF4C586E),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),
                boldText != null
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: subtitle,
                              style: GoogleFonts.workSans(
                                color: const Color(0xFF011F54),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.40,
                                letterSpacing: -0.50,
                              ),
                            ),
                            TextSpan(
                              text: boldText,
                              style: GoogleFonts.workSans(
                                color: const Color(0xFF011F54),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.40,
                                letterSpacing: -0.50,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        subtitle,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.40,
                          letterSpacing: -0.50,
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
