import 'package:flutter/material.dart';
import 'package:nowlii/themes/create_qutes.dart';

class EnableCallCard extends StatefulWidget {
  final double scale;
  final Function(bool)? onCallEnabledChanged;
  final bool? initialValue;

  const EnableCallCard({
    super.key, 
    this.scale = 1.0, 
    this.onCallEnabledChanged,
    this.initialValue,
  });

  @override
  State<EnableCallCard> createState() => _EnableCallCardState();
}

class _EnableCallCardState extends State<EnableCallCard> {
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
                  widget.onCallEnabledChanged?.call(newValue);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF4542EB),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFB0B0B0),
              ),
              Text('ENABLE CALL', style: AppTextStylesQutes.workSansBlack24),
            ],
          ),
          SizedBox(height: 10 * s),
          // Description + switch
          Row(
            children: [
              Expanded(
                child: Text(
                  'A real-time 10-min support call will help you stay on track.',
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
