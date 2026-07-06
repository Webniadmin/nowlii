import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

import 'package:nowlii/utils/color_palette/color_palette.dart';
import 'package:nowlii/api/google_sign_in_flow.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsApps.lightBlueBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 64,
                  height: 59,
                  child: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.black87,
                        size: 34,
                      ),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Illustration
              Center(child: Assets.svgImages.welcomeBack.svg(height: 180)),

              const Spacer(),

              // Google Button
              SizedBox(
                width: double.infinity,
                height: 74,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A46FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Assets.svgIcons.googleIcon.svg(height: 24, width: 24),
                      const SizedBox(width: 12),
                    ],
                  ),
                  label: Text(
                    'Continue with Google',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFFFFFDF7),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 0.80,
                    ),
                  ),
                  onPressed: () => handleGoogleSignIn(context),
                ),
              ),

              // SizedBox(
              //   width: double.infinity,
              //   height: 74,
              //   child: ElevatedButton.icon(
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: const Color(0xFF4A46FF),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(50),
              //       ),
              //     ),
              //     icon: Assets.svgIcons.googleIcon.svg(height: 24, width: 24),
              //     SizedBox(width: 12),
              //     label: Text(
              //       'Continue with Google',
              //       textAlign: TextAlign.center,
              //       style: GoogleFonts.workSans(
              //         color: const Color(0xFFFFFDF7), // Text-light
              //         fontSize: 20,
              //         fontWeight: FontWeight.w900,
              //         height: 0.80,
              //       ),
              //     ),
              //     onPressed: () {
              //       context.push("/readyToStartScreen");
              //     },
              //   ),
              // ),
              const SizedBox(height: 8),

              // Apple Button
              SizedBox(
                width: double.infinity,
                height: 74,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A46FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Assets.svgIcons.appleIcon.svg(height: 24, width: 24),
                      const SizedBox(width: 12),
                    ],
                  ),
                  label: Text(
                    'Continue with Apple',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFFFFFDF7),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 0.80,
                    ),
                  ),
                  onPressed: () => handleAppleSignIn(context),
                ),
              ),

              const SizedBox(height: 24),

              // Privacy Policy Text
              // Center(
              //   child: Text(
              //     'By signing up, you agree to Nowlii’s Privacy Policy & Terms of Service.',
              //     style: AppsTextStyles.haveAnAccount.copyWith(
              //       fontSize: 14,
              //       color: Colors.black54,
              //     ),
              //     textAlign: TextAlign.center,
              //   ),
              // ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
