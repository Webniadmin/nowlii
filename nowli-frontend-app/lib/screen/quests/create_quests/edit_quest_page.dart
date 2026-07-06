import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/custom_code/bottom_nav.dart';
import 'package:nowlii/screen/quests/create_quests/_buildInputCard/input_widget_card.dart';
import 'package:nowlii/screen/quests/create_quests/buildAddSubtasksButton/build_add_subtask_button.dart';
import 'package:nowlii/screen/quests/create_quests/buildTitle/edit_title_widget.dart';
import 'package:nowlii/screen/quests/create_quests/enable_card/enable_card.dart';
import 'package:nowlii/screen/quests/create_quests/repeat_quest_card/repeat_quest_card.dart';
import 'package:nowlii/screen/quests/create_quests/select_zone_card/select_zone_card.dart';
import 'package:nowlii/screen/quests/create_quests/time_picker_card/time_picker_card.dart';
import 'package:nowlii/screen/quests/create_quests/when_card/when_card.dart';
import 'package:nowlii/services/quest_service.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class EditQuestPage extends StatefulWidget {
  final Map<String, dynamic>? taskData;
  final int? taskId;

  const EditQuestPage({
    super.key,
    this.taskData,
    this.taskId,
  });

  @override
  State<EditQuestPage> createState() => _EditQuestPageState();
}

class _EditQuestPageState extends State<EditQuestPage> {
  bool showSubtaskGenerator = false;
  bool showDesignScreen = false;
  bool showDateSelectionScreen = false;
  
  // Form state
  final TextEditingController _taskController = TextEditingController();
  String? selectedZone;
  DateTime selectedDate = DateTime.now();
  String? selectedTime; // Add time state
  bool enableCall = true;
  bool repeatQuest = true;
  List<String> subtasks = [];
  bool _isUpdating = false;
  
  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Pre-fill data if available
    if (widget.taskData != null) {
      _taskController.text = widget.taskData?['title'] ?? '';
      selectedZone = widget.taskData?['zone'];
      enableCall = widget.taskData?['enableCall'] ?? true;
      repeatQuest = widget.taskData?['repeatQuest'] ?? true;
      selectedTime = widget.taskData?['time']; // Load existing time
      
      // Parse date if available
      if (widget.taskData?['selectADate'] != null) {
        try {
          selectedDate = DateTime.parse(widget.taskData!['selectADate']);
        } catch (e) {
          selectedDate = DateTime.now();
        }
      }
      
      // Load subtasks if available
      if (widget.taskData?['subtasks'] != null) {
        final List<dynamic> subtasksList = widget.taskData!['subtasks'];
        subtasks = subtasksList.map((s) => s['title'].toString()).toList();
      }
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    _speech.stop();
    super.dispose();
  }
  
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
        setState(() => _isListening = false);
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
  }
  
  Future<void> _startListening() async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice input'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    setState(() => _isListening = true);
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _taskController.text = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );
  }
  
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }
  
  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _handleUpdateQuest() async {
    // Validation
    if (_taskController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quest title')),
      );
      return;
    }

    if (selectedZone == null || selectedZone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a zone')),
      );
      return;
    }

    if (widget.taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quest ID is missing')),
      );
      return;
    }

    setState(() => _isUpdating = true);

    final questService = QuestService();
    
    // Prepare subtasks
    List<Map<String, dynamic>>? subtasksList;
    if (subtasks.isNotEmpty) {
      subtasksList = subtasks.map((title) => {
        'title': title,
        'task_done': false,
      }).toList();
    }

    final updatedQuest = await questService.updateQuest(
      questId: widget.taskId!,
      task: _taskController.text.trim(),
      zone: selectedZone!,
      selectADate: DateFormat('yyyy-MM-dd').format(selectedDate),
      selectATime: selectedTime, // Pass time to backend
      enableCall: enableCall,
      repeatQuest: repeatQuest,
      setAlarm: true,
      subtasks: subtasksList,
    );

    setState(() => _isUpdating = false);

    if (updatedQuest != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quest updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Return true to indicate quest was updated successfully
      context.pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update quest. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                  EditTitleWidget(
                    onMicPressed: _toggleListening,
                    isListening: _isListening,
                  ),
                  SizedBox(height: 14 * baseScale),
                  InputCardWidget(
                    controller: _taskController,
                  ),
                  SizedBox(height: 12 * baseScale),
                  AddSubtasksButton(
                    questController: _taskController,
                    onSubtasksChanged: (List<String> newSubtasks) {
                      setState(() => subtasks = newSubtasks);
                    },
                  ),
                  SizedBox(height: 12 * baseScale),
                  SelectZoneCard(
                    initialZone: selectedZone,
                    onZoneSelected: (String? zone) {
                      setState(() => selectedZone = zone);
                    },
                  ),
                  SizedBox(height: 12 * baseScale),
                  WhenCard(
                    onDateSelected: (String option, DateTime date) {
                      setState(() => selectedDate = date);
                    },
                  ),
                  SizedBox(height: 12 * baseScale),
                  TimePickerCard(
                    initialTime: widget.taskData?['time'],
                    onTimeSelected: (String time) {
                      setState(() => selectedTime = time);
                    },
                  ),
                  SizedBox(height: 12 * baseScale),
                  EnableCallCard(
                    initialValue: enableCall,
                    onCallEnabledChanged: (bool value) {
                      setState(() => enableCall = value);
                    },
                  ),
                  SizedBox(height: 12 * baseScale),
                  RepeatQuestCard(
                    initialValue: repeatQuest,
                    onRepeatChanged: (bool value) {
                      setState(() => repeatQuest = value);
                    },
                  ),
                  SizedBox(
                    height: 130 * baseScale,
                  ), // Extra space for fixed button
                ],
              ),
            ),

            // Fixed Update Quest Button at bottom
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
                    Positioned(
                      left: 0,
                      top: 74,
                      child: SizedBox(
                        width: width,
                        height: 34,
                        child: Stack(
                          children: [
                            Positioned(
                              left: (width - 134) / 2,
                              top: 21,
                              child: Container(
                                width: 134,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFDF7),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

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
                            GestureDetector(
                              onTap: _handleUpdateQuest,
                              child: Container(
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
                                child: _isUpdating
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF011F54),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Update Quest',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.workSans(
                                          color: const Color(0xFF011F54),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          height: 0.80,
                                        ),
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
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation tap
        },
      ),
    );
  }
}
