import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/custom_code/bottom_nav.dart';

import 'package:nowlii/screen/home/swipe_on_quest/delete_toast.dart';
import 'package:nowlii/screen/home/swipe_on_quest/tomorrow_card.dart';
import 'package:nowlii/screen/reminder_notification/ai_call_reminder/default_yellow/default_yellow.dart';
import 'package:nowlii/screen/reminder_notification/ai_call_reminder/error_toast/error_toast.dart';
import 'package:nowlii/screen/reminder_notification/ai_call_reminder/quest_suggestion_purple/quest_suggestion_purple.dart';
import 'package:nowlii/screen/reminder_notification/ai_call_reminder/success_toast/success_toast.dart';
import 'package:nowlii/themes/create_qutes.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';

class AiCallRemiender extends StatefulWidget {
  const AiCallRemiender({super.key});

  @override
  State<AiCallRemiender> createState() => _AiCallRemienderState();
}

class _AiCallRemienderState extends State<AiCallRemiender> {
  final ScrollController _scrollController = ScrollController();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        OnboardingOverlay.show(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation tap
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            // Handle avatar tap
            context.push(AppRoutespath.profileNotificationsScreen);
          },
          child: CircleAvatar(
            radius: 24,
            // child: Icon(
            //   Icons.person_outline,
            //   color: Color(0xFF5B7EFF),
            //   size: 28,
            // ),
            child: Image.asset(
              Assets.svgIcons.avatar.path,
              height: 28,
              width: 28,
            ),
          ),
        ),
        Text('HI JULIE!', style: AppsTextStyles.extraBold32Centered),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColorsApps.skyBlueLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05))],
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
          BoxShadow(color: const Color(0xFF5B7EFF).withValues(alpha: 0.1)),
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
              BoxShadow(color: const Color(0xFF5B7EFF).withValues(alpha: 0.1)),
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
              BoxShadow(color: const Color(0xFF5B7EFF).withValues(alpha: 0.3)),
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
                  color: const Color(0xFFFFFDF7), // Text-text-light
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
            color: const Color(0xFF011F54), // Text-text-default
            fontSize: 32,
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
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF5B7EFF), width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: Color(0xFF5B7EFF), size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Add quest',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.workSans(
                      color: const Color(0xFF4542EB) /* Text-text-primary */,
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
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSwipeButton() {
    return GestureDetector(
      onTap: () {},
      // child: Container(
      //   padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      //   decoration: BoxDecoration(
      //     color: Colors.,

      //   ),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       Image.asset(
      //         Assets.svgIcons.swipeToTalkToFuzzy.path,
      //         height: 24,
      //         width: 24,
      //       ),
      //       const SizedBox(width: 12),
      //       Text(
      //         'Swipe to talk to Fuzzy',
      //         textAlign: TextAlign.center,
      //         style: GoogleFonts.workSans(
      //           color: const Color(0xFF011F54),
      //           fontSize: 20,
      //           fontWeight: FontWeight.w900,
      //           height: 0.8,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
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
          // mainAxisSize: MainAxisSize.min,
          // mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 12,
          children: [
            // Container(
            //   width: 56,
            //   height: 56,
            //   padding: const EdgeInsets.all(16),
            //   decoration: ShapeDecoration(
            //     // color: const Color(0xFF4542EB),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(999),
            //     ),
            //     shadows: [
            //       BoxShadow(
            //         color: Color(0x19011F54),
            //         blurRadius: 18,
            //         offset: Offset(2, 10),
            //         spreadRadius: 0,
            //       ),
            //     ],
            //   ),
            //   child: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     spacing: 10,
            //     children: [Container(width: 24, height: 24, child: Stack())],
            //   ),
            // ),
            Center(
              child: Image.asset(
                Assets.svgIcons.swipeToTalkToFuzzy.path,
                height: 70,
                width: 70,
              ),
            ),
            Text(
              'Swipe to talk to Fuzzy',
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: const Color(0xFF011F54),
                fontSize: 20,

                fontWeight: FontWeight.w900,
                // height: 0.80,
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
                child: Opacity(opacity: value, child: child),
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

// Onboarding System
class OnboardingOverlay {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => const OnboardingDialog(),
    );
  }
}

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

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
      widget: const DefaultYellow(),
      position: const Alignment(0, -0.3),
    ),
    OnboardingStep(
      widget: const SuccessTueast(),
      position: const Alignment(0.5, 0),
    ),
    OnboardingStep(
      widget: const ErrorTueast(),
      position: const Alignment(-0.5, 0.4),
    ),
    OnboardingStep(
      widget: const QuestSuggestionPurple(),
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
      if (mounted) Navigator.of(context).pop();
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
