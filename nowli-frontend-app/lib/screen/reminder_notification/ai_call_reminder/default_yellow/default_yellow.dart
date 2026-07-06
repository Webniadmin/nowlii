import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DefaultYellow extends StatelessWidget {
  const DefaultYellow({super.key});
  @override
  Widget build(BuildContext c) {
    return CustomPaint(
      // painter: Tail(),
      child: Container(
        width: 335,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFCE73),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFF8F26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 10,
                      children: [
                        SizedBox(width: 24, height: 24, child: Stack()),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 16,
                      children: [
                        SizedBox(
                          width: 237,
                          child: Text(
                            'Quest starts soon! Wanna share how u feel before we dive in?',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF011F54),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.20,
                              letterSpacing: -0.50,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 237,
                          child: Text(
                            'Send a voice note to your bestie- me! Tell me what s on your mind, or how youre feeling before the session.',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF595754),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: ShapeDecoration(
                color: const Color(0xFFFF8F26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 8,
                children: [
                  SizedBox(width: 18, height: 18, child: Stack()),
                  Text(
                    'Send a quick note',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 0.80,
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
