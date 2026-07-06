// import 'package:flutter/material.dart';
// import 'package:nowlii/screen/settings/api_personalization_screen/clear_memory_popup/clear_memory_popup.dart';
// import 'package:nowlii/screen/settings/api_personalization_screen/restricted_topics_popup/restricted_topiccs_popup.dart';
// import 'package:nowlii/screen/settings/api_personalization_screen/voice_selector_popup/voice_selector_popup.dart';
// import 'package:nowlii/themes/text_styles.dart';
// import 'package:nowlii/core/gen/assets.gen.dart';

// class AIPersonalizationScreen extends StatefulWidget {
//   const AIPersonalizationScreen({Key? key}) : super(key: key);

//   @override
//   State<AIPersonalizationScreen> createState() =>
//       _AIPersonalizationScreenState();
// }

// class _AIPersonalizationScreenState extends State<AIPersonalizationScreen> {
//   bool _useDataToImproveAI = true;

//   void _showClearMemoryDialog(BuildContext context) async {
//     final confirmed = await ClearMemoryPopup.show(context);
//     if (confirmed == true) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('AI Memory cleared successfully'),
//           backgroundColor: Color(0xFFE53935),
//         ),
//       );
//     }
//   }

//   static void show(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => const VoiceSelectorPopup(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF4C3EDD),
//       body: Column(
//         children: [
//           // Header
//           SafeArea(
//             bottom: false,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: Image.asset(
//                       Assets.svgIcons.settingsBackIcon.path,
//                       width: 32,
//                       height: 32,
//                       // color: Colors.white,
//                     ),
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     'AI PERSONALIZATION',
//                     style: AppsTextStyles.kSettingsTitleStyle,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // White card container
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.all(20),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(24),
//                   topRight: Radius.circular(24),
//                 ),
//               ),
//               child: ListView(
//                 children: [
//                   _buildMenuItem(
//                     iconWidget: Image.asset(
//                       Assets.svgIcons.voicePersonality.path,
//                       width: 40,
//                       height: 40,
//                     ),
//                     title: 'Voice & Personality',
//                     onTap: () async {
//                       final selectedVoice = await VoiceSelectorPopup.show(
//                         context,
//                       );
//                       if (selectedVoice != null) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Selected: $selectedVoice')),
//                         );
//                       }
//                     },
//                     hasArrow: true,
//                   ),
//                   const SizedBox(height: 12),
//                   _buildMenuItem(
//                     iconWidget: Image.asset(
//                       Assets.svgIcons.restrictedTopics.path,
//                       width: 40,
//                       height: 40,
//                     ),
//                     title: 'Restricted Topics',
//                     onTap: () async {
//                       final selectedTopics = await RestrictedTopicsPopup.show(
//                         context,
//                       );
//                       if (selectedTopics != null) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Selected ${selectedTopics.length} topics',
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     hasArrow: true,
//                   ),
//                   const SizedBox(height: 12),
//                   _buildMenuItem(
//                     iconWidget: Image.asset(
//                       Assets.svgIcons.useMyDataToImproveAI.path,
//                       width: 40,
//                       height: 40,
//                     ),
//                     title: 'Use My Data to\nImprove AI',
//                     hasSwitch: true,
//                     switchValue: _useDataToImproveAI,
//                     onSwitchChanged: (value) {
//                       setState(() {
//                         _useDataToImproveAI = value;
//                       });
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   _buildMenuItem(
//                     iconWidget: Image.asset(
//                       Assets.svgIcons.clearAllAIMemoryPng.path,
//                       width: 40,
//                       height: 40,
//                     ),
//                     title: 'Clear All AI Memory',
//                     onTap: () => _showClearMemoryDialog(context),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuItem({
//     IconData? icon,
//     Widget? iconWidget,
//     required String title,
//     VoidCallback? onTap,
//     bool hasArrow = false,
//     bool hasSwitch = false,
//     bool switchValue = false,
//     ValueChanged<bool>? onSwitchChanged,
//     Color? iconColor,
//     Color? titleColor,
//   }) {
//     final defaultColor = const Color(0xFF1E3A8A);
//     final effectiveIconColor = iconColor ?? defaultColor;
//     final effectiveTitleColor = titleColor ?? defaultColor;

//     Widget content = Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8F9FA),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Row(
//         children: [
//           // Icon
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: iconColor != null
//                   ? const Color(0xFFFFE5E5)
//                   : const Color(0xFFE8E9F3),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child:
//                 iconWidget ?? Icon(icon!, color: effectiveIconColor, size: 22),
//           ),
//           const SizedBox(width: 12),

//           // Title
//           Expanded(child: Text(title, style: AppsTextStyles.textDefaultStyle)),

//           // Trailing widget
//           if (hasArrow)
//             Icon(
//               Icons.arrow_forward_ios,
//               color: Colors.grey.shade400,
//               size: 16,
//             ),
//           if (hasSwitch)
//             Switch(
//               value: switchValue,
//               onChanged: onSwitchChanged,
//               activeColor: Colors.white,
//               activeTrackColor: const Color(0xFF4C3EDD),
//               inactiveThumbColor: Colors.white,
//               inactiveTrackColor: const Color(0xFFD1D5DB),
//             ),
//         ],
//       ),
//     );

//     if (onTap != null) {
//       return Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: content,
//         ),
//       );
//     }

//     return content;
//   }

//   void _navigateTo(BuildContext context, String page) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text('Opening $page')));
//   }
// }
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/screen/settings/api_personalization_screen/clear_memory_popup/clear_memory_popup.dart';
import 'package:nowlii/screen/settings/api_personalization_screen/restricted_topics_popup/restricted_topiccs_popup.dart';
import 'package:nowlii/screen/settings/api_personalization_screen/voice_selector_popup/voice_selector_popup.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class AIPersonalizationScreen extends StatefulWidget {
  const AIPersonalizationScreen({super.key});

  @override
  State<AIPersonalizationScreen> createState() =>
      _AIPersonalizationScreenState();
}

