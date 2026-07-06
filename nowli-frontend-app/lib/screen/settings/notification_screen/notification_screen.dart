// import 'package:flutter/material.dart';
// import 'package:nowlii/themes/text_styles.dart';

// class NotificationsScreen extends StatefulWidget {
//   const NotificationsScreen({Key? key}) : super(key: key);

//   @override
//   State<NotificationsScreen> createState() => _NotificationsScreenState();
// }

// class _NotificationsScreenState extends State<NotificationsScreen> {
//   final Map<String, bool> _notifications = {
//     'Task Reminders': true,
//     'Daily Tips': true,
//     'Nowlli Check-ins': true,
//     'Streak Progress': true,
//     'AI Insights & Reflections': true,
//   };

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF4F46E5),
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
//                     icon: const Icon(Icons.arrow_back, color: Colors.white),
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     'NOTIFICATIONS',
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
//               // margin: const EdgeInsets.symmetric(horizontal: 16),
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
//                   _buildNotificationTile(
//                     icon: Icons.check_box_rounded,
//                     title: 'Task Reminders',
//                     key: 'Task Reminders',
//                   ),
//                   const SizedBox(height: 12),
//                   _buildNotificationTile(
//                     icon: Icons.lightbulb_rounded,
//                     title: 'Daily Tips',
//                     key: 'Daily Tips',
//                   ),
//                   const SizedBox(height: 12),
//                   _buildNotificationTile(
//                     icon: Icons.sentiment_satisfied_rounded,
//                     title: 'Nowlli Check-ins',
//                     key: 'Nowlli Check-ins',
//                   ),
//                   const SizedBox(height: 12),
//                   _buildNotificationTile(
//                     icon: Icons.bar_chart_rounded,
//                     title: 'Streak Progress',
//                     key: 'Streak Progress',
//                   ),
//                   const SizedBox(height: 12),
//                   _buildNotificationTile(
//                     icon: Icons.auto_fix_high_rounded,
//                     title: 'AI Insights &\nReflections',
//                     key: 'AI Insights & Reflections',
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationTile({
//     required IconData icon,
//     required String title,

//     required String key,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
//               color: const Color(0xFFE8E9F3),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
//           ),
//           const SizedBox(width: 12),

//           // Title
//           Expanded(
//             child: Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF1E3A8A),
//                 height: 1.2,
//               ),
//             ),
//           ),

//           // Toggle Switch
//           Switch(
//             value: _notifications[key] ?? false,
//             onChanged: (value) {
//               setState(() {
//                 _notifications[key] = value;
//               });
//             },
//             activeThumbColor: Colors.white,
//             activeTrackColor: const Color(0xFF4F46E5),
//             inactiveThumbColor: Colors.white,
//             inactiveTrackColor: const Color(0xFFD1D5DB),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> _notifications = {
    'Task Reminders': true,
    'Daily Tips': true,
    'Nowlli Check-ins': true,
    'Streak Progress': true,
    'AI Insights & Reflections': true,
  };

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications['Task Reminders'] = 
          prefs.getBool('notif_task_reminders') ?? true;
      _notifications['Daily Tips'] = 
          prefs.getBool('notif_daily_tips') ?? true;
      _notifications['Nowlli Check-ins'] = 
          prefs.getBool('notif_nowlli_checkins') ?? true;
      _notifications['Streak Progress'] = 
          prefs.getBool('notif_streak_progress') ?? true;
      _notifications['AI Insights & Reflections'] = 
          prefs.getBool('notif_ai_insights') ?? true;
    });
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    String prefKey = '';
    switch (key) {
      case 'Task Reminders':
        prefKey = 'notif_task_reminders';
        break;
      case 'Daily Tips':
        prefKey = 'notif_daily_tips';
        break;
      case 'Nowlli Check-ins':
        prefKey = 'notif_nowlli_checkins';
        break;
      case 'Streak Progress':
        prefKey = 'notif_streak_progress';
        break;
      case 'AI Insights & Reflections':
        prefKey = 'notif_ai_insights';
        break;
    }
    if (prefKey.isNotEmpty) {
      await prefs.setBool(prefKey, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
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
                    'NOTIFICATIONS',
                    style: AppsTextStyles.kSettingsTitleStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // White card container
          Flexible(
            child: Container(
              // margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  _buildNotificationTile(
                    iconWidget: Image.asset(
                      Assets.svgIcons.taslReminders.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Task Reminders',
                    key: 'Task Reminders',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationTile(
                    iconWidget: Image.asset(
                      Assets.svgIcons.dailyTips.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Daily Tips',
                    key: 'Daily Tips',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationTile(
                    iconWidget: Image.asset(
                      Assets.svgIcons.nowlliCheckIns.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Nowlli Check-ins',
                    key: 'Nowlli Check-ins',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationTile(
                    iconWidget: Image.asset(
                      Assets.svgIcons.streakProgress.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'Streak Progress',
                    key: 'Streak Progress',
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationTile(
                    iconWidget: Image.asset(
                      Assets.svgIcons.aIInsightsReflections.path,
                      width: 40,
                      height: 40,
                    ),
                    title: 'AI Insights &\nReflections',
                    key: 'AI Insights & Reflections',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required String key,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E9F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                iconWidget ??
                Icon(icon!, color: const Color(0xFF1E3A8A), size: 22),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(child: Text(title, style: AppsTextStyles.textDefaultStyle)),

          // Toggle Switch
          Switch(
            value: _notifications[key] ?? false,
            onChanged: (value) {
              setState(() {
                _notifications[key] = value;
              });
              _saveNotificationSetting(key, value);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF4542EB),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFB0B0B0),
          ),
        ],
      ),
    );
  }
}
