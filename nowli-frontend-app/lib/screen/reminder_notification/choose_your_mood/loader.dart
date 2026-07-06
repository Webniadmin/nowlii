import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF0B2246);
  static const Color headingBlue = Color(0xFF061438);
  static const Color primary = Color(0xFF3A6BFF);
  static const Color orange = Color(0xFFFFA54F);

  static Color? get primaryColor => null;
}

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final baseScale = (width / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0 * baseScale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Orange heart icon container
                Container(
                  width: 80 * baseScale,
                  height: 80 * baseScale,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(20 * baseScale),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.favorite,
                      color: AppColors.navy,
                      size: 40 * baseScale,
                    ),
                  ),
                ),

                SizedBox(height: 32 * baseScale),

                // Main heading
                Text(
                  'Noted! Thanks for\nyour honesty!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28 * baseScale,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    height: 1.2,
                  ),
                ),

                SizedBox(height: 16 * baseScale),

                // Subtitle
                Text(
                  "Fuzzy's here to make today\na little easier.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16 * baseScale,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
