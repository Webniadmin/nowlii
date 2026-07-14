import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/custom_code/bottom_nav.dart';
import 'package:nowlii/screen/home/contextual_onboarding/popup_screen.dart';
import 'package:nowlii/screen/home/swipe_on_quest/delete_toast.dart';
import 'package:nowlii/screen/home/swipe_on_quest/tomorrow_card.dart';
import 'package:nowlii/themes/create_qutes.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';
import 'package:nowlii/screen/home/swipe_to_talk/swipe_button_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/services/profile_service.dart';
import 'package:nowlii/services/quest_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;
  ProfileData? _profileData;
  bool _isLoadingProfile = true;
  int _streakCount = 0;
  bool _isLoadingStreak = true;
  List<Quest> _quests = [];
  bool _isLoadingQuests = true;
  Map<String, int> _questCountByDate = {}; // Date-wise quest count
  DateTime _selectedDate = DateTime.now(); // Currently selected date
  List<DateTime> _availableDates = []; // Dates that have quests

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadProfile();
    _loadStreak();
    _loadQuests();
    _loadAllQuestsForDates();
    _checkAndShowOnboarding();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload profile when app comes to foreground
      _loadProfile();
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload profile when widget updates
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileService = ProfileService();
    final profile = await profileService.fetchProfile();
    if (mounted) {
      setState(() {
        _profileData = profile;
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadStreak() async {
    final profileService = ProfileService();
    final streak = await profileService.fetchStreak();
    if (mounted) {
      setState(() {
        _streakCount = streak;
        _isLoadingStreak = false;
      });
    }
  }

  Future<void> _loadQuests() async {
    final questService = QuestService();
    final quests = await questService.fetchQuestsByDate(_selectedDate);
    if (mounted) {
      setState(() {
        _quests = quests;
        _isLoadingQuests = false;
      });
    }
  }

  Future<void> _loadQuestsForDate(DateTime date) async {
    if (mounted) {
      setState(() {
        _selectedDate = date;
        _isLoadingQuests = true;
      });
    }
    
    final questService = QuestService();
    final quests = await questService.fetchQuestsByDate(date);
    
    if (mounted) {
      setState(() {
        _quests = quests;
        _isLoadingQuests = false;
      });
    }
  }

  Future<void> _loadAllQuestsForDates() async {
    final questService = QuestService();
    final allQuests = await questService.fetchAllQuests();
    
    if (mounted) {
      // Group quests by date
      Map<String, int> countByDate = {};
      Set<DateTime> uniqueDates = {};
      
      for (var quest in allQuests) {
        final dateStr = quest.selectADate;
        countByDate[dateStr] = (countByDate[dateStr] ?? 0) + 1;
        
        // Parse date and add to unique dates
        try {
          final date = DateTime.parse(dateStr);
          uniqueDates.add(DateTime(date.year, date.month, date.day));
        } catch (e) {
          print('Error parsing date: $dateStr');
        }
      }
      
      // Sort dates
      final sortedDates = uniqueDates.toList()..sort();
      
      // Always include today if not already there
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      if (!sortedDates.contains(todayDate)) {
        sortedDates.insert(0, todayDate);
      }
      
      setState(() {
        _questCountByDate = countByDate;
        _availableDates = sortedDates;
      });
    }
  }

  Future<void> _checkAndShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user just completed onboarding (new user)
    final isNewUser = prefs.getBool('is_new_user') ?? false;
    final hasSeenHomeOnboarding = prefs.getBool('hasSeenHomeOnboarding') ?? false;
    
    // Only show tooltips and notifications to NEW users who haven't seen them yet
    if (isNewUser && !hasSeenHomeOnboarding && mounted) {
      // Mark as seen
      await prefs.setBool('hasSeenHomeOnboarding', true);
      // Clear the new user flag
      await prefs.setBool('is_new_user', false);
      
      // Show onboarding tooltips
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          OnboardingOverlay.show(context, onComplete: _showAllNotifications);
        }
      });
    }
  }

  void _showAllNotifications() {
    if (!mounted) return;

    NotificationManager().show(
      context,
      NotificationData(
        type: NotificationType.defaultYellow,
        title: 'Quest starts soon! Wanna share how u feel before we dive in?',
        subtitle:
            'Send a voice note to your bestie- me! Tell me what\'s on your mind, or how you\'re feeling before the session.',
        buttonText: 'Send a quick note',
        displayDuration: const Duration(seconds: 5),
        onButtonPressed: () {
          // Go straight to the 5-min AI voice call (emotion-share detour removed).
          context.push(AppRoutespath.aiVoice);
        },
      ),
    );

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        NotificationManager().show(
          context,
          NotificationData(
            type: NotificationType.success,
            title: 'Fuzzy\'s proud of you',
            subtitle: 'One chat at a time, you\'re getting stronger',
            buttonText: 'See progress',
            displayDuration: const Duration(seconds: 5),
            onButtonPressed: () {
              debugPrint('See progress pressed - Navigating to Progress screen');
              context.push(AppRoutespath.progress);
            },
          ),
        );
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        NotificationManager().show(
          context,
          NotificationData(
            type: NotificationType.questSuggestion,
            title: 'Wake up or wind down with Nowlli! 😴🌞',
            subtitle:
                'You can schedule Nowlli for wake-up or bedtime calls! Just create a task, turn on repeat, and Nowlli will call you 10 minutes before — to help you wake up or drift off peacefully. 💕',
            buttonText: 'Add quest',
            displayDuration: const Duration(seconds: 5),
            onButtonPressed: () {
              debugPrint('Add quest pressed - Navigating to Create Quest screen');
              context.push(AppRoutespath.createQuestPage);
            },
          ),
        );
      }
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        NotificationManager().show(
          context,
          NotificationData(
            type: NotificationType.error,
            title: 'You missed our talk, that\'s okay',
            subtitle: 'I\'m here when you\'re ready',
            buttonText: 'Add another quest',
            displayDuration: const Duration(seconds: 5),
            onButtonPressed: () {
              debugPrint('Add another quest - Navigating to Create Quest screen');
              context.push(AppRoutespath.createQuestPage);
            },
          ),
        );
      }
    });
  }

  void _showCompletionDialog() {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 15 + MediaQuery.of(context).padding.top,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: const CompletionDialog(),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // ── Main scrollable content with RefreshIndicator ──
          RefreshIndicator(
            onRefresh: () async {
              // Reload all data
              await Future.wait([
                _loadProfile(),
                _loadStreak(),
                _loadQuests(),
                _loadAllQuestsForDates(),
              ]);
            },
            color: const Color(0xFF4542EB),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content is short
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/svg_images/upscalemedia-transformed.png',
                    ),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildProgressCard(),
                        const SizedBox(height: 24),
                        _buildDateSection(),
                        const SizedBox(height: 24),
                        _buildTodaysPlanHeader(),
                        const SizedBox(height: 16),
                        _buildTaskList(),
                        const SizedBox(height: 24),
                        _buildSwipeButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Rain Confetti — 20+ scattered ──
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                // explosive → চারদিকে এলোমেলো ছড়াবে, gravity নিচে টানবে
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.08, // ঘন ঘন emit হবে
                numberOfParticles: 25, // ২৫টা একসাথে
                gravity: 0.25, // ধীরে ধীরে নিচে পড়বে — বেশি float
                minBlastForce: 5,
                maxBlastForce: 25, // force random → এলোমেলো দূরত্ব
                shouldLoop: false,
                colors: const [
                  Color(0xFF4285F4), // Blue
                  Color(0xFFEA4335), // Red-orange
                  Color(0xFFFBBC05), // Yellow
                  Color(0xFF34A853), // Green
                  Color(0xFFFF6D00), // Orange
                ],
                createParticlePath: (size) {
                  // Image এর মতো irregular চতুর্ভুজ
                  final path = Path();
                  path.moveTo(0, size.height * 0.3);
                  path.lineTo(size.width * 0.6, 0);
                  path.lineTo(size.width, size.height * 0.7);
                  path.lineTo(size.width * 0.4, size.height);
                  path.close();
                  return path;
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            // Navigate to profile and reload when returning
            await context.push(AppRoutespath.profileNotificationsScreen);
            // Reload profile data
            if (mounted) {
              _loadProfile();
            }
          },
          child: _isLoadingProfile
              ? const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFD4E3FF),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B7EFF)),
                  ),
                )
              : CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFD4E3FF),
                  backgroundImage: _profileData?.profileImage.isNotEmpty == true
                      ? NetworkImage(_profileData!.profileImage)
                      : null,
                  child: _profileData?.profileImage.isEmpty ?? true
                      ? const Icon(
                          Icons.person_outline,
                          color: Color(0xFF5B7EFF),
                          size: 28,
                        )
                      : null,
                ),
        ),
        const SizedBox(width: 12),
        Text(
          'HI ${(_profileData?.name ?? 'JULIE').toUpperCase()}!',
          style: TextStyle(
            color: const Color(0xFF011F54),
            fontSize: 32,
            fontFamily: 'Wosker',
            fontWeight: FontWeight.w400,
            height: 0.80,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFDFEFFF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(Assets.svgIcons.fire.path, height: 22, width: 22),
              const SizedBox(width: 6),
              _isLoadingStreak
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B7EFF)),
                      ),
                    )
                  : Text('$_streakCount', style: AppsTextStyles.fullNameAndEmail),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final totalTasks = _quests.length;
    final completedTasks = _quests.where((quest) => quest.taskDone).length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4E3FF), Color(0xFFE8F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B7EFF).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 178,
                      child: Text(
                        'Ready to make \n today count?',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tiny wins make big shifts.',
                      style: AppsTextStyles.workSansRegular14,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4542EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _profileData?.avatarLogo.isNotEmpty == true
                    ? Image.network(
                        _profileData!.avatarLogo,
                        width: 90.28,
                        height: 90.37,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            Assets.svgIcons.readyToMakeTodayCount.path,
                            width: 90.28,
                            height: 90.37,
                          );
                        },
                      )
                    : Image.asset(
                        Assets.svgIcons.readyToMakeTodayCount.path,
                        width: 90.28,
                        height: 90.37,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Todays progress',
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: -0.50,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFC3DBFF),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFDFEFFF), Color(0xFF4542EB)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    final now = DateTime.now();
    
    // Get day names
    final List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    String getDayName(DateTime date) {
      return dayNames[date.weekday - 1];
    }
    
    String getDateLabel(DateTime date) {
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      if (dateOnly == today) {
        return 'Today';
      } else if (dateOnly == tomorrow) {
        return 'Tomorrow';
      } else {
        return getDayName(date);
      }
    }
    
    // Check if date is selected
    bool isDateSelected(DateTime date) {
      return DateFormat('yyyy-MM-dd').format(date) == 
             DateFormat('yyyy-MM-dd').format(_selectedDate);
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Show all available dates
          for (int i = 0; i < _availableDates.length; i++) ...[
            GestureDetector(
              onTap: () => _loadQuestsForDate(_availableDates[i]),
              child: _buildDateCard(
                label: getDateLabel(_availableDates[i]),
                day: _availableDates[i].day,
                isToday: isDateSelected(_availableDates[i]),
                hasIndicator: (_questCountByDate[DateFormat('yyyy-MM-dd').format(_availableDates[i])] ?? 0) > 0,
                indicatorColor: i == 0 ? const Color(0xFF4542EB) : 
                               i == 1 ? const Color(0xFFFF8F26) : 
                               const Color(0xFF4542EB),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Plan button
          GestureDetector(
            onTap: () async {
              final result = await context.push(AppRoutespath.createQuestPage);
              // If quest was created successfully, reload data
              if (result == true && mounted) {
                _loadQuests();
                _loadAllQuestsForDates();
              }
            },
            child: Container(
              width: 78,
              height: 84,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4542EB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFFFFFDF7),
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFFFFFDF7),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateCard({
    required String label,
    required int day,
    required bool isToday,
    required bool hasIndicator,
    Color? indicatorColor,
  }) {
    return Container(
      height: 84,
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFDFEFFF) : const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday ? const Color(0xFF4542EB) : const Color(0xFFC3DBFF),
          width: isToday ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.workSans(
              color: const Color(0xFF011F54),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$day',
            style: GoogleFonts.workSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
              color: const Color(0xFF011F54),
            ),
          ),
          if (hasIndicator) ...[
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaysPlanHeader() {
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == 
                    DateFormat('yyyy-MM-dd').format(now);
    final isTomorrow = DateFormat('yyyy-MM-dd').format(_selectedDate) == 
                       DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    
    String headerText;
    if (isToday) {
      headerText = 'Todays plan';
    } else if (isTomorrow) {
      headerText = 'Tomorrows plan';
    } else {
      headerText = '${DateFormat('MMM d').format(_selectedDate)}\'s plan';
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              headerText,
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              final result = await context.push(AppRoutespath.createQuestPage);
              // If quest was created successfully, reload data
              if (result == true && mounted) {
                _loadQuests();
                _loadAllQuestsForDates();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF5B7EFF), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: const Color(0xFF5B7EFF), size: 20.sp),
                  SizedBox(width: 2.sp),
                  Text(
                    'Add quest',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4542EB),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 0.80,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    if (_isLoadingQuests) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_quests.isEmpty) {
      final now = DateTime.now();
      final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == 
                      DateFormat('yyyy-MM-dd').format(now);
      
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC3DBFF)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Color(0xFF5B7EFF),
            ),
            const SizedBox(height: 16),
            Text(
              isToday ? 'No quests for today' : 'No quests for this date',
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add quest" to create your first task',
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: const Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    final items = _quests.asMap().entries.map((entry) {
      final index = entry.key;
      final quest = entry.value;
      
      // Format time for display (convert 24-hour to 12-hour format)
      String displayTime = quest.zone; // Default to zone if no time
      if (quest.selectATime != null && quest.selectATime!.isNotEmpty) {
        try {
          // Parse time (format: "06:11:00" or "06:11")
          final timeParts = quest.selectATime!.split(':');
          if (timeParts.length >= 2) {
            int hour = int.parse(timeParts[0]);
            int minute = int.parse(timeParts[1]);
            
            // Convert to 12-hour format
            String period = hour >= 12 ? 'PM' : 'AM';
            int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
            
            displayTime = '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
          }
        } catch (e) {
          print('Error parsing time: $e');
          displayTime = quest.zone; // Fallback to zone
        }
      }
      
      return AnimatedTaskItem(
        key: ValueKey('quest_${quest.id}'),
        task: TaskItem(
          quest.task,
          displayTime, // Show time instead of zone
          quest.taskDone,
          questId: quest.id,
        ),
        onEdit: () async {
          final result = await context.push(
            AppRoutespath.editQuestPage,
            extra: {
              'taskId': quest.id,
              'taskData': {
                'title': quest.task,
                'zone': quest.zone,
                'selectADate': quest.selectADate,
                'time': quest.selectATime, // Pass time for editing
                'enableCall': quest.enableCall,
                'repeatQuest': quest.repeatQuest,
                'setAlarm': quest.setAlarm,
                'taskDone': quest.taskDone,
                'subtasks': quest.subtasks.map((s) => {
                  'id': s.id,
                  'title': s.title,
                  'task_done': s.taskDone,
                }).toList(),
              },
            },
          );
          // If quest was updated successfully, reload data
          if (result == true && mounted) {
            _loadQuests();
            _loadAllQuestsForDates();
          }
        },
        onDelete: () => _deleteQuest(index, quest.id),
        onTomorrow: () => _moveToTomorrow(index, quest.id),
        onToggle: () => _toggleQuest(index, quest.id),
      );
    }).toList();

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          items[i],
          if (i != items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSwipeButton() {
    return SwipeButtonWidget(
      companionName: (_profileData?.companionName.isNotEmpty ?? false)
          ? _profileData!.companionName
          : 'Fuzzy',
      onSwipe: () {
        // Go straight to the 5-min AI voice call (emotion-share detour removed).
        context.push(AppRoutespath.aiVoice);
      },
    );
  }

  Future<void> _toggleQuest(int index, int questId) async {
    if (!mounted) return;
    
    final quest = _quests[index];
    final newStatus = !quest.taskDone;
    
    setState(() {
      quest.taskDone = newStatus;
    });

    final questService = QuestService();
    final success = await questService.updateQuestStatus(questId, newStatus);

    if (!success && mounted) {
      // Revert on failure
      setState(() {
        quest.taskDone = !newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update quest')),
      );
      return;
    }

    if (newStatus && mounted) {
      _confettiController.play();
      _showCompletionDialog();
      
      // Reload streak after completing a quest
      _loadStreak();
      
      final allCompleted = _quests.every((q) => q.taskDone);
      if (allCompleted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            NotificationManager().show(
              context,
              NotificationData(
                type: NotificationType.success,
                title: 'Fuzzy\'s proud of you',
                subtitle: 'One chat at a time, you\'re getting stronger',
                buttonText: 'See progress',
                onButtonPressed: () {
                  debugPrint('See progress pressed - Navigating to Progress screen');
                  context.push(AppRoutespath.progress);
                },
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _deleteQuest(int index, int questId) async {
    if (!mounted) return;
    
    final removed = _quests[index];
    setState(() => _quests.removeAt(index));
    
    bool undoPressed = false;
    
    _showCustomToast(
      context,
      child: DeleteToast(
        onUndo: () async {
          undoPressed = true;
          if (mounted) {
            setState(() => _quests.insert(index, removed));
          }
        },
      ),
    );

    // Delete from API after a delay (allowing undo)
    await Future.delayed(const Duration(seconds: 3));
    
    // Only delete if undo was not pressed
    if (!undoPressed && mounted) {
      final questService = QuestService();
      final success = await questService.deleteQuest(questId);
      
      if (!success && mounted) {
        // If delete failed, add the quest back
        setState(() => _quests.insert(index, removed));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete quest'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Reload date counts after successful delete
      _loadAllQuestsForDates();
      
      if (mounted) {
        NotificationManager().show(
          context,
          NotificationData(
            type: NotificationType.error,
            title: 'You missed our talk, that\'s okay',
            subtitle: 'I\'m here when you\'re ready',
            buttonText: 'Add another quest',
            onButtonPressed: () {
              context.push(AppRoutespath.createQuestPage);
            },
          ),
        );
      }
    }
  }

  Future<void> _moveToTomorrow(int index, int questId) async {
    if (!mounted) return;
    
    final removed = _quests[index];
    setState(() => _quests.removeAt(index));
    _showCustomToast(context, child: const TomorrowCard());
    
    // Parse current date and add 1 day
    final currentDate = DateTime.parse(removed.selectADate);
    final nextDate = currentDate.add(const Duration(days: 1));
    final nextDateStr = DateFormat('yyyy-MM-dd').format(nextDate);
    
    // Update quest date in API using PATCH
    final questService = QuestService();
    final updatedQuest = await questService.updateQuest(
      questId: questId,
      selectADate: nextDateStr,
    );
    
    if (updatedQuest == null && mounted) {
      // If update failed, add the quest back
      setState(() => _quests.insert(index, removed));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to move quest to tomorrow'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Reload date counts after successful move
      _loadAllQuestsForDates();
    }
  }

  void _showCustomToast(BuildContext context, {required Widget child}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: MediaQuery.of(context).size.width / 2 - 170,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: child,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}

// ============================================
// Task Model
// ============================================
class TaskItem {
  String title;
  String time;
  bool isCompleted;
  String? reminder;
  final bool isSpecial;
  final int? questId;

  TaskItem(
    this.title,
    this.time,
    this.isCompleted, {
    this.isSpecial = false,
    this.reminder,
    this.questId,
  });
}

// ============================================
// Animated Task Item
// ============================================
class AnimatedTaskItem extends StatefulWidget {
  final TaskItem task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTomorrow;
  final VoidCallback onToggle;

  const AnimatedTaskItem({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onTomorrow,
    required this.onToggle,
  });

  @override
  State<AnimatedTaskItem> createState() => _AnimatedTaskItemState();
}

class _AnimatedTaskItemState extends State<AnimatedTaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Slidable(
        key: ValueKey(widget.task),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.75,
          children: [
            CustomSlidableAction(
              onPressed: (_) => widget.onEdit(),
              backgroundColor: const Color(0xFFFAE3CE),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              autoClose: true,
              padding: EdgeInsets.zero,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/svg_images/Edit.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edit',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomSlidableAction(
              onPressed: (_) => widget.onDelete(),
              backgroundColor: const Color(0xFFFEDCDC),
              autoClose: true,
              padding: EdgeInsets.zero,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/svg_images/Trash.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomSlidableAction(
              onPressed: (_) => widget.onTomorrow(),
              backgroundColor: const Color(0xFFC3DBFF),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              autoClose: true,
              padding: EdgeInsets.zero,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/svg_images/Tomowr.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tomorrow',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        child: _buildTaskCard(),
      ),
    );
  }

  Widget _buildTaskCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: widget.task.isSpecial
            ? null
            : Border.all(color: AppColorsApps.peachGlow),
        color: widget.task.isSpecial ? null : AppColorsApps.softCream,
        image: widget.task.isSpecial
            ? const DecorationImage(
                image: AssetImage('assets/svg_icons/To sleep.png'),
                fit: BoxFit.cover,
              )
            : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: widget.task.isSpecial
                ? const Color(0xFF5B7EFF).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.task.isCompleted
                    ? (widget.task.isSpecial
                          ? Colors.white
                          : const Color(0xFF5B7EFF))
                    : Colors.transparent,
                border: Border.all(
                  color: widget.task.isSpecial
                      ? Colors.white
                      : const Color(0xFF5B7EFF),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.task.isCompleted
                  ? Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: widget.task.isSpecial
                          ? const Color(0xFF5B7EFF)
                          : Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.task.title,
              style: AppTextStylesQutes.workSansSemiBosld18.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.task.isSpecial
                    ? Colors.white
                    : const Color(0xFF1A1F36),
                decoration: widget.task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                decorationThickness: widget.task.isCompleted ? 2 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.task.isSpecial
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.task.time,
              style: AppTextStylesQutes.workSansSemiBold18.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.task.isSpecial
                    ? Colors.white
                    : AppColorsApps.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Completion Dialog
// ============================================
class CompletionDialog extends StatelessWidget {
  const CompletionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 335,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: ShapeDecoration(
            color: const Color(0xFFCFFFC9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x070A0C12),
                blurRadius: 6,
                offset: Offset(0, 4),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Color(0x140A0C12),
                blurRadius: 16,
                offset: Offset(0, 12),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/svg_icons/bottom_first_your_complate.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Boom, your first task completed!',
                            style: TextStyle(
                              color: Color(0xFF011F54),
                              fontSize: 20,
                              fontFamily: 'Work Sans',
                              fontWeight: FontWeight.w800,
                              height: 1.20,
                              letterSpacing: -0.50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFFDF7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            '+1 streak',
                            style: TextStyle(
                              color: Color(0xFF011F54),
                              fontSize: 12,
                              fontFamily: 'Work Sans',
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// Onboarding System
// ============================================
class OnboardingOverlay {
  static void show(BuildContext context, {VoidCallback? onComplete}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => OnboardingDialog(onComplete: onComplete),
    );
  }
}

class OnboardingDialog extends StatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingDialog({super.key, this.onComplete});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      widget: const ChatBubbleContainer(),
      position: const Alignment(0, -0.3),
    ),
    OnboardingStep(
      widget: const ChatMessage(),
      position: const Alignment(0.5, 0),
    ),
    OnboardingStep(
      widget: const ConversationBubble(),
      position: const Alignment(-0.5, 0.4),
    ),
    OnboardingStep(
      widget: const TextBubble(),
      position: const Alignment(0, 0.6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _next() async {
    await _fadeController.reverse();
    if (_step < _steps.length - 1) {
      if (mounted) {
        setState(() => _step++);
        _fadeController.forward();
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _next,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              alignment: _steps[_step].position,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  key: ValueKey(_step),
                  child: _steps[_step].widget,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingStep {
  final Widget widget;
  final Alignment position;
  OnboardingStep({required this.widget, required this.position});
}

// ============================================
// NOTIFICATION SYSTEM
// ============================================
enum NotificationType { error, questSuggestion, defaultYellow, success }

class NotificationData {
  final NotificationType type;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final String? iconPath;
  final Duration displayDuration;

  NotificationData({
    required this.type,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconPath,
    this.displayDuration = const Duration(seconds: 5),
  });
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final List<NotificationData> _queue = [];
  bool _isShowing = false;

  void show(BuildContext context, NotificationData notification) {
    _queue.add(notification);
    if (!_isShowing) {
      _showNext(context);
    }
  }

  void _showNext(BuildContext context) {
    if (_queue.isEmpty) {
      _isShowing = false;
      return;
    }
    _isShowing = true;
    final notification = _queue.removeAt(0);
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 15 + MediaQuery.of(context).padding.top,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -80 * (1 - value)),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              );
            },
            child: AICallNotification(notification: notification),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(notification.displayDuration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
      if (context.mounted) {
        _showNext(context);
      }
    });
  }

  void clear() {
    _queue.clear();
    _isShowing = false;
  }
}

class AICallNotification extends StatelessWidget {
  final NotificationData notification;
  const AICallNotification({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final config = _getNotificationConfig(notification.type);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: config.backgroundGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: config.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: _buildIcon(notification.type, config)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (notification.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        notification.subtitle!,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (notification.buttonText != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: notification.onButtonPressed,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: config.buttonColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (config.buttonImagePath != null) ...[
                      Image.asset(
                        config.buttonImagePath!,
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      notification.buttonText!,
                      textAlign: TextAlign.center,
                      style:
                          (notification.type ==
                                  NotificationType.defaultYellow ||
                              notification.type == NotificationType.success)
                          ? GoogleFonts.workSans(
                              color: const Color(0xFF011F54),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 0.80,
                            )
                          : GoogleFonts.workSans(
                              color: config.buttonTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon(NotificationType type, _NotificationConfig config) {
    switch (type) {
      case NotificationType.error:
        return const Icon(Icons.favorite, color: Colors.white, size: 24);
      case NotificationType.questSuggestion:
        return Image.asset(
          'assets/images/sun.png',
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset('assets/images/sun.png', width: 24, height: 24),
        );
      case NotificationType.defaultYellow:
        return Image.asset(
          'assets/images/star.png',
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.mic, color: Colors.white, size: 24),
        );
      case NotificationType.success:
        return Image.asset(
          'assets/images/celberation.png',
          width: 24,
          height: 24,
        );
    }
  }

  _NotificationConfig _getNotificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.error:
        return _NotificationConfig(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE4E6), Color(0xFFFECDD3)],
          ),
          iconBackgroundColor: const Color(0xFFE11D48),
          iconColor: Colors.white,
          buttonColor: const Color(0xFFE11D48),
          buttonTextColor: Colors.white,
          defaultIconPath: 'assets/images/plush.png',
          buttonImagePath: 'assets/images/plush.png',
        );
      case NotificationType.questSuggestion:
        return _NotificationConfig(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDBE9FF), Color(0xFFC7D9F7)],
          ),
          iconBackgroundColor: const Color(0xFFBFDBFE),
          iconColor: Colors.white,
          buttonColor: const Color(0xFF6366F1),
          buttonTextColor: Colors.white,
          defaultIconPath: 'assets/images/plush.png',
          buttonImagePath: 'assets/images/plush.png',
        );
      case NotificationType.defaultYellow:
        return _NotificationConfig(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE4B5), Color(0xFFFFD699)],
          ),
          iconBackgroundColor: const Color(0xFFFF8C00),
          iconColor: Colors.white,
          buttonColor: const Color(0xFFFF8C00),
          buttonTextColor: Colors.white,
          defaultIconPath: 'assets/images/Microphone.png',
          buttonImagePath: 'assets/images/Microphone.png',
        );
      case NotificationType.success:
        return _NotificationConfig(
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
          ),
          iconBackgroundColor: const Color(0xFF86EFAC),
          iconColor: Colors.white,
          buttonColor: const Color(0xFF22C55E),
          buttonTextColor: Colors.white,
          defaultIconPath: 'assets/images/fire_nave.png',
          buttonImagePath: 'assets/images/fire_nave.png',
        );
    }
  }
}

class _NotificationConfig {
  final LinearGradient backgroundGradient;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final String defaultIconPath;
  final String? buttonImagePath;

  _NotificationConfig({
    required this.backgroundGradient,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.defaultIconPath,
    this.buttonImagePath,
  });
}
