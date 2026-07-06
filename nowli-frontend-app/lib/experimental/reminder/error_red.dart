import 'package:flutter/material.dart';

class ErrorRed extends StatelessWidget {
  const ErrorRed({super.key});
  @override
  Widget build(BuildContext c) {
    return CustomPaint(
      child: Container(
        width: 335,
        height: 282,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/reminder_red.png'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 10,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD53D40) /* Background-bg-error */,
                    ),
                    child: Stack(),
                  ),
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
                      'You missed our talk, that’s okay ',
                      style: TextStyle(
                        color: const Color(0xFF011F54) /* Text-text-default */,
                        fontSize: 20,
                        fontFamily: 'Work Sans',
                        fontWeight: FontWeight.w800,
                        height: 1.20,
                        letterSpacing: -0.50,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 237,
                    child: Text(
                      'I’m here when you’re ready',
                      style: TextStyle(
                        color: const Color(
                          0xFF595754,
                        ) /* Text-text-secondary-default */,
                        fontSize: 14,
                        fontFamily: 'Work Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFD53D3F),
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
                        Flexible(
                          child: Text(
                            'Add another quest',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(
                                0xFFFFFDF7,
                              ) /* Text-text-light */,
                              fontSize: 18,
                              fontFamily: 'Work Sans',
                              fontWeight: FontWeight.w900,
                              height: 0.80,
                            ),
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
