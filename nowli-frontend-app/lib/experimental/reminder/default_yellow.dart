import 'package:flutter/material.dart';

class DefaultYellow extends StatelessWidget {
  const DefaultYellow({super.key});
  @override
  Widget build(BuildContext c) {
    return CustomPaint(
      child: Container(
        width: 282,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/reminder_yellow.png'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9E45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF061B3B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Quest starts soon!",
                        style: TextStyle(
                          color: Color(0xFF061B3B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Wanna share how u feel before we dive in?",
                        style: TextStyle(
                          color: Color(0xFF061B3B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Send a voice note to your bestie- me! Tell me what’s on your mind, or how you’re feeling before the session.",
              style: TextStyle(
                color: Color(
                  0xFF5A4E38,
                ), // Darker brownish shade for contrast on yellow
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8B22),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.mic, color: Color(0xFF061B3B), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Send a quick note",
                    style: TextStyle(
                      color: Color(0xFF061B3B),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
