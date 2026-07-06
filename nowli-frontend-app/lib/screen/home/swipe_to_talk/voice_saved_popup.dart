import 'package:flutter/material.dart';

class VoiceSavedPopup extends StatelessWidget {
  const VoiceSavedPopup({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const VoiceSavedPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD89C),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.volunteer_activism,
                color: const Color(0xFF011F54),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your voice note is saved.',
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 18,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fuzzy will check in soon',
                    style: TextStyle(
                      color: const Color(0xFF011F54),
                      fontSize: 16,
                      fontFamily: 'Work Sans',
                      fontWeight: FontWeight.w400,
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
