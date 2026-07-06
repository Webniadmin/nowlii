import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart';

class SelectZoneCard extends StatefulWidget {
  final double scale;
  final Function(String?)? onZoneSelected;
  final String? initialZone;

  const SelectZoneCard({
    super.key, 
    this.scale = 1.0, 
    this.onZoneSelected,
    this.initialZone,
  });

  @override
  State<SelectZoneCard> createState() => _SelectZoneCardState();
}

class _SelectZoneCardState extends State<SelectZoneCard> {
  String? selectedZone;
  bool showDesignScreen = false;

  final List<String> chips = [
    'Soft steps',
    'Elevated',
    'Stretch zone',
    'Power move',
  ];

  @override
  void initState() {
    super.initState();
    selectedZone = widget.initialZone;
    showDesignScreen = selectedZone == 'Soft steps';
  }

  @override
  Widget build(BuildContext context) {
    double s = widget.scale;

    return Column(
      children: [
        // Show DesignScreen at TOP when 'Soft steps' is selected
        if (showDesignScreen) ...[
          Padding(
            padding: EdgeInsets.only(
              top: 20 * s,
              left: 24 * s,
              right: 24 * s,
              bottom: 16 * s,
            ),
            child: const DesignScreen(),
          ),
        ],

        // Main Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12 * s),
          decoration: BoxDecoration(
            color: Color(0xFFDFEFFF),
            borderRadius: BorderRadius.circular(12 * s),
          ),
          child: Column(
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        Assets.svgIcons.graph.path,
                        height: 20 * s,
                        width: 20 * s,
                      ),
                      SizedBox(width: 8 * s),
                      Text(
                        'SELECT A ZONE',
                        style: AppTextStylesQutes.workSansBlack24,
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * s),
                  Text(
                    "Label how demanding this feels - \nit helps track your progress over time.",
                    style: AppTextStylesQutes.workSansRegular16,
                  ),
                ],
              ),
              SizedBox(height: 14 * s),
              // Chips in two rows
              Row(
                children: [
                  Expanded(child: _zoneChip(chips[0], s)),
                  SizedBox(width: 10 * s),
                  Expanded(child: _zoneChip(chips[1], s)),
                ],
              ),
              SizedBox(height: 10 * s),
              Row(
                children: [
                  Expanded(child: _zoneChip(chips[2], s)),
                  SizedBox(width: 10 * s),
                  Expanded(child: _zoneChip(chips[3], s)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _zoneChip(String label, double s) {
    bool isSelected = selectedZone == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedZone = label;
          showDesignScreen = label == 'Soft steps';
        });
        widget.onZoneSelected?.call(label);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF89B6F8) : Colors.white,
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(
            color: isSelected ? const Color(0xFF89B6F8) : Colors.blue.shade100,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStylesQutes.workSansSemiBold18.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF4C586E),
            fontSize: 16 * s,
          ),
        ),
      ),
    );
  }
}

class DesignScreen extends StatelessWidget {
  const DesignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("💡", style: TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Zones show how intense your quest feels. Pick what fits your energy today – we'll track your flow over time.",
                  style: AppTextStylesQutes.workSansSemiBosld18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const BulletText("Soft steps — Gentle & doable"),
          const BulletText("Elevated — Balanced and steady"),
          const BulletText("Stretch zone — A bit beyond your comfort"),
          const BulletText("Power move — Full focus, no distractions"),
        ],
      ),
    );
  }
}

class BulletText extends StatelessWidget {
  final String text;
  const BulletText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(text, style: AppTextStylesQutes.workSansRegular14),
          ),
        ],
      ),
    );
  }
}
