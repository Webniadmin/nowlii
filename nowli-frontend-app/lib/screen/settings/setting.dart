import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/api/auth_controller.dart';
import 'package:nowlii/screen/settings/api_personalization_screen/ai_personalization_screen.dart';
import 'package:nowlii/screen/settings/language/languegs_selector_screen.dart';
import 'package:nowlii/screen/settings/notification_screen/notification_screen.dart';

import 'package:nowlii/screen/settings/privacy_data/privacy_data_screen.dart';
import 'package:nowlii/screen/settings/rate_nowli/rate_nowli.dart';
import 'package:nowlii/themes/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundsEnabled = true;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundsEnabled = prefs.getBool('settings_sounds_enabled') ?? true;
      _selectedLanguage = prefs.getString('settings_language') ?? 'English';
    });
  }

  Future<void> _saveSoundsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_sounds_enabled', value);
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_language', language);
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          LanguageSelector(currentLanguage: _selectedLanguage),
    ).then((value) {
      if (value != null) {
        setState(() => _selectedLanguage = value);
        _saveLanguage(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4C3EDD),
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildHeader()),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFFEF8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.nowliPro.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Nowtli Pro',
                    onTap: () => {context.push('/subscriptionPage')},
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.notifications.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.aIPersonalization.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'AI Personalization',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIPersonalizationScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.language.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    onTap: _showLanguageSelector,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.sounds.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Sounds',
                    trailing: Switch(
                      value: _soundsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _soundsEnabled = value;
                        });
                        _saveSoundsEnabled(value);
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF4542EB),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFB0B0B0),
                    ),
                    onTap: null,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.privacyData.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Privacy & Data',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyDataScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.help.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Help',
                    onTap: () => _navigateTo('Help'),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.rateNowliw.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Rate Nowtli',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const RatingPopup(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.logOut.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Log out',
                    onTap: _handleLogout,
                    titleColor: const Color(0xFFE53935),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            // color: Colors.black,
            icon: Image.asset(
              Assets.svgIcons.settingsBackIcon.path,
              width: 32,
              height: 32,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text('SETTINGS', style: AppsTextStyles.kSettingsTitleStyle),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    IconData? icon,
    Widget? iconWidget, // <-- New optional widget
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),

                child:
                    iconWidget ??
                    (icon != null ? Icon(icon, size: 20) : const SizedBox()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppsTextStyles.textDefaultStyle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xFF1A1A1A),
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(String destination) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigate to $destination')));
  }

  void _handleLogout() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 335,
            padding: const EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: 40,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFDFEFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Drag Indicator
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBEC3CB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                const SizedBox(height: 24),

                /// Title
                Text(
                  'Are you sure you want to log out?',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),

                const SizedBox(height: 32),

                /// Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2,
                              color: const Color(0xFF011F54),
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF011F54),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 0.80,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // Close dialog
                          Navigator.of(context).pop();
                          
                          // Perform logout
                          final authController = AuthController();
                          await authController.logout();
                          
                          // Navigate to sign in screen
                          if (context.mounted) {
                            context.go(AppRoutespath.signInScreen);
                          }
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4542EB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Log out',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFFFFFDF7),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 0.80,
                            ),
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
      },
    );
  }
}
