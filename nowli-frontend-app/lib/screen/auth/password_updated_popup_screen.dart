import 'package:flutter/material.dart';
import 'package:nowlii/themes/text_styles.dart' show AppsTextStyles;

class PasswordUpdatedPopupScreen extends StatelessWidget {
  const PasswordUpdatedPopupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: const Color(0xFFDFEFFF), // light bluish tone
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top indicator bar (like modal)
          Container(
            width: 50,
            height: 6,
            decoration: BoxDecoration(
              color: Color(0xFFBEC3CB),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 32),

          // Circle with check mark
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3C4BFF), width: 3),
            ),
            child: const Center(
              child: Icon(Icons.check, size: 60, color: Color(0xFF3C4BFF)),
            ),
          ),

          const SizedBox(height: 32),

          // Text section
          Text('Password updated!', style: AppsTextStyles.passwordUpdate),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  "You’re all set to log in 🔐 ",
                  style: AppsTextStyles.passwordUpdateSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
