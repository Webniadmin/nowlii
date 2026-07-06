// Delete Account Confirmation Dialog
import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/text_styles.dart';

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5E5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                Assets.svgIcons.deleteYourAccount.path,
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Delete Your Account?',
              style: AppsTextStyles.textDefaultStyle,
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'This will erase all your reflections, call history, and AI learning data.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Nowlli will forget everything it knows about you - and personalization will reset.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            const Text(
              'Are you sure you want to continue?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: Color(0xFF1E3A8A),
                        width: 2,
                      ),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppsTextStyles.textDefaultStyle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleDeleteAccount(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Delete',
                      style: AppsTextStyles.textDefaultStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    // Implement account deletion logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion initiated'),
        backgroundColor: Color(0xFFE53935),
      ),
    );
  }
}