class _AIPersonalizationScreenState extends State<AIPersonalizationScreen> {
  bool _useDataToImproveAI = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useDataToImproveAI = prefs.getBool('ai_use_data_to_improve') ?? true;
    });
  }

  Future<void> _saveUseDataSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_use_data_to_improve', value);
  }

  void _showClearMemoryDialog(BuildContext context) async {
    final confirmed = await ClearMemoryPopup.show(context);
    if (confirmed == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Memory cleared successfully'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

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
                  Expanded(
                    child: Text(
                      'AI PERSONALIZATION',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppsTextStyles.kSettingsTitleStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // White card container
          Expanded(
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
                  _buildMenuItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.voicePersonality.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Voice & Personality',
                    onTap: () async {
                      final selectedVoice = await VoiceSelectorPopup.show(
                        context,
                      );
                      if (selectedVoice != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Selected: $selectedVoice')),
                          );
                        }
                      }
                    },
                    hasArrow: true,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.restrictedTopics.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Restricted Topics',
                    onTap: () async {
                      final selectedTopics = await RestrictedTopicsPopup.show(
                        context,
                      );
                      if (selectedTopics != null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Selected ${selectedTopics.length} topics',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    hasArrow: true,
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.useMyDataToImproveAI.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Use My Data to\nImprove AI',
                    hasSwitch: true,
                    switchValue: _useDataToImproveAI,
                    onSwitchChanged: (value) {
                      if (!mounted) return;
                      setState(() {
                        _useDataToImproveAI = value;
                      });
                      _saveUseDataSetting(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    iconWidget: Image.asset(
                      Assets.svgIcons.clearAllAIMemoryPng.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Clear All AI Memory',
                    onTap: () => _showClearMemoryDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    VoidCallback? onTap,
    bool hasArrow = false,
    bool hasSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
    Color? iconColor,
  }) {
    final defaultColor = const Color(0xFF1E3A8A);
    final effectiveIconColor = iconColor ?? defaultColor;

    Widget content = Container(
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
              color: iconColor != null
                  ? const Color(0xFFFFE5E5)
                  : const Color(0xFFE8E9F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                iconWidget ?? Icon(icon!, color: effectiveIconColor, size: 22),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(child: Text(title, style: AppsTextStyles.textDefaultStyle)),

          // Trailing widget
          if (hasArrow)
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          if (hasSwitch)
            Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF4542EB),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFB0B0B0),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: content,
        ),
      );
    }

    return content;
  }
}
