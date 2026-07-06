// AppsTextStyles.textDefaultStyle

import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/screen/settings/privacy_data/delete_account_dialog/delete_account_dialog.dart';
import 'package:nowlii/themes/text_styles.dart';

class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4C3EDD),
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset(
                      Assets.svgIcons.settingsBackIcon.path,
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'PRIVACY & DATA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFFFDF7) /* Text-text-light */,
                      fontSize: 32,
                      fontFamily: 'Wosker',
                      fontWeight: FontWeight.w400,
                      height: 0.80,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // White card container
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                children: [
                  _buildPrivacyItem(
                    context: context,
                    iconWidget: Image.asset(
                      Assets.svgIcons.privacyPolicy.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Privacy Policy',
                    onTap: () => _navigateToPolicy(context, 'Privacy Policy'),
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyItem(
                    context: context,
                    iconWidget: Image.asset(
                      Assets.svgIcons.privacyPolicy.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Terms of Use',
                    onTap: () => _navigateToPolicy(context, 'Terms of Use'),
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyItem(
                    context: context,
                    iconWidget: Image.asset(
                      Assets.svgIcons.deleteMyAccount.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Delete My Account',
                    onTap: () => _showDeleteAccountDialog(context),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem({
    required BuildContext context,
    required Widget iconWidget,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFFFE5E5)
                      : const Color(0xFFE8E9F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(title, style: AppsTextStyles.textDefaultStyle),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPolicy(BuildContext context, String policyType) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening $policyType')));
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteAccountDialog(),
    );
  }
}
