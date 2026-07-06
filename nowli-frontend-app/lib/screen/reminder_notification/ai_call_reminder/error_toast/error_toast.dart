import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorTueast extends StatelessWidget {
  const ErrorTueast({super.key});
  @override
  Widget build(BuildContext c) {
    return CustomPaint(
      // painter: Tail(),
      child: Container(
        width: 366,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: ShapeDecoration(
          color: const Color(0xFFFDDBDC) /* Background-bg-error-light */,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: ShapeDecoration(
                color: const Color(0xFFD53D40) /* Background-bg-error */,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFD53D40) /* Background-bg-error */,
                ),
                child: Icon(Icons.error_outline, color: Colors.white, size: 24),
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
                      'You missed our talk, that\'s okay ',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54) /* Text-text-default */,
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
                      'I\'m here when you\'re ready',
                      style: GoogleFonts.workSans(
                        color: const Color(
                          0xFF595754,
                        ) /* Text-text-secondary-default */,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,

                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFD53D3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Add another quest',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(
                            color: const Color(
                              0xFFFFFDF7,
                            ) /* Text-text-light */,
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
          ],
        ),
      ),
    );
  }
}

// class Tail extends CustomPainter {
//   @override
//   void paint(Canvas c, Size s) {
//     c.drawPath(
//       Path()
//         ..moveTo(20, s.height)
//         ..lineTo(32, s.height + 12)
//         ..lineTo(44, s.height),
//       Paint()..color = Color(0xFFFDDBDC),
//     );
//   }

//   @override
//   bool shouldRepaint(_) => false;
// }
