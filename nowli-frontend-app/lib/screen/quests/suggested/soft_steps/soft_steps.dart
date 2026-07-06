import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';
import 'package:nowlii/models/quest_suggestion_model.dart';
import 'package:nowlii/services/insights_service.dart';

class ShuffleScreen extends StatefulWidget {
  final String? filterZone; // Add optional filter parameter
  
  const ShuffleScreen({super.key, this.filterZone});

  @override
  State<ShuffleScreen> createState() => _ShuffleScreenState();
}

class _ShuffleScreenState extends State<ShuffleScreen> {
  final InsightsService _service = InsightsService();
  List<QuestSuggestion> _suggestions = [];
  List<QuestSuggestion> _filteredSuggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('\n');
    print('═══════════════════════════════════════');
    print('🎯 SHUFFLE SCREEN INITIALIZED');
    if (widget.filterZone != null) {
      print('🔍 Filter Zone: ${widget.filterZone}');
    } else {
      print('📋 Showing all zones');
    }
    print('═══════════════════════════════════════');
    print('\n');
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    print('🔄 Loading quest suggestions from Insights API...');
    setState(() => _isLoading = true);
    
    try {
      print('📞 Calling Insights API...');
      final response = await _service.getInsights();
      print('📦 API Response received: ${response != null ? "Success" : "Null"}');
      
      if (response != null && response.weekly.questSuggestions.isNotEmpty && mounted) {
        print('✅ Setting ${response.weekly.questSuggestions.length} suggestions from Insights API');
        setState(() {
          _suggestions = response.weekly.questSuggestions;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        print('⚠️ Using fallback data');
        // Use fallback data if API fails
        _useFallbackData();
      }
    } catch (e) {
      print('❌ Error in _loadSuggestions: $e');
      _useFallbackData();
    }
  }

  void _applyFilter() {
    if (widget.filterZone == null) {
      // No filter - show all
      _filteredSuggestions = _suggestions;
      print('📋 Showing all ${_filteredSuggestions.length} suggestions');
    } else {
      // Filter by zone
      _filteredSuggestions = _suggestions.where((suggestion) {
        return suggestion.zone.toLowerCase() == widget.filterZone!.toLowerCase();
      }).toList();
      print('🔍 Filtered to ${_filteredSuggestions.length} suggestions for zone: ${widget.filterZone}');
    }
  }
  void _useFallbackData() {
    // Fallback to hardcoded data if API fails
    setState(() {
      _suggestions = [
        QuestSuggestion(
          task: 'To sleep',
          description: 'Wind down, unplug, and prep your mind for rest.',
          zone: 'Soft steps',
          suggestedTime: '22:00',
        ),
        QuestSuggestion(
          task: 'To wake up',
          description: 'Rise fresh. Stretch, breathe — just light, breath, and presence.',
          zone: 'Soft steps',
          suggestedTime: '07:00',
        ),
        QuestSuggestion(
          task: 'To walk',
          description: 'Move your body, clear your mind. Even for a little bit counts.',
          zone: 'Stretch zone',
          suggestedTime: '18:00',
        ),
        QuestSuggestion(
          task: 'To study',
          description: 'Focus, learn, retain. Deep in reflection — just progress.',
          zone: 'Power move',
          suggestedTime: '14:00',
        ),
        QuestSuggestion(
          task: 'To train',
          description: 'Sweat, strengthen, boost energy. Show up for yourself.',
          zone: 'Elevated',
          suggestedTime: '06:00',
        ),
      ];
      _applyFilter();
      _isLoading = false;
    });
  }

  Color _getZoneColor(String zone) {
    switch (zone.toLowerCase()) {
      case 'soft steps':
        return const Color(0xFFA0E871); // Green
      case 'stretch zone':
        return const Color(0xFFFFB46E); // Orange
      case 'power move':
        return const Color(0xFFA9A8F6); // Purple
      case 'elevated':
        return const Color(0xFFFFCE73); // Yellow
      default:
        return const Color(0xFFA0E871); // Default Green
    }
  }

  String _getEmojiForTask(String task) {
    final taskLower = task.toLowerCase();
    
    // Sleep related
    if (taskLower.contains('sleep') || taskLower.contains('rest') || taskLower.contains('relax')) {
      return Assets.svgIcons.moon.path;
    }
    // Wake up related
    if (taskLower.contains('wake') || taskLower.contains('morning')) {
      return Assets.svgIcons.sun.path;
    }
    // Walk/Exercise related
    if (taskLower.contains('walk') || taskLower.contains('stretch') || taskLower.contains('move')) {
      return Assets.svgIcons.toWalkIcon.path;
    }
    // Study/Read/Learn related
    if (taskLower.contains('study') || taskLower.contains('read') || taskLower.contains('learn') || 
        taskLower.contains('book') || taskLower.contains('journal')) {
      return Assets.svgIcons.book.path;
    }
    // Train/Workout related
    if (taskLower.contains('train') || taskLower.contains('exercise') || taskLower.contains('workout') || 
        taskLower.contains('fitness')) {
      return Assets.svgIcons.push.path;
    }
    // Meditation/Mindfulness
    if (taskLower.contains('meditat') || taskLower.contains('mindful') || taskLower.contains('breath')) {
      return Assets.svgIcons.moon.path;
    }
    // Planning/Organize
    if (taskLower.contains('plan') || taskLower.contains('organiz') || taskLower.contains('priorit')) {
      return Assets.svgIcons.book.path;
    }
    // Gratitude/Reflection
    if (taskLower.contains('gratitude') || taskLower.contains('reflect') || taskLower.contains('positive')) {
      return Assets.svgIcons.book.path;
    }
    
    // Default
    return Assets.svgIcons.moon.path;
  }

  String _getBackgroundForTask(String task) {
    final taskLower = task.toLowerCase();
    
    // Sleep related
    if (taskLower.contains('sleep') || taskLower.contains('rest') || taskLower.contains('relax')) {
      return Assets.svgIcons.moon4.path;
    }
    // Wake up related
    if (taskLower.contains('wake') || taskLower.contains('morning')) {
      return Assets.svgIcons.toWakeUp.path;
    }
    // Walk/Exercise related
    if (taskLower.contains('walk') || taskLower.contains('stretch') || taskLower.contains('move')) {
      return Assets.svgIcons.toWalk.path;
    }
    // Study/Read/Learn related
    if (taskLower.contains('study') || taskLower.contains('read') || taskLower.contains('learn') || 
        taskLower.contains('book') || taskLower.contains('journal')) {
      return Assets.svgIcons.toStudy.path;
    }
    // Train/Workout related
    if (taskLower.contains('train') || taskLower.contains('exercise') || taskLower.contains('workout') || 
        taskLower.contains('fitness')) {
      return Assets.svgIcons.toTrain.path;
    }
    // Meditation/Mindfulness
    if (taskLower.contains('meditat') || taskLower.contains('mindful') || taskLower.contains('breath')) {
      return Assets.svgIcons.moon4.path;
    }
    // Planning/Organize
    if (taskLower.contains('plan') || taskLower.contains('organiz') || taskLower.contains('priorit')) {
      return Assets.svgIcons.toStudy.path;
    }
    // Gratitude/Reflection
    if (taskLower.contains('gratitude') || taskLower.contains('reflect') || taskLower.contains('positive')) {
      return Assets.svgIcons.toStudy.path;
    }
    
    // Default
    return Assets.svgIcons.moon4.path;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_isLoading)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4542EB)),
                  ),
                ),
              )
            else
              Expanded(
                child: _filteredSuggestions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.filterZone != null
                                  ? 'No ${widget.filterZone} quests available'
                                  : 'No suggestions available',
                              style: GoogleFonts.workSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try shuffling for new suggestions',
                              style: GoogleFonts.workSans(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _filteredSuggestions[index];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RoutineCard(
                              title: suggestion.task,
                              description: suggestion.description,
                              time: suggestion.suggestedTime,
                              softSteps: suggestion.zone,
                              hardSteps: '10 mins',
                              imagePath: _getBackgroundForTask(suggestion.task),
                              emoji: _getEmojiForTask(suggestion.task),
                              hardStepsColor: _getZoneColor(suggestion.zone),
                              softStepsColor: AppColorsApps.freshGreen,
                              suggestion: suggestion,
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _isLoading ? null : () {
          // Shuffle button clicked - reload suggestions
          print('🔄 Shuffle button clicked - Reloading suggestions...');
          _loadSuggestions();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: ShapeDecoration(
            color: _isLoading ? const Color(0xFFF5F5F5) : Colors.transparent,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 2, 
                color: _isLoading ? const Color(0xFFCCCCCC) : const Color(0xFF011F54),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4542EB)),
                  ),
                )
              else
                Image.asset(
                  Assets.svgIcons.shuffle.path,
                  width: 20,
                  height: 20,
                  color: const Color(0xFF011F54),
                ),
              const SizedBox(width: 8),
              Text(
                _isLoading ? 'Loading...' : 'Shuffle',
                style: GoogleFonts.workSans(
                  color: _isLoading ? const Color(0xFF999999) : const Color(0xFF011F54),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SleepRoutineCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final String softSteps;
  final String hardSteps;
  final String imagePath;
  final String emoji;
  final Color hardStepsColor;
  final Color softStepsColor;
  final QuestSuggestion? suggestion;

  const SleepRoutineCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.softSteps,
    required this.hardSteps,
    required this.imagePath,
    required this.emoji,
    required this.hardStepsColor,
    required this.softStepsColor,
    this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(emoji, width: 64, height: 64),
              GestureDetector(
                onTap: () async {
                  final result = await context.push('/suggestedTaskOverview', extra: suggestion);
                  // If quest was added successfully, show a brief feedback
                  if (result == true) {
                    print('✅ Quest added from Soft steps tab');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    Assets.svgIcons.toMoonPlus.path,
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.workSans(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        Assets.svgIcons.calendarBlank.path,
                        width: 15,
                        height: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        Assets.svgIcons.clockBlack.path,
                        width: 15,
                        height: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.workSans(
              color: const Color(0xFFFFFEF8),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.9,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hardStepsColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hardSteps,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: softStepsColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    softSteps,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RoutineCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final String softSteps;
  final String hardSteps;
  final String imagePath;
  final String emoji;
  final Color hardStepsColor;
  final Color softStepsColor;
  final QuestSuggestion? suggestion;

  const RoutineCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.softSteps,
    required this.hardSteps,
    required this.imagePath,
    required this.emoji,
    required this.hardStepsColor,
    required this.softStepsColor,
    this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(emoji, width: 64, height: 64),
              GestureDetector(
                onTap: () async {
                  final result = await context.push('/suggestedTaskOverview', extra: suggestion);
                  // If quest was added successfully, show a brief feedback
                  if (result == true) {
                    print('✅ Quest added from ${suggestion?.zone ?? "All zones"} tab');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    Assets.svgIcons.buttonCalendar.path,
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        Assets.svgIcons.calendarBlank.path,
                        width: 12,
                        height: 12,
                        color: const Color(0xFF011F54),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Today',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        Assets.svgIcons.clockBlack.path,
                        width: 12,
                        height: 12,
                        color: const Color(0xFF011F54),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          time,
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.workSans(
              color: const Color(0xFF4C586E),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.3,
              letterSpacing: -0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hardStepsColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hardSteps,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: softStepsColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    softSteps,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF011F54),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
