import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-width primary action used by the last two onboarding steps.
///
/// Those two screens were authored later than the rest of the flow and use a
/// plain "Continue" bar rather than the circular `Icon button` the numbered
/// screens share, so this is deliberately its own thing and not a restyle of the
/// existing control.
class OnboardingContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const OnboardingContinueButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A3AFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.workSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
