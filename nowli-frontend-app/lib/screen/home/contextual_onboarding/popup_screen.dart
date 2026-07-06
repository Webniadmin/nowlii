import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        width: 282,
        height: 128,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF33B24E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Expanded(
              child: Text(
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
      width: 282,
      height: 128,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF33B24E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Expanded(
            child: Text(
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
        width: 282,
        height: 148,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF33B24E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Expanded(
              child: Text(
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
    return IntrinsicWidth(
      child: Column(
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
                    "assets/svg_icons/Ready to make today count?.png",
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Swipe here!\nIm available any time',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFFFFFDF7),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
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
