import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/screen/home/swipe_to_talk/screen_flow_controller.dart';
import 'package:nowlii/screen/home/swipe_to_talk/voice_check/voice_check_controller.dart';

/// Main Voice Check Popup Widget
class PoupYourShareYou extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration totalDuration;

  const PoupYourShareYou({
    super.key,
    this.title = 'Answer emails',
    this.subtitle = "You're doing great — keep it going",
    this.totalDuration = const Duration(minutes: 10),
  });

  @override
  State<PoupYourShareYou> createState() => _PoupYourShareYouState();
}

class _PoupYourShareYouState extends State<PoupYourShareYou>
    with ScreenFlowMixin {
  @override
  FlowScreen get flowScreen => FlowScreen.poupYourShareYou;

  @override
  void initState() {
    super.initState();
    // Initialize automatic navigation flow (3 seconds delay)
    initializeFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VoiceCheckController>()
        ? Get.find<VoiceCheckController>()
        : Get.put(VoiceCheckController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/svg_images/popup_scree_liner.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    // ✅ FIXED HEADER
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left side - Profile/Avatar
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Image.asset(
                                    "assets/images/blu_cross.png",
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),

                            // Right side - AI Label
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 8),
                                Image.asset(
                                  "assets/images/AI.png",
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    _buildTitle(),
                    Obx(() => _buildSubtitle(controller)),

                    // Avatar
                    Expanded(
                      child: Center(child: _buildVoiceAvatar(controller)),
                    ),

                    // Action buttons (Bottom)
                    // Obx(() {
                    //   if (controller.aiCallState.value == AiCallState.callEnded)
                    //     return const SizedBox();

                    //   return Column(children: []);
                    // }),
                    SizedBox(
                      width: 335,
                      child: Text(
                        'Hold to speak 🎙️\nNowlii will listen once you say something.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(
                            0xFF4542EB,
                          ) /* Text-text-primary */,
                          fontSize: 18,
                          fontFamily: 'Work Sans',
                          fontWeight: FontWeight.w600,
                          height: 1.40,
                          letterSpacing: -0.90,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Overlays
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Obx(
                  () => _buildStatusBanner(controller.aiCallState.value),
                ),
              ),

              // Full Screen Overlay for Call Ended
              Positioned.fill(
                child: Obx(() {
                  if (controller.aiCallState.value == AiCallState.callEnded) {
                    return Container(
                      color: Colors.black54,
                      child: Center(child: _buildCallEndedWidget()),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(AiCallState state) {
    switch (state) {
      case AiCallState.endingSoon:
        return _buildCallEndingSoonWidget();
      case AiCallState.minutesAdded:
        return _buildMinutesAddedWidget();
      case AiCallState.muted:
        return _buildMutedWidget();
      case AiCallState.networkError:
        return _buildNetworkErrorWidget();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCallEndingSoonWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFCF1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Call ending soon!',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'You can add 10 more minutes to your call!',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF595754),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.60,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFF8F26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 18, height: 18, child: Stack()),
                      SizedBox(width: 8),
                      Text(
                        'Add 10 minutes',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 18,
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
        ],
      ),
    );
  }

  Widget _buildMinutesAddedWidget() {
    return Container(
      width: 335,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFDF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '10 more minutes added',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'You can now talk to me 10 more minutes!',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF595754),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutedWidget() {
    return Container(
      width: 335,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFDF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
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
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 24, height: 24, child: Stack()),
                SizedBox(width: 8),
                Text(
                  'Youre muted',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkErrorWidget() {
    return Container(
      width: 335,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFFDDBDC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
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
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 24, height: 24, child: Stack()),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Network error',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.20,
                          letterSpacing: -0.50,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Please check your internet connection!',
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallEndedWidget() {
    return Container(
      width: 335,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFDF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: [
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wrap up already?',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'No rush — but if you re done, lets mark this quest complete.',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF595754),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.60,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 2,
                              color: const Color(0xFF6A68EF),
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Continue a bit longer',
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
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF3F3CD6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Yes, Im done',
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontFamily: 'Wosker',
              fontSize: 28.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1A2B4F),
            ),
          ),
          SizedBox(width: 8.w),
          Text('✉️', style: TextStyle(fontSize: 24.sp)),
        ],
      ),
    );
  }

  Widget _buildSubtitle(VoiceCheckController controller) {
    String text;
    switch (controller.state.value) {
      case VoiceCheckState.recording:
        text = "Nowlii will listen once you say something.";
        break;
      case VoiceCheckState.error:
        text = "You didn't say anything?\nHold and speak again.";
        break;
      case VoiceCheckState.processing:
        text = "Processing your voice note...";
        break;
      default:
        text = widget.subtitle;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6B7280),
        height: 1.4,
      ),
    );
  }

  Widget _buildVoiceAvatar(VoiceCheckController controller) {
    return Obx(() {
      final isRecording = controller.state.value == VoiceCheckState.recording;

      return Stack(
        alignment: Alignment.center,
        children: [
          // Actual progress indicator
          if (isRecording)
            SizedBox(
              width: 200.w,
              height: 200.w,
              child: CustomPaint(
                painter: ProgressRingPainter(
                  progress:
                      (controller.recordingDuration.value.inSeconds /
                              widget.totalDuration.inSeconds)
                          .clamp(0.1, 1.0),
                  color: const Color(0xFF3B82F6),
                  strokeWidth: 12.w,
                ),
              ),
            ),

          // Inner dark blue circle
          SizedBox(
            width: 266,
            height: 248.79,
            child: Stack(
              children: [
                // Outer gradient circle
                Positioned(
                  left: 1,
                  top: 0,
                  child: SizedBox(
                    width: 248.77,
                    height: 248.79,
                    child: Stack(
                      children: [
                        Positioned(
                          child: Container(
                            width: 258,
                            height: 255,
                            decoration: ShapeDecoration(
                              gradient: RadialGradient(
                                center: Alignment(0.46, 0.46),
                                radius: 0.98,
                                colors: [
                                  const Color(0x003F3CD6),
                                  const Color.fromARGB(125, 30, 28, 175),
                                ],
                              ),
                              shape: OvalBorder(),
                            ),
                          ),
                        ),
                        // Inner gradient circle with shadow
                        Positioned(
                          left: 34,
                          top: 32,
                          child: Container(
                            width: 182.58,
                            height: 182.58,
                            decoration: ShapeDecoration(
                              gradient: RadialGradient(
                                center: Alignment(0.50, 0.50),
                                radius: 0.73,
                                colors: [
                                  const Color(0xFF7270F3),
                                  const Color(0xFF3F3CD6),
                                ],
                              ),
                              shape: OvalBorder(),
                              shadows: [
                                BoxShadow(
                                  color: Color(0x995550FF),
                                  blurRadius: 19.60,
                                  offset: Offset(0, 0),
                                  spreadRadius: 11,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Middle layer
                Positioned(
                  left: 0,
                  top: 48.15,
                  child: Container(
                    width: 266,
                    height: 154.39,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.13),
                      ),
                    ),
                  ),
                ),
                // Center image/emoji
                Positioned(
                  left: 67.17,
                  top: 60.45,
                  child: Container(
                    width: 130.63,
                    height: 129.18,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          "assets/svg_images/popup_screen_carton.png",
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Custom painter for progress ring
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final startAngle = -3.14159 / 2;
      final sweepAngle = 2 * 3.14159 * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Loading dots animation widget
class LoadingDotsAnimation extends StatefulWidget {
  const LoadingDotsAnimation({super.key});

  @override
  State<LoadingDotsAnimation> createState() => _LoadingDotsAnimationState();
}

class _LoadingDotsAnimationState extends State<LoadingDotsAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.5 + (_animations[index].value * 0.5),
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// Show voice check popup as a modal
void showVoiceCheckPopup({
  required BuildContext context,
  String title = 'Answer emails',
  String subtitle = "You're doing great — keep it going",
  Duration totalDuration = const Duration(minutes: 10),
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: PoupYourShareYou(
        title: title,
        subtitle: subtitle,
        totalDuration: totalDuration,
      ),
    ),
  );
}

class RingPainter extends CustomPainter {
  final double progress;

  RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Progress ring
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3D87F5), Color(0xFF68A2F9)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
