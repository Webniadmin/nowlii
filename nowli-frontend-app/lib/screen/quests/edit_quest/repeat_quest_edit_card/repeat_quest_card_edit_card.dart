import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/themes/create_qutes.dart';

class RepeatQuestCardEditCard extends StatefulWidget {
  final double scale;

  const RepeatQuestCardEditCard({super.key, this.scale = 1.0});

  @override
  State<RepeatQuestCardEditCard> createState() =>
      _RepeatQuestCardEditCardState();
}

class _RepeatQuestCardEditCardState extends State<RepeatQuestCardEditCard> {
  bool isRepeatQuestEnabled = false;

  @override
  Widget build(BuildContext context) {
    double s = widget.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFDFEFFF),
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with switch and title
          Row(
            children: [
              Transform.scale(
                scale: s,
                child: Switch(
                  value: isRepeatQuestEnabled,
                  onChanged: (value) {
                    setState(() {
                      isRepeatQuestEnabled = value;
                    });
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF4542EB),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFB0B0B0),
                ),
              ),
              SizedBox(width: 4 * s),
              Text('REPEAT QUEST', style: AppTextStylesQutes.workSansBlack24),
            ],
          ),
          SizedBox(height: 8 * s),
          // Description
          Padding(
            padding: EdgeInsets.only(left: 4 * s),
            child: Text(
              'Turn this on to repeat the quest daily, weekly or on custom days.',
              style: GoogleFonts.workSans(
                color: const Color(0xFF4C586E), // Text-text-primary-default
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.40,
                letterSpacing: -0.50,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
