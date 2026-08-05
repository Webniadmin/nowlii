import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

/// What the out-of-sparks card opens when tapped.
///
/// The card said the day was over and then did nothing when pressed, which reads as a
/// button that is broken rather than a statement. This is the answer to the question the
/// card provokes — *why only two?* — and it makes the limit sound deliberate instead of
/// mean: the design's own words are "Two a day is limited by design."
///
/// It also carries the next step the user named on their last call, so the sheet ends on
/// something of theirs rather than on a rule of ours.
class OutOfSparksSheet extends StatelessWidget {
  const OutOfSparksSheet({super.key, this.nextStep});

  /// The next step from the most recent call that named one. Null or blank hides the card
  /// — quoting an empty string would be worse than saying nothing.
  final String? nextStep;

  static Future<void> show(BuildContext context, {String? nextStep}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // The design's scrim, which is darker and bluer than Flutter's default black54.
      barrierColor: const Color(0x99010530),
      builder: (_) => OutOfSparksSheet(nextStep: nextStep),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = nextStep?.trim() ?? '';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFEF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grab handle.
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0x2E011F54),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 9),
                Transform.rotate(
                  angle: 1.83 * math.pi / 180,
                  child: Image.asset(
                    Assets.svgIcons.companionSleeping.path,
                    width: 60,
                    height: 94.46,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "THAT'S THE\nWHOLE IDEA.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Wosker',
                    color: Color(0xFF011F54),
                    fontSize: 52,
                    fontWeight: FontWeight.w400,
                    height: 0.8,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Two a day is limited by design. Nowlii gives you a spark, then gets '
                  'out of your way.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF4C586E),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                    letterSpacing: -0.5,
                  ),
                ),
                if (step.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFEFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next step you named',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF4C586E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          '“$step”',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4542EB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      "Okay, I'm going",
                      style: GoogleFonts.workSans(
                        color: const Color(0xFFFFFEF8),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  // Closes the sheet first: leaving it open behind the receipts would put
                  // the user back here when they came back.
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutespath.receipts);
                  },
                  child: Text(
                    "Read today's receipts instead",
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4C586E),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
