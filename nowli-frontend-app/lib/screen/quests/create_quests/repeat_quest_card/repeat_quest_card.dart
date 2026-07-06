import 'package:flutter/material.dart';
import 'package:nowlii/themes/create_qutes.dart';

class RepeatQuestCard extends StatefulWidget {
  final double scale;
  final Function(bool)? onRepeatChanged;
  final bool? initialValue;

  const RepeatQuestCard({
    super.key, 
    this.scale = 1.0, 
    this.onRepeatChanged,
    this.initialValue,
  });

  @override
  State<RepeatQuestCard> createState() => _RepeatQuestCardState();
}

class _RepeatQuestCardState extends State<RepeatQuestCard> {
  bool isCallEnabled = true;

  @override
  void initState() {
    super.initState();
    isCallEnabled = widget.initialValue ?? true;
  }

  @override
  Widget build(BuildContext context) {
    double s = widget.scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * s),
      decoration: BoxDecoration(
        color: Color(0xFFDFEFFF),
        borderRadius: BorderRadius.circular(12 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Switch(
                value: isCallEnabled,
                onChanged: (bool newValue) {
                  setState(() {
                    isCallEnabled = newValue;
                  });
                  widget.onRepeatChanged?.call(newValue);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF4542EB),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFB0B0B0),
              ),
              Text('REPEAT QUEST', style: AppTextStylesQutes.workSansBlack24),
            ],
          ),
          SizedBox(height: 10 * s),
          // Description + switch
          Row(
            children: [
              Expanded(
                child: Text(
                  'Turn this on to repeat the quest daily or weekly.',
                  style: AppTextStylesQutes.workSansRegular16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
