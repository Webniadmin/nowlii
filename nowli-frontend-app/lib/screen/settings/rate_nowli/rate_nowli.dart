import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingPopup extends StatelessWidget {
  const RatingPopup({super.key});

  // static void show(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => const RatingPopup(),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 335,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDFEFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
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
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFBEC3CB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),

          /// ICON BOX
          Container(
            width: 40.w,
            height: 40.h,
            padding: const EdgeInsets.all(9.8),
            decoration: BoxDecoration(
              color: const Color(0xFFC3DBFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/rate_nowlli.png', // তোমার image path
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 24),

          /// TITLE
          Text(
            'Rate Nowlli',
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              height: 1.20,
              letterSpacing: -0.50,
            ),
          ),

          const SizedBox(height: 12),

          /// DESCRIPTION
          Text(
            'Help Nowlli grow with you. Your thoughts mean a lot.',
            style: GoogleFonts.workSans(
              color: const Color(0xFF595754),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              height: 1.40,
              letterSpacing: -0.50,
            ),
          ),

          const SizedBox(height: 24),

          /// BUTTONS ROW
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: const Color(0xFF6A68EF),
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Next time',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4542EB),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      height: 0.80,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4542EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Yes',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFFFFFDF7),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      height: 0.80,
                    ),
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
/*


Container(
  width: 335,
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  decoration: BoxDecoration(
    color: const Color(0xFFDFEFFF),
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
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
    children: [
      Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFBEC3CB),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      const SizedBox(height: 12),

      /// ICON BOX
      Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(9.8),
        decoration: BoxDecoration(
          color: const Color(0xFFC3DBFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(),
      ),

      const SizedBox(height: 24),

      /// TITLE
      Text(
        'Rate Nowlli',
        style: GoogleFonts.workSans(
          color: const Color(0xFF011F54),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.20,
          letterSpacing: -0.50,
        ),
      ),

      const SizedBox(height: 12),

      /// DESCRIPTION
      Text(
        'Help Nowlli grow with you. Your thoughts mean a lot.',
        style: GoogleFonts.workSans(
          color: const Color(0xFF595754),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.40,
          letterSpacing: -0.50,
        ),
      ),

      const SizedBox(height: 24),

      /// BUTTONS ROW
      Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: const Color(0xFF6A68EF),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Next time',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF4542EB),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 0.80,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF4542EB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Yes',
                style: GoogleFonts.workSans(
                  color: const Color(0xFFFFFDF7),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 0.80,
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
);
*/