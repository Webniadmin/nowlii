import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart';
import 'package:nowlii/services/subtask_service.dart';

class AddSubtasksButton extends StatefulWidget {
  final double scale;
  final Function(List<String>)? onSubtasksChanged;
  final TextEditingController? questController; // Quest text controller

  const AddSubtasksButton({
    super.key, 
    this.scale = 1.0, 
    this.onSubtasksChanged,
    this.questController,
  });

  @override
  State<AddSubtasksButton> createState() => _AddSubtasksButtonState();
}

class _AddSubtasksButtonState extends State<AddSubtasksButton> {
  bool showSubtaskGenerator = false;
  bool showGeneratedSubtasks = false;
  bool isGenerating = false;

  // Generated subtasks from API
  List<String> generatedSubtasks = [];

  // Chosen/selected subtasks
  final List<String> chosenSubtasks = [];
  
  final SubtaskService _subtaskService = SubtaskService();

  void _notifyParent() {
    widget.onSubtasksChanged?.call(chosenSubtasks);
  }

  Future<void> _onGenerateSubtasks() async {
    // Get quest text from controller
    final questText = widget.questController?.text.trim() ?? '';
    
    // Validate quest text
    if (questText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write down your quest first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isGenerating = true;
    });

    try {
      final subtasks = await _subtaskService.generateSubtasks(questText);
      
      if (subtasks != null && subtasks.isNotEmpty) {
        setState(() {
          generatedSubtasks = subtasks;
          showGeneratedSubtasks = true;
          isGenerating = false;
        });
      } else {
        setState(() {
          isGenerating = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate subtasks. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isGenerating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onToggleSubtask(String subtask) {
    setState(() {
      if (chosenSubtasks.contains(subtask)) {
        chosenSubtasks.remove(subtask);
      } else {
        chosenSubtasks.add(subtask);
      }
    });
    _notifyParent();
  }

  void _onDeselectAll() {
    setState(() {
      chosenSubtasks.clear();
    });
    _notifyParent();
  }

  void _onRefreshGenerate() {
    // Re-generate subtasks with API call
    _onGenerateSubtasks();
  }

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
                    child: Icon(
                      showSubtaskGenerator ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 20 * s,
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
                onTap: isGenerating ? null : _onGenerateSubtasks,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14 * s),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isGenerating 
                        ? const Color(0xFFB3C6E6) 
                        : const Color(0xFFA9A8F6),
                    ),
                    borderRadius: BorderRadius.circular(25 * s),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isGenerating)
                        SizedBox(
                          height: 20 * s,
                          width: 20 * s,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF4542EB),
                            ),
                          ),
                        )
                      else
                        Image.asset(
                          Assets.svgIcons.star.path,
                          height: 20 * s,
                          width: 20 * s,
                        ),
                      SizedBox(width: 8 * s),
                      Text(
                        isGenerating ? "Generating..." : "Generate subtasks",
                        style: AppTextStylesQutes.workSansBlack18.copyWith(
                          color: isGenerating 
                            ? const Color(0xFFB3C6E6) 
                            : const Color(0xFF011F54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Generated subtasks section ---
            if (showGeneratedSubtasks) ...[
              SizedBox(height: 16 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                child: Row(
                  children: [
                    Text(
                      'Generated subtasks',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54), // Text-text-default
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.20,
                        letterSpacing: -0.50,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _onRefreshGenerate,
                      child: Container(
                        width: 28 * s,
                        height: 28 * s,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6E4FF),
                          borderRadius: BorderRadius.circular(8 * s),
                        ),
                        child: Image.asset(
                          Assets.images.cleanWindowsRefers.path,
                          height: 24 * s,
                          width: 24 * s,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * s),
                child: Wrap(
                  spacing: 8 * s,
                  runSpacing: 8 * s,
                  children: generatedSubtasks.map((subtask) {
                    final isSelected = chosenSubtasks.contains(subtask);
                    return GestureDetector(
                      onTap: () => _onToggleSubtask(subtask),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * s,
                          vertical: 10 * s,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF4542EB)
                              : const Color(0xFFE6F0FF),
                          borderRadius: BorderRadius.circular(25 * s),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4542EB)
                                : const Color(0xFFB3C6E6),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              Assets.images.cleanKitchen.path,
                              height: 18 * s,
                              width: 18 * s,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4542EB),
                            ),
                            SizedBox(width: 6 * s),
                            Text(
                              subtask,
                              style: GoogleFonts.workSans(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF4542EB),
                                // color: const Color(
                                //   0xFF4542EB,
                                // ), // Text-text-primary
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 0.80,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // --- Chosen section ---
              if (chosenSubtasks.isNotEmpty) ...[
                SizedBox(height: 16 * s),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s),
                  child: Row(
                    children: [
                      Text(
                        'Choosen',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54), // Text-text-default
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.20,
                          letterSpacing: -0.50,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _onDeselectAll,
                        child: Row(
                          children: [
                            Image.asset(
                              Assets.images.deselectAll.path,
                              height: 16 * s,
                              width: 16 * s,
                            ),
                            SizedBox(width: 4 * s),
                            Text(
                              'Deselect all',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.workSans(
                                color: const Color(
                                  0xFF4542EB,
                                ), // Text-text-primary
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 0.80,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10 * s),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16 * s),
                  child: Wrap(
                    spacing: 8 * s,
                    runSpacing: 8 * s,
                    children: chosenSubtasks.map((subtask) {
                      return GestureDetector(
                        onTap: () => _onToggleSubtask(subtask),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * s,
                            vertical: 10 * s,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4542EB),
                            borderRadius: BorderRadius.circular(25 * s),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                Assets.images.checkCircle.path,
                                height: 18 * s,
                                width: 18 * s,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6 * s),
                              Text(
                                subtask,
                                style: GoogleFonts.workSans(
                                  color: const Color(
                                    0xFFFFFDF7,
                                  ), // Text-text-light
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 0.80,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              SizedBox(height: 12 * s),
            ],

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
