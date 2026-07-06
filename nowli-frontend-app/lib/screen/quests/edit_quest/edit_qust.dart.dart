import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/screen/quests/create_quests/_buildInputCard/input_widget_card.dart';
import 'package:nowlii/screen/quests/create_quests/buildAddSubtasksButton/build_add_subtask_button.dart';
import 'package:nowlii/screen/quests/create_quests/buildTitle/title_widget.dart';
import 'package:nowlii/screen/quests/create_quests/select_zone_card/select_zone_card.dart';
import 'package:nowlii/screen/quests/create_quests/when_card/when_card.dart';
import 'package:nowlii/screen/quests/edit_quest/enable_card_edit/enable_card_edit.dart';
import 'package:nowlii/screen/quests/edit_quest/repeat_quest_edit_card/repeat_quest_card_edit_card.dart';
import 'package:nowlii/themes/create_qutes.dart';

class EditQuestPage extends StatefulWidget {
  const EditQuestPage({super.key});

  @override
  State<EditQuestPage> createState() => _EditQuestPageState();
}

class _EditQuestPageState extends State<EditQuestPage> {
  bool showSubtaskGenerator = false;
  bool showDesignScreen = false;
  bool showDateSelectionScreen = false;
  String? selectedZone;
  bool isCallEnabled = true;
  bool isSetAlarmEnabled = false;

  String selectedDateOption = 'Today';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final baseScale = width / 390.0;

    return Scaffold(
      backgroundColor: Color(0xFF89B6F8),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 16.0 * baseScale,
                vertical: 12.0 * baseScale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10 * baseScale),
                  TitleWidget(),
                  SizedBox(height: 14 * baseScale),
                  InputCardWidget(),
                  SizedBox(height: 12 * baseScale),
                  AddSubtasksButton(),
                  SizedBox(height: 12 * baseScale),
                  SelectZoneCard(),
                  SizedBox(height: 12 * baseScale),
                  WhenCard(),
                  SizedBox(height: 12 * baseScale),

                  SizedBox(height: 12 * baseScale),
                  _buildTimeDisplayCard(baseScale),
                  SizedBox(height: 12 * baseScale),
                  EnabableCardEdit(),
                  SizedBox(height: 12 * baseScale),
                  RepeatQuestCardEditCard(),
                  SizedBox(height: 12 * baseScale),

                  _buildSetAlarmCard(baseScale),
                  SizedBox(
                    height: 130 * baseScale,
                  ), // Extra space for fixed button
                ],
              ),
            ),

            // Fixed Create Quest Button at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                width: width,
                height: 108,
                child: Stack(
                  children: [
                    /// Bottom rounded bar

                    /// Button
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: width,
                        padding: const EdgeInsets.only(
                          top: 12,
                          left: 20,
                          right: 20,
                          bottom: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 64,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8F26),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Save',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF011F54),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 0.80,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // DesignScreen Overlay
            if (showDesignScreen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showDesignScreen = false;
                    });
                  },
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: const DesignScreen(),
                      ),
                    ),
                  ),
                ),
              ),

            // DateSelectionScreen Overlay
            if (showDateSelectionScreen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showDateSelectionScreen = false;
                    });
                  },
                  child: Container(
                    color: Colors.black38,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: DateSelectionScreen(
                          onDateSelected: (day, weekday) {
                            setState(() {
                              selectedDateOption = '$weekday, Jan $day';
                              showDateSelectionScreen = false;
                            });
                          },
                          onClose: () {
                            setState(() {
                              showDateSelectionScreen = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplayCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF1),
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Row(
        children: [
          Image.asset(
            Assets.images.clock.path,
            height: 24 * s,
            width: 24 * s,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 8 * s),
          Text('22:00', style: AppTextStylesQutes.workSansBlack24),
        ],
      ),
    );
  }

  Widget _buildSetAlarmCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFDFEFFF),
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: s,
            child: Switch(
              value: isSetAlarmEnabled,
              onChanged: (value) {
                setState(() {
                  isSetAlarmEnabled = value;
                });
              },
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF4542EB),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFB0B0B0),
            ),
          ),
          SizedBox(width: 4 * s),
          // Alarm icon
          Image.asset(
            Assets.images.clock.path,
            height: 24 * s,
            width: 24 * s,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 8 * s),
          Text('SET ALARM', style: AppTextStylesQutes.workSansBlack24),
        ],
      ),
    );
  }
}
