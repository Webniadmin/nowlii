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
import 'package:nowlii/models/call_summary_history.dart';
import 'package:nowlii/models/scheduled_call.dart';
import 'package:nowlii/services/call_reminder_service.dart';
import 'package:nowlii/services/completion_banner.dart';
import 'package:nowlii/services/home_format.dart';
import 'package:nowlii/services/scheduled_call_state.dart';
import 'package:nowlii/services/spark_state.dart';
import 'package:nowlii/services/spark_state_store.dart';
import 'package:nowlii/services/voice_call_service.dart';
import 'package:nowlii/screen/home/sparks/out_of_sparks_card.dart';
import 'package:nowlii/widget/lapsed_reminder.dart';
import 'dart:async';
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
  /// Home now shows today only — the other days live in the Quests tab.
  final DateTime _selectedDate = DateTime.now();

  /// The most recent call that named a next step, quoted back on the hero card.
  CallSummaryHistoryItem? _lastSaid;

  /// The user's companion, for copy that addresses them by name. "Fuzzy" was written into
  /// these notifications from the mock, so every user was congratulated by a companion
  /// they had not chosen.
  String get _companionName {
    final name = _profileData?.companionName.trim() ?? '';
    return name.isEmpty ? 'Nowlii' : name;
  }

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
    _loadLastSaid();
    _checkAndShowOnboarding();
    // How many sparks are left decides whether this screen offers a call at all.
    SparkStateStore.instance.refresh();
    // A lapsed plan no longer closes the app, so nothing else here would say it has ended.
    // Once per launch, on the screen they actually land on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowLapsedReminder(context);
    });
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
      // The allowance resets at midnight, so an app left open overnight would otherwise
      // still be showing yesterday's "that's enough for today".
      SparkStateStore.instance.refresh();
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

  /// The newest saved call that actually named a next step, for the hero quote.
  ///
  /// Skips calls that produced no next step rather than quoting an empty string — a short
  /// call legitimately leaves nothing to say back.
  Future<void> _loadLastSaid() async {
    final summaries = await VoiceCallService().getSummaries();
    if (!mounted) return;
    CallSummaryHistoryItem? found;
    for (final s in summaries) {
      if (s.nextStep.trim().isNotEmpty) {
        found = s;
        break;
      }
    }
    setState(() => _lastSaid = found);
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
            title: '$_companionName\'s proud of you',
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

  void _showCompletionDialog({required String title, required String badge}) {
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
            child: CompletionDialog(title: title, badge: badge),
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
      backgroundColor: const Color(0xFFFFFEF8),
      body: Stack(
        children: [
          // Decorative bloom bleeding off the top-left corner, behind everything.
          Positioned(
            left: -214,
            top: -364,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: 80.73 * pi / 180,
                child: Assets.svgIcons.homeFlower.svg(width: 431, height: 431),
              ),
            ),
          ),

          // ── Main scrollable content with RefreshIndicator ──
          RefreshIndicator(
            onRefresh: () async {
              // Reload all data
              await Future.wait([
                _loadProfile(),
                _loadStreak(),
                _loadQuests(),
                _loadLastSaid(),
                SparkStateStore.instance.refresh(),
              ]);
            },
            color: const Color(0xFF4542EB),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content is short
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 16),
                      // Stays at the top, above the restored hero card.
                      _buildSparksBar(),
                      const SizedBox(height: 16),
                      _buildReadyCard(),
                      const SizedBox(height: 32),
                      _buildTodaysPlanHeader(),
                      const SizedBox(height: 16),
                      _buildQuestList(),
                      const SizedBox(height: 24),
                      _buildSwipeButton(),
                      const SizedBox(height: 40),
                    ],
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
          // Greet by name once we have one. The old fallback was the mock's "JULIE",
          // so every user was greeted as someone else until their profile loaded.
          (_profileData?.name.trim().isNotEmpty ?? false)
              ? 'HI ${_profileData!.name.trim().toUpperCase()}!'
              : 'HI THERE!',
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
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
          decoration: ShapeDecoration(
            color: const Color(0xFFDFEFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
              side: const BorderSide(color: Color(0xFFC3DBFF)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.svgIcons.homeFire.svg(width: 32, height: 32),
              const SizedBox(width: 4),
              _isLoadingStreak
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4542EB)),
                      ),
                    )
                  : Text(
                      '$_streakCount',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF4542EB),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                        letterSpacing: -0.5,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  /// How many of today's sparks are still available, as pills plus a plain count.
  ///
  /// Replaces the old "Ready to make today count?" progress card. It reads from the same
  /// shared store as the call screen and the swipe button, so the three cannot disagree.
  Widget _buildSparksBar() {
    return ValueListenableBuilder<SparkState>(
      valueListenable: SparkStateStore.instance.state,
      builder: (context, sparks, _) {
        // Unlimited accounts have no meaningful number of slots to draw; unknown has no
        // honest one. Both get the label without the pills.
        final slots = (sparks.known && !sparks.unlimited) ? sparks.limit : 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFDFEFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (int i = 0; i < slots; i++) ...[
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    // Spent slots stay visible so the row keeps its shape and you can see
                    // what you started the day with.
                    color: i < sparks.remaining
                        ? const Color(0xFF4542EB)
                        : const Color(0x334542EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Padding(
                padding: EdgeInsets.only(left: slots > 0 ? 4 : 0),
                child: Text(
                  sparksAvailableLabel(
                    remaining: sparks.remaining,
                    unlimited: sparks.unlimited,
                    known: sparks.known,
                    paused: sparks.paused,
                  ),
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The blue hero card: an invitation plus how far today has got.
  ///
  /// Restored from the original design. It gives way to the closing card once the day's
  /// sparks are spent — at that point "ready to make today count?" is the wrong thing to
  /// ask, and the green card is the designed ending.
  Widget _buildReadyCard() {
    return ValueListenableBuilder<SparkState>(
      valueListenable: SparkStateStore.instance.state,
      builder: (context, sparks, _) {
        if (sparks.isSpent) {
          return OutOfSparksCard(
            sparks: sparks,
            nextStep: _lastSaid?.nextStep,
          );
        }

        final total = _quests.length;
        final done = _quests.where((q) => q.taskDone).length;
        // An empty day has nothing to be a fraction of. The bar keeps its track and simply
        // does not fill, rather than dividing by zero or implying progress.
        final progress = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFDFEFFF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to make today count?',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tiny wins make big shifts.',
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF4C586E),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(9.43),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4542EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _profileData?.avatarLogo.isNotEmpty == true
                        ? Image.network(
                            _profileData!.avatarLogo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Todays progress',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(
                      height: 24,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC3DBFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      height: 24,
                      width: progressFillWidth(
                        progress: progress,
                        trackWidth: constraints.maxWidth,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDFEFFF), Color(0xFF4542EB)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The last thing the user told their companion, quoted back.
  ///
  /// Kept for the moment but no longer in the layout: the restored design leads with the
  /// hero card above instead.
  // ignore: unused_element
  Widget _buildLastSaidCard() {
    return ValueListenableBuilder<SparkState>(
      valueListenable: SparkStateStore.instance.state,
      builder: (context, sparks, _) {
        if (sparks.isSpent) {
          return OutOfSparksCard(
            sparks: sparks,
            nextStep: _lastSaid?.nextStep,
          );
        }

        final said = _lastSaid;
        // Nothing to quote yet — a new account has no calls behind it, and an empty
        // bordered card would just be a hole in the layout.
        if (said == null) return const SizedBox.shrink();

        final when = said.startedAt ?? said.createdAt;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFEF8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFC3DBFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (when == null ? 'You said' : saidWhenLabel(when)).toUpperCase(),
                style: GoogleFonts.martianMono(
                  color: const Color(0xFF4C586E),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.32,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '“${said.nextStep.trim()}”',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Assets.svgIcons.homeCheck.svg(width: 22, height: 22),
                  const SizedBox(width: 9),
                  Text(
                    'Did it',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4C586E),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// "Todays plan" and the way to add to it.
  ///
  /// Always today: the day strip is gone from home, and the other days live in the Quests
  /// tab, so there is no longer another date this could be describing.
  Widget _buildTodaysPlanHeader() {
    return Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Todays plan',
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
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final result = await context.push(AppRoutespath.createQuestPage);
              // If quest was created successfully, reload data
              if (result == true && mounted) {
                _loadQuests();
              }
            },
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(color: Color(0xFF6A68EF), width: 2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Assets.svgIcons.homePlus.svg(width: 18, height: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Add quest',
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4542EB),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 0.8,
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

  /// Today's quests, as the list the original design shows.
  ///
  /// Restored from single-card back to a list: home is where the day is planned, and one
  /// card at a time hid the rest of it.
  Widget _buildQuestList() {
    if (_isLoadingQuests) {
      return _questCardShell(title: 'Loading…', subtitle: '', showArt: false);
    }
    if (_quests.isEmpty) {
      return _questCardShell(
        title: 'Nothing planned',
        subtitle: 'Add a quest to give today a shape.',
        showArt: true,
      );
    }

    return Column(
      children: [
        for (int i = 0; i < _quests.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildQuestRow(i, _quests[i]),
        ],
      ],
    );
  }

  /// One row of the day: a checkbox, the quest, and the time it is set for.
  Widget _buildQuestRow(int index, Quest quest) {
    final done = quest.taskDone;
    return GestureDetector(
      onTap: () => _toggleQuest(index, quest.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCB9B)),
        ),
        child: Row(
          children: [
            Container(
              width: 21.6,
              height: 21.6,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF4542EB) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF4542EB), width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: Color(0xFFFFFEF8))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                quest.task,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  letterSpacing: -0.9,
                  // A finished quest reads as struck through rather than disappearing, so
                  // the day still shows what was done.
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if ((quest.selectATime ?? '').isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                _shortTime(quest.selectATime!),
                style: GoogleFonts.workSans(
                  color: const Color(0xFF595754),
                  fontSize: 18,
                  height: 1.4,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "14:30:00" → "14:30". The backend serialises seconds the design never shows.
  String _shortTime(String raw) {
    final parts = raw.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : raw;
  }

  /// Today's quest, as one card. Superseded by [_buildQuestList]; kept for reference.
  // ignore: unused_element
  Widget _buildTodaysQuestCard() {
    if (_isLoadingQuests) {
      return _questCardShell(
        title: 'Loading…',
        subtitle: '',
        showArt: false,
      );
    }

    if (_quests.isEmpty) {
      return _questCardShell(
        title: 'Nothing planned',
        subtitle: 'Add a quest to give today a shape.',
        showArt: true,
      );
    }

    final next = _quests.firstWhere(
      (q) => !q.taskDone,
      orElse: () => _quests.first,
    );
    final allDone = _quests.every((q) => q.taskDone);
    final stepsLeft = next.subtasks.where((s) => !s.taskDone).length;

    return _questCardShell(
      title: next.task,
      subtitle: allDone
          ? 'All done for today'
          : stepsLeftLabel(
              // A quest with no subtasks is one step in itself.
              next.subtasks.isEmpty ? (next.taskDone ? 0 : 1) : stepsLeft,
            ),
      showArt: true,
    );
  }

  Widget _questCardShell({
    required String title,
    required String subtitle,
    required bool showArt,
  }) {
    return Container(
      width: double.infinity,
      height: 170,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFAE3CE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          if (showArt)
            Positioned(
              right: 24,
              bottom: 13,
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(
                  Assets.svgIcons.homeQuestBlob.path,
                  width: 96,
                  height: 144,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: SizedBox(
              // Keeps the copy clear of the illustration rather than running under it.
              width: 190,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "TODAY'S QUEST",
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF6B3C10),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.72,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.archivoBlack(
                      color: const Color(0xFF011F54),
                      fontSize: 26,
                      height: 0.9,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    Text(
                      subtitle,
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF4C586E),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeButton() {
    return ValueListenableBuilder<SparkState>(
      valueListenable: SparkStateStore.instance.state,
      builder: (context, sparks, _) => SwipeButtonWidget(
        // Out of sparks: becomes a closing line instead of a swipe that would only reach
        // the backend's refusal. Which line depends on why — see [SparkState.paused].
        spent: sparks.isSpent,
        paused: sparks.paused,
        // Go straight to the 5-min AI voice call (emotion-share detour removed).
        onSwipe: _startSpontaneousCall,
      ),
    );
  }

  /// Swipe-to-talk, with one guard: don't let the user spend their last call by accident.
  ///
  /// Scheduled calls never reserve quota — they are plans, not bookings. So swiping when
  /// only one call is left silently kills a call the user planned for later today. That is
  /// the one case worth interrupting for; every other path goes straight through.
  Future<void> _startSpontaneousCall() async {
    final voiceCalls = VoiceCallService();
    final quota = await voiceCalls.getQuota();
    if (!mounted) return;

    // This read is the freshest thing we have; share it rather than letting the card and
    // the button keep an older one.
    if (quota != null) {
      SparkStateStore.instance
          .adopt(limit: quota.limit, remaining: quota.remaining);
    }

    // Only fetch the schedule when it could actually matter.
    if (quota != null && quota.remaining == 1) {
      final scheduled = await voiceCalls.getScheduledCalls();
      if (!mounted) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final laterToday = scheduled
          .where((c) => c.isPending && c.isOn(today))
          .toList()
        ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));

      if (wouldStrandAScheduledCall(
        remainingCalls: quota.remaining,
        scheduledLaterToday: [for (final c in laterToday) c.scheduledFor],
        now: now,
      )) {
        final next = laterToday.firstWhere((c) => c.scheduledFor.isAfter(now));
        final callNow = await _confirmSpendingLastCall(
          DateFormat('HH:mm').format(next.scheduledFor),
        );
        if (!mounted || !callNow) return;

        // Talking now spends the call that one was counting on. Rather than leave it to
        // fail at its own hour, offer it the same time tomorrow — rescheduleCall moves the
        // quest with it, so the plan and the quest never disagree.
        await _offerToMoveStrandedCall(next);
        if (!mounted) return;
      }
    }

    if (!mounted) return;
    context.push(AppRoutespath.aiVoice);
  }

  /// Ask whether the call this swipe just stranded should move to tomorrow.
  ///
  /// Declining is a real answer, not a postponement: the call stays where it is and shows
  /// as missed. Nothing here blocks the call the user asked for — a failed move is
  /// reported and the call goes ahead.
  Future<void> _offerToMoveStrandedCall(ScheduledCall call) async {
    final at = DateFormat('HH:mm').format(call.scheduledFor);
    final quest = call.questTitle.trim();
    final named = quest.isEmpty ? 'your $at call' : '"$quest"';

    final move = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Move $named to tomorrow?',
          style: GoogleFonts.workSans(fontWeight: FontWeight.w900),
        ),
        content: Text(
          "Your $at call can't run today now. Nowlii can move it — and the quest "
          'with it — to $at tomorrow.',
          style: GoogleFonts.workSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Leave it', style: GoogleFonts.workSans()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Move to tomorrow',
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4542EB),
              ),
            ),
          ),
        ],
      ),
    );

    if (move != true || !mounted) return;

    final moved = await VoiceCallService()
        .rescheduleCall(call.id, sameTimeNextDay(call.scheduledFor));
    if (!mounted) return;

    if (moved) {
      unawaited(CallReminderService.instance.sync());
      _loadQuests();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          moved
              ? 'Moved to $at tomorrow.'
              : "Couldn't move it — it stays at $at today.",
        ),
      ),
    );
  }

  /// Returns true if the user wants to talk now anyway.
  Future<bool> _confirmSpendingLastCall(String nextCallTime) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'This is your last call today',
          style: GoogleFonts.workSans(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'You have a call scheduled for $nextCallTime. Talking now uses your last '
          'call of the day, so that one will be locked until tomorrow.',
          style: GoogleFonts.workSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep it for $nextCallTime', style: GoogleFonts.workSans()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Talk now',
              style: GoogleFonts.workSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4542EB),
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
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

      final lifetime = await CompletionCounter.record();
      if (!mounted) return;
      final completedToday = _quests.where((q) => q.taskDone).length;
      _showCompletionDialog(
        title: completionBannerTitle(
          lifetimeCompletions: lifetime,
          completedToday: completedToday,
        ),
        badge: completionBannerBadge(
          completedToday: completedToday,
          totalToday: _quests.length,
        ),
      );


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
                title: '$_companionName\'s proud of you',
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
      
      // The day strip is gone; just refresh today.
      _loadQuests();
      
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
      // The day strip is gone; just refresh today.
      _loadQuests();
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
  /// Both lines are passed in rather than written here: the headline was a claim about
  /// the user's first completion and the badge a claim about their streak, and the widget
  /// knows neither. See `services/completion_banner.dart`.
  const CompletionDialog({super.key, required this.title, required this.badge});

  final String title;
  final String badge;

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
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
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
                          child: Text(
                            badge,
                            style: const TextStyle(
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
