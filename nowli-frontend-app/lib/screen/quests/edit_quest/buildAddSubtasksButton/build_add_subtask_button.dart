import 'package:flutter/material.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart';

class AddSubtasksButton extends StatefulWidget {
  final double scale;

  const AddSubtasksButton({super.key, this.scale = 1.0});

  @override
  State<AddSubtasksButton> createState() => _AddSubtasksButtonState();
}

class _AddSubtasksButtonState extends State<AddSubtasksButton> {
  bool showSubtaskGenerator = false;

  @override
  Widget build(BuildContext context) {
    double s = widget.scale;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6F0FF),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and add button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 8 * s),
            child: Row(
              children: [
                Image.asset(
                  Assets.svgIcons.arrow.path,
                  height: 20 * s,
                  width: 20 * s,
                ),
                SizedBox(width: 8 * s),
                Expanded(
                  child: Text(
                    'ADD SUBTASKS',
                    style: AppTextStylesQutes.workSansBlack24,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showSubtaskGenerator = !showSubtaskGenerator;
                    });
                  },
                  child: Container(
                    width: 32 * s,
                    height: 32 * s,
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(8 * s),
                    ),
                    child: Image.asset(
                      Assets.svgIcons.quests.path,
                      height: 20 * s,
                      width: 20 * s,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Expandable subtask generator section
          if (showSubtaskGenerator) ...[
            SizedBox(height: 12 * s),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * s),
              child: GestureDetector(
                onTap: () {
                  // Handle generate subtasks
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14 * s),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFA9A8F6)),
                    borderRadius: BorderRadius.circular(25 * s),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        Assets.svgIcons.star.path,
                        height: 20 * s,
                        width: 20 * s,
                      ),
                      SizedBox(width: 8 * s),
                      Text(
                        "Generate subtasks",
                        style: AppTextStylesQutes.workSansBlack18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12 * s),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * s),
              child: Container(
                padding: EdgeInsets.all(14 * s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12 * s),
                  border: Border.all(color: Colors.blue.shade100, width: 1.5),
                ),
                child: TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write subtask...',
                    hintStyle: AppTextStylesQutes.workSansExtraBold32,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTextStylesQutes.workSansSemiBold18,
                ),
              ),
            ),
            SizedBox(height: 12 * s),
          ],
        ],
      ),
    );
  }
}
