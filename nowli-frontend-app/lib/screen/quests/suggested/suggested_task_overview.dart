import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/create_qutes.dart';
import 'package:nowlii/models/quest_suggestion_model.dart';
import 'package:nowlii/services/quest_service.dart';
import 'package:intl/intl.dart';

class SuggestedTaskOverview extends StatefulWidget {
  final QuestSuggestion? suggestion;
  
  const SuggestedTaskOverview({super.key, this.suggestion});

  @override
  State<SuggestedTaskOverview> createState() => _SuggestedTaskOverviewState();
}

class _SuggestedTaskOverviewState extends State<SuggestedTaskOverview> {
  final QuestService _questService = QuestService();
  bool isCallEnabled = true;
  bool isRepeatQuestEnabled = true;
  bool isSetAlarmEnabled = true;
  bool _isCreating = false;
  
  // Default values if no suggestion is provided
  String get taskTitle => widget.suggestion?.task ?? 'TO SLEEP';
  String get taskZone => widget.suggestion?.zone ?? 'Soft steps';
  String get taskTime => widget.suggestion?.suggestedTime ?? '22:00';
  String get taskDescription => widget.suggestion?.description ?? 
      "You're having a 10-minute call with your Bestie Fizzy during this task.";
  
  Color get zoneColor {
    switch (taskZone.toLowerCase()) {
      case 'soft steps':
        return const Color(0xFFA0E871);
      case 'stretch zone':
        return const Color(0xFFFFB84D);
      case 'power move':
        return const Color(0xFFFF6B6B);
      case 'elevated':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFFA0E871);
    }
  }

  Future<void> _addQuest() async {
    if (_isCreating) return; // Prevent double tap
    
    setState(() => _isCreating = true);

    try {
      print('\n🎯 Adding quest from suggestion...');
      print('Task: $taskTitle');
      print('Zone: $taskZone');
      print('Time: $taskTime');
      print('Enable Call: $isCallEnabled');
      print('Repeat Quest: $isRepeatQuestEnabled');
      print('Set Alarm: $isSetAlarmEnabled');

      // Get today's date in the format expected by API
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      final quest = await _questService.createQuest(
        task: taskTitle,
        zone: taskZone,
        selectADate: today,
        selectATime: taskTime,
        enableCall: isCallEnabled,
        repeatQuest: isRepeatQuestEnabled,
        setAlarm: isSetAlarmEnabled,
      );

      if (quest != null && mounted) {
        print('✅ Quest created successfully!');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quest "$taskTitle" added to Today\'s Plan!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFA0E871),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Go back and return true to indicate success
        context.pop(true);
      } else {
        print('❌ Failed to create quest');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add quest. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error adding quest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final baseScale = width / 390.0;

    return Scaffold(
      backgroundColor: const Color(0xFF89B6F8),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Assets.images.suggestedTaskOverview.path),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0 * baseScale,
                  vertical: 12.0 * baseScale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10 * baseScale),
                    // Header with back button, emoji, and edit button
                    _buildHeader(baseScale),
                    SizedBox(height: 16 * baseScale),

                    // Zone badge (dynamic)
                    _buildZoneBadge(baseScale),
                    SizedBox(height: 12 * baseScale),

                    // Task title (dynamic)
                    Text(
                      taskTitle.toUpperCase(),
                      style: AppTextStylesQutes.alfaSlabOneTitle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12 * baseScale),

                    // Today + Time row (dynamic)
                    _buildDateTimeRow(baseScale),
                    SizedBox(height: 20 * baseScale),

                    // Enable Call card
                    _buildEnableCallCard(baseScale),
                    SizedBox(height: 12 * baseScale),

                    // Repeat Quest card
                    _buildRepeatQuestCard(baseScale),
                    SizedBox(height: 12 * baseScale),

                    // Set Alarm card
                    _buildSetAlarmCard(baseScale),
                    SizedBox(height: 12 * baseScale),

                    // Call info text
                    _buildCallInfoText(baseScale),

                    SizedBox(height: 130 * baseScale),
                  ],
                ),
              ),

              // Fixed "Add quest" button at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildAddQuestButton(width, baseScale),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        GestureDetector(
          onTap: () {
            context.pop();
          },
          child: Container(
            width: 40 * s,
            height: 40 * s,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: const Color(0xFF011F54),
              size: 32 * s,
            ),
          ),
        ),

        // Emoji avatar
        SizedBox(
          width: 74 * s,
          height: 74 * s,
          child: Image.asset(
            Assets.images.emojiFun.path,
            fit: BoxFit.contain,
            width: 74 * s,
            height: 74 * s,
          ),
        ),

        // Edit button
        GestureDetector(
          onTap: () {
            context.push('/edit_quest');
          },
          child: SizedBox(
            width: 54 * s,
            height: 54 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(8 * s),
                child: Image.asset(
                  Assets.svgIcons.clearAllAIMemoryPng.path,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneBadge(double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: zoneColor,
        borderRadius: BorderRadius.circular(20 * s),
      ),
      child: Text(
        taskZone,
        style: GoogleFonts.workSans(
          color: const Color(0xFF011F54),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.40,
          letterSpacing: -0.90,
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(double s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          Assets.images.today.path,
          height: 16 * s,
          width: 16 * s,
          fit: BoxFit.cover,
        ),
        SizedBox(width: 6 * s),
        Text(
          'Today',
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 16 * s,
            color: const Color(0xFF011F54),
          ),
        ),
        SizedBox(width: 16 * s),
        Image.asset(
          Assets.images.clock1.path,
          height: 16 * s,
          width: 16 * s,
          fit: BoxFit.cover,
        ),
        SizedBox(width: 6 * s),
        Text(
          taskTime,
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.w600,
            fontSize: 16 * s,
            color: const Color(0xFF011F54),
          ),
        ),
      ],
    );
  }

  Widget _buildEnableCallCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF8),
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
                  value: isCallEnabled,
                  onChanged: (value) {
                    setState(() {
                      isCallEnabled = value;
                    });
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF4542EB),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFB0B0B0),
                ),
              ),
              SizedBox(width: 4 * s),
              Text('ENABLE CALL', style: AppTextStylesQutes.workSansBlack24),
            ],
          ),
          SizedBox(height: 8 * s),
          // Description
          Padding(
            padding: EdgeInsets.only(left: 4 * s),
            child: Text(
              '💬 A real-time 10-min support call will help you stay on track. You can add more time later if needed.',
              style: GoogleFonts.workSans(
                color: const Color(0xFF4C586E),
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

  Widget _buildRepeatQuestCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF8),
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
                color: const Color(0xFF4C586E),
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

  Widget _buildSetAlarmCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF8),
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

  Widget _buildCallInfoText(double s) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      child: Text(
        taskDescription,
        style: GoogleFonts.workSans(
          fontWeight: FontWeight.w400,
          fontSize: 14 * s,
          height: 1.5,
          color: const Color(0xFF011F54),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAddQuestButton(double width, double s) {
    return Container(
      width: width,
      padding: EdgeInsets.only(
        top: 12 * s,
        left: 20 * s,
        right: 20 * s,
        bottom: 32 * s,
      ),
      child: GestureDetector(
        onTap: _isCreating ? null : _addQuest,
        child: Container(
          width: double.infinity,
          height: 64 * s,
          decoration: BoxDecoration(
            color: _isCreating ? const Color(0xFF9B99D8) : const Color(0xFF4542EB),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: _isCreating
              ? SizedBox(
                  width: 24 * s,
                  height: 24 * s,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 24 * s),
                    SizedBox(width: 8 * s),
                    Text(
                      'Add quest',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        color: Colors.white,
                        fontSize: 20 * s,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
