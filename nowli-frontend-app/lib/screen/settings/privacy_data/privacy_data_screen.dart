// AppsTextStyles.textDefaultStyle

import 'package:flutter/material.dart';
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/screen/settings/privacy_data/delete_account_dialog/delete_account_dialog.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    onTap: () =>
                        _openLegalUrl(context, ApiConstants.privacyPolicyUrl),
                  ),
                  const SizedBox(height: 12),
                  // TODO(legal): Terms of Use is not written yet. The row is hidden rather
                  // than left showing a dead "Opening Terms of Use" toast. Publish the
                  // document, set ApiConstants.termsOfServiceUrl, and restore this block —
                  // it must be live before the store listing.
                  // _buildPrivacyItem(
                  //   context: context,
                  //   iconWidget: Image.asset(
                  //     Assets.svgIcons.privacyPolicy.path,
                  //     width: 40,
                  //     height: 40,
                  //   ),
                  //   title: 'Terms of Use',
                  //   onTap: () =>
                  //       _openLegalUrl(context, ApiConstants.termsOfServiceUrl),
                  // ),
                  // const SizedBox(height: 12),
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

  /// Open a legal document in the browser.
  ///
  /// This used to show an "Opening Privacy Policy" toast and go nowhere. Play requires the
  /// policy to be genuinely reachable from inside the app, not just from the listing.
  Future<void> _openLegalUrl(BuildContext context, String url) async {
    if (url.isEmpty) return; // not published yet — see TODO(legal)
    final opened =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open $url")),
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteAccountDialog(),
    );
  }
}
