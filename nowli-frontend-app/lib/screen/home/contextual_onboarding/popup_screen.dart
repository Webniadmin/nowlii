import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/widget/auto_shrink_text.dart';

/// The tutorial bubbles were drawn at a flat 282 wide inside a fixed height.
/// On a 320dp screen that is the whole width bar a couple of points, so the
/// copy inside had nowhere to wrap and the fixed height cut it off. Keep the
/// design width where it fits, and step back from the screen edges where it
/// does not.
double _bubbleWidth(BuildContext context) =>
    math.min(282.0, MediaQuery.sizeOf(context).width - 32);

// Add to HomeScreen's initState or build method:
// OnboardingOverlay.show(context);

class OnboardingOverlay {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const OnboardingDialog(),
    );
  }
}

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int _step = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      widget: const ChatBubbleContainer(),
      position: const Alignment(0, -0.3),
    ),
    OnboardingStep(
      widget: const ChatMessage(),
      position: const Alignment(0.5, 0),
    ),
    OnboardingStep(
      widget: const ConversationBubble(),
      position: const Alignment(-0.5, 0.4),
    ),
    OnboardingStep(
      widget: const TextBubble(),
      position: const Alignment(0, 0.6),
    ),
  ];

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _next,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              alignment: _steps[_step].position,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_step),
                  child: _steps[_step].widget,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingStep {
  final Widget widget;
  final Alignment position;

  OnboardingStep({required this.widget, required this.position});
}

// Bubble Widgets
class ChatBubbleContainer extends StatelessWidget {
  const ChatBubbleContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BubbleTail(),
      child: Container(
        width: _bubbleWidth(context),
        height: 128,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF33B24E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Expanded(
              child: AutoShrinkText(
                "Start here. A good day begins with rest.",
                style: GoogleFonts.workSans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Next",
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF184B29),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF184B29),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _bubbleWidth(context),
      height: 128,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF33B24E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Expanded(
            child: AutoShrinkText(
              "Swipe left to reschedule or edit quests..",
              style: GoogleFonts.workSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Next",
                style: GoogleFonts.workSans(
                  color: const Color(0xFF184B29),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF184B29),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ConversationBubble extends StatelessWidget {
  const ConversationBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BubbleTail(),
      child: Container(
        width: _bubbleWidth(context),
        height: 148,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF33B24E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Expanded(
              child: AutoShrinkText(
                "Every streak starts with day one. You've already begun 💫",
                style: GoogleFonts.workSans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Next",
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF184B29),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF184B29),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TextBubble extends StatelessWidget {
  const TextBubble({super.key});

  @override
  Widget build(BuildContext context) {
    // No `IntrinsicWidth` here any more. The text below now sets its own width,
    // so there is nothing left for it to measure — and it cannot measure what
    // is inside: `AutoShrinkText` is a `LayoutBuilder`, which has no intrinsic
    // width to give, so the whole bubble collapsed to nothing. The tutorial's
    // last step dimmed the screen and drew no bubble at all, which read as the
    // app hanging for as long as it took to tap again.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3BB64B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    // The old path had a "?" in the filename, which cannot exist on
                    // Windows — the file is gone and this rendered as a broken image.
                    Assets.svgIcons.avatar.path,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: _bubbleWidth(context) - 32,
                  // Was "Swipe here! / Im available any time" — it never said
                  // what swiping does, and the app's own word for a call is a
                  // spark, which is what the control underneath is labelled.
                  // (The missing apostrophe was in the original too.)
                  child: AutoShrinkText(
                    'Swipe here to start a spark.\nI\'m available any time.',
                    maxLines: 2,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFFFFFDF7),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      );
  }
}

class BubbleTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(20, size.height)
        ..lineTo(32, size.height + 12)
        ..lineTo(44, size.height),
      Paint()..color = const Color(0xFF33B24E),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
