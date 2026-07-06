import 'package:flutter/material.dart';
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
import 'dart:math';

// Import the notification system
// import 'notification_system.dart';

class TestFile extends StatefulWidget {
  const TestFile({super.key});

  @override
  State<TestFile> createState() => _TestFileState();
}

class _TestFileState extends State<TestFile> {
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;

  final List<TaskItem> _tasks = [
    TaskItem('To wake up ☀️', '10:00', false),
    TaskItem('To walk 🚶', '10:30', false),
    TaskItem('To study 📚', '12:00', false),
    TaskItem('To train 💪', '16:00', false),
    TaskItem('To Sleep 🌙', '22:00', false, isSpecial: true),
  ];

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Show onboarding first - notifications will be triggered after onboarding completes
        OnboardingOverlay.show(
          context,
          onComplete: _showAllNotifications, // ✅ Callback when onboarding done
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _showAllNotifications() {
    if (!mounted) return;

    // Notification 1: Default Yellow (shows immediately after onboarding)
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
          debugPrint('Navigate to voice note screen');
        },
      ),
    );

    // Notification 2: Quest Suggestion (5 seconds later)
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
              debugPrint('Add quest pressed');
            },
          ),
        );
      }
    });

    // Notification 3: Success (10 seconds later)
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
              debugPrint('See progress pressed');
            },
          ),
        );
      }
    });

    // Notification 4: Error (15 seconds later)
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
              debugPrint('Add another quest');
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
          SingleChildScrollView(
            controller: _scrollController,
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

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.03,
              numberOfParticles: 30,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
                Colors.orange,
                Colors.pink,
              ],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(
                  Rect.fromCircle(center: Offset.zero, radius: size.width / 2),
                );
                return path;
              },
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            context.push(AppRoutespath.profileNotificationsScreen);
          },
          child: const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFD4E3FF),
            child: Icon(
              Icons.person_outline,
              color: Color(0xFF5B7EFF),
              size: 28,
            ),
          ),
        ),
        Text('HI JULIE!', style: AppsTextStyles.extraBold32Centered),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColorsApps.skyBlueLight,
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
              Text('1', style: AppsTextStyles.fullNameAndEmail),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final totalTasks = _tasks.length;
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ready to make\ntoday count?',
                  style: AppsTextStyles.sendResetLinkButton,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tiny wins make big shifts.',
                  style: AppsTextStyles.workSansRegular14,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Today\'s progress',
                        style: AppsTextStyles.regular16l,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppsTextStyles.regular16l,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColorsApps.royalBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              Assets.svgIcons.readyToMakeTodayCount.path,
              height: 44,
              width: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    final now = DateTime.now();
    return Row(
      children: [
        Container(
          height: 120,
          width: 120,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF5B7EFF), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7EFF).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Today',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text('${now.day}', style: AppsTextStyles.extraBold32Centered),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 120,
          width: 120,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B7EFF), Color(0xFF4542EB)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B7EFF).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Plan',
                textAlign: TextAlign.center,
                style: GoogleFonts.workSans(
                  color: const Color(0xFFFFFDF7),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 0.80,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysPlanHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Todays plan',
          textAlign: TextAlign.center,
          style: GoogleFonts.workSans(
            color: const Color(0xFF011F54),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -1,
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              // Show quest suggestion notification
              NotificationManager().show(
                context,
                NotificationData(
                  type: NotificationType.questSuggestion,
                  title: 'Wake up or wind down with Nowlli! 😴🌞',
                  subtitle:
                      'You can schedule Nowlli for wake-up or bedtime calls! Just create a task, turn on repeat, and Nowlli will call you 10 minutes before — to help you wake up or drift off peacefully. 💕',
                  buttonText: 'Add quest',
                  onButtonPressed: () {
                    debugPrint('Add quest pressed');
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF5B7EFF), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: Color(0xFF5B7EFF), size: 20),
                  SizedBox(width: 2),
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
    return Column(
      children: _tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        return AnimatedTaskItem(
          key: ValueKey('${task.title}_$index'),
          task: task,
          onEdit: () => (index),
          onDelete: () => _deleteTask(index),
          onTomorrow: () => _moveToTomorrow(index),
          onToggle: () {
            if (mounted) {
              setState(() {
                task.isCompleted = !task.isCompleted;
              });

              if (task.isCompleted) {
                _confettiController.play();
                _showCompletionDialog();

                // Check if all tasks completed
                final allCompleted = _tasks.every((t) => t.isCompleted);
                if (allCompleted) {
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      NotificationManager().show(
                        context,
                        NotificationData(
                          type: NotificationType.success,
                          title: 'Fuzzy\'s proud of you',
                          subtitle:
                              'One chat at a time, you\'re getting stronger',
                          buttonText: 'See progress',
                          onButtonPressed: () {
                            debugPrint('See progress pressed');
                          },
                        ),
                      );
                    }
                  });
                }
              }
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSwipeButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 80,
        width: double.infinity,
        padding: const EdgeInsets.only(top: 8, left: 8, right: 24, bottom: 8),
        decoration: ShapeDecoration(
          color: const Color(0xFFFF8F26),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x19011F54),
              blurRadius: 18,
              offset: Offset(2, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(
                Assets.svgIcons.swipeToTalkToFuzzy.path,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Swipe to talk to Fuzzy',
                textAlign: TextAlign.center,
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTask(int index) {
    if (!mounted) return;

    final removed = _tasks[index];
    setState(() => _tasks.removeAt(index));

    // First show the DeleteToast
    _showCustomToast(
      context,
      child: DeleteToast(
        onUndo: () {
          if (mounted) {
            setState(() => _tasks.insert(index, removed));
          }
        },
      ),
    );

    // Show error notification AFTER DeleteToast disappears (3 seconds later)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        NotificationManager().show(
          context,
          NotificationData(
            type: NotificationType.error,
            title: 'You missed our talk, that\'s okay',
            subtitle: 'I\'m here when you\'re ready',
            buttonText: 'Add another quest',
            onButtonPressed: () {
              debugPrint('Add another quest');
            },
          ),
        );
      }
    });
  }

  void _moveToTomorrow(int index) {
    if (!mounted) return;

    setState(() => _tasks.removeAt(index));

    _showCustomToast(context, child: const TomorrowCard());
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

// Task Model
class TaskItem {
  String title;
  String time;
  bool isCompleted;
  String? reminder;
  final bool isSpecial;

  TaskItem(
    this.title,
    this.time,
    this.isCompleted, {
    this.isSpecial = false,
    this.reminder,
  });
}

// Animated Task Item Widget with flutter_slidable
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
            SlidableAction(
              onPressed: (_) => widget.onEdit(),
              backgroundColor: const Color(0xFF5B7EFF),
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            SlidableAction(
              onPressed: (_) => widget.onDelete(),
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
            SlidableAction(
              onPressed: (_) => widget.onTomorrow(),
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              icon: Icons.today,
              label: 'Tomorrow',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
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
      margin: const EdgeInsets.only(bottom: 14),
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

// Completion Dialog Widget
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

// Onboarding System
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
      // ✅ Onboarding complete!
      if (mounted) {
        Navigator.of(context).pop();
        // ✅ Trigger notifications after dialog closes
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
// NOTIFICATION SYSTEM (Inline)
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: ShapeDecoration(
        image: DecorationImage(
          image: AssetImage(config.backgroundImagePath),
          fit: BoxFit.cover,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: config.iconBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Image.asset(
              notification.iconPath ?? config.defaultIconPath,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),

                if (notification.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    notification.subtitle!,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF595754),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.60,
                    ),
                  ),
                ],

                if (notification.buttonText != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: notification.onButtonPressed,
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      decoration: ShapeDecoration(
                        color: config.buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          notification.buttonText!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(
                            color: config.buttonTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 0.80,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _NotificationConfig _getNotificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.error:
        return _NotificationConfig(
          backgroundImagePath: 'assets/images/reminder_red.png',
          iconBackgroundColor: const Color(0xFFD53D40),
          iconColor: Colors.white,
          buttonColor: const Color(0xFFD53D3F),
          buttonTextColor: const Color(0xFFFFFDF7),
          defaultIconPath: 'assets/images/plush.png',
        );
      case NotificationType.questSuggestion:
        return _NotificationConfig(
          backgroundImagePath: 'assets/images/Quest suggestion-purple.png',
          iconBackgroundColor: const Color(0xFF3F3CD6),
          iconColor: Colors.white,
          buttonColor: const Color(0xFF4542EB),
          buttonTextColor: const Color(0xFFFFFDF7),
          defaultIconPath: 'assets/images/plush.png',
        );
      case NotificationType.defaultYellow:
        return _NotificationConfig(
          backgroundImagePath: 'assets/images/reminder_yellow.png',
          iconBackgroundColor: const Color(0xFFFF8F26),
          iconColor: Colors.white,
          buttonColor: const Color(0xFFFF8F26),
          buttonTextColor: const Color(0xFF011F54),
          defaultIconPath: 'assets/images/Microphone.png',
        );
      case NotificationType.success:
        return _NotificationConfig(
          backgroundImagePath: 'assets/images/reminder_green.png',
          iconBackgroundColor: const Color(0xFFA0E871),
          iconColor: Colors.white,
          buttonColor: const Color(0xFFA0E871),
          buttonTextColor: const Color(0xFF011F54),
          defaultIconPath: 'assets/images/fire_nave.png',
        );
    }
  }
}

class _NotificationConfig {
  final String backgroundImagePath;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final String defaultIconPath;

  _NotificationConfig({
    required this.backgroundImagePath,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.defaultIconPath,
  });
}
