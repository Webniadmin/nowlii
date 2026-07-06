import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';

/////////////////////////////////////////////////////////////////////
/// QUEST LIST + TASK CARD
//////////////////////////////////////////////////////////////////////

List<Map<String, dynamic>> quests = [
  {
    "emoji": "🧹",
    "title": "Clean house",
    "levelText": "Soft steps",
    "levelColor": Color(0xFFA0E871),
    "time": "22:00",
    "duration": "10 mins",
  },
  // {
  //   "emoji": "📘",
  //   "title": "Do homework",
  //   "levelText": "Elevated",
  //   "levelColor": Color(0xFFF7A94B),
  //   "time": "22:00",
  //   "duration": "10 mins",
  // },
  // {
  //   "emoji": "🍽️",
  //   "title": "Do dishes",
  //   "levelText": "Stretch zone",
  //   "levelColor": Color(0xFF6AA7FF),
  //   "time": "22:00",
  //   "duration": "10 mins",
  // },
  // {
  //   "emoji": "🏋️",
  //   "title": "Workout",
  //   "levelText": "Power move",
  //   "levelColor": Color(0xFFFF5A5A),
  //   "time": "22:00",
  //   "duration": "10 mins",
  // },
];

class QuestList extends StatelessWidget {
  const QuestList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: quests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = quests[index];
        return TaskCard(
          emoji: item['emoji'],
          title: item['title'],
          levelText: item['levelText'],
          levelColor: item['levelColor'],
          time: item['time'],
          duration: item['duration'],
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////////////
/// TASK CARD
//////////////////////////////////////////////////////////////////////

class TaskCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String levelText;
  final Color levelColor;
  final String time;
  final String duration;

  const TaskCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.levelText,
    required this.levelColor,
    required this.time,
    required this.duration,
  });

  static const String uploadedImagePath =
      '/mnt/data/ec55cb33-aecd-4f73-acee-b8bf326d88b9.png';

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool isCompleted = true;

  Color _getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _showPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Popup',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, __, ___) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return Align(
          alignment: Alignment.bottomCenter,
          // 24 px left/right padding and 20 px space from bottom
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: Material(
                borderRadius: BorderRadius.circular(14),

                /*  */
                // color: Colors.white,
                color: AppColorsApps.skyBlueLight,
                elevation: 8,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Repeat this quest?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Icon(Icons.calendar_today, size: 18),
                          SizedBox(width: 8),
                          Text('Tomorrow'),
                          Spacer(),
                          Icon(Icons.check_circle, size: 18),
                          SizedBox(width: 6),
                          Text('22:00'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Edit time'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4C4CE6), // Blue color
                                borderRadius: BorderRadius.circular(
                                  25,
                                ), // Rounded corners
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Yes',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ), // White text color
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF4DCC9), width: 1),
      ),
      elevation: 0,
      color: Color(0xFFFFFCF1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CLICKABLE TOP ROW
            GestureDetector(
              onTap: () {
                setState(() {
                  isCompleted = !isCompleted;
                });
              },
              child: Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: const Color(0xFF4C4CE6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted ? 'Completed' : 'Not completed',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4542EB), // Text-text-primary
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.40,
                      letterSpacing: -0.50,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFE0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.repeat, color: Color(0xFF5A4C4C)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // TITLE ROW
            Row(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppsTextStyles.regularResponsive(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // TIME + DATE
            Row(
              children: [
                Image.asset(Assets.images.today.path, height: 20, width: 20),
                const SizedBox(width: 10),
                Text(
                  "Today",
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 20),
                Image.asset(Assets.images.clock1.path, height: 20, width: 20),
                const SizedBox(width: 10),
                Text(
                  widget.time,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // CHIPS
           Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Level Tag
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: ShapeDecoration(
                  color: widget.levelColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.levelText,
                  style: GoogleFonts.workSans(
                    color: _getTextColor(widget.levelColor),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.40,
                    letterSpacing: -0.40,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Duration Tag
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFAE3CE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.duration,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -0.40,
                  ),
                ),
              ),
            ],
          ),

            const SizedBox(height: 16),

            // OPTIONAL IMAGE
            Builder(
              builder: (_) {
                try {
                  final file = File(TaskCard.uploadedImagePath);
                  if (file.existsSync()) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                } catch (_) {}
                return const SizedBox.shrink();
              },
            ),

            // BUTTON
            Center(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _showPopup(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF4542EB), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'See reflection',
                    style: AppsTextStyles.workSansBlack18CenterBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
