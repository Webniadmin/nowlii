import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nowlii/screen/home/swipe_to_talk/screen_flow_controller.dart';
import 'package:nowlii/screen/home/swipe_to_talk/voice_check/voice_check_controller.dart';

/// Main Voice Check Popup Widget
class PoupSpking extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration totalDuration;

  const PoupSpking({
    super.key,
    this.title = 'Answer emails',
    this.subtitle = "You're doing great — keep it going",
    this.totalDuration = const Duration(minutes: 10),
  });

  @override
  State<PoupSpking> createState() => _PoupSpkingState();
}

class _PoupSpkingState extends State<PoupSpking> with ScreenFlowMixin {
  @override
  FlowScreen get flowScreen => FlowScreen.poupSpking;

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
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                child: Column(
                  children: [
                    Padding(
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
                    // Header Area (Title/Subtitle) - Hide if critical alert?
                    // Keeping it for now but call status might cover it.
                    _buildTitle(),
                    Obx(() => _buildSubtitle(controller)),

                    // Avatar
                    Expanded(
                      child: Center(child: _buildVoiceAvatar(controller)),
                    ),

                    // Action buttons (Bottom)
                    Obx(() {
                      // Hide bottom controls if call ended overlay is shown?
                      // The user request shows "Wrap up" overlay.
                      // For now we keep bottom controls unless blocked.
                      if (controller.aiCallState.value ==
                          AiCallState.callEnded) {
                        return const SizedBox();
                      }

                      return Column(
                        children: [
                          // Row(
                          //   mainAxisSize: MainAxisSize.min,
                          //   mainAxisAlignment: MainAxisAlignment.start,
                          //   crossAxisAlignment: CrossAxisAlignment.center,
                          //   spacing: 8,
                          //   children: [
                          //     Container(
                          //       width: 40,
                          //       height: 40,
                          //       padding: const EdgeInsets.all(10),
                          //       decoration: ShapeDecoration(
                          //         color: const Color(0xFFC3DBFF),
                          //         shape: RoundedRectangleBorder(
                          //           borderRadius: BorderRadius.circular(999),
                          //         ),
                          //       ),
                          //       child: Row(
                          //         mainAxisSize: MainAxisSize.min,
                          //         mainAxisAlignment: MainAxisAlignment.center,
                          //         crossAxisAlignment: CrossAxisAlignment.center,
                          //         spacing: 10,
                          //         children: [
                          //           Container(
                          //             width: 20,
                          //             height: 20,
                          //             child: Stack(),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //     Flexible(
                          //       child: FittedBox(
                          //         fit: BoxFit.scaleDown,
                          //         child: Row(
                          //           mainAxisSize: MainAxisSize.min,
                          //           mainAxisAlignment: MainAxisAlignment.start,
                          //           crossAxisAlignment:
                          //               CrossAxisAlignment.center,
                          //           spacing: 9,
                          //           children: [
                          //             Text(
                          //               controller.getFormattedTime(),
                          //               textAlign: TextAlign.center,
                          //               style: TextStyle(
                          //                 color: const Color(0xFF4542EB),
                          //                 fontSize: 52,
                          //                 fontFamily: 'Wosker',
                          //                 fontWeight: FontWeight.w400,
                          //                 height: 0.80,
                          //               ),
                          //             ),
                          //             Text(
                          //               '/',
                          //               textAlign: TextAlign.center,
                          //               style: TextStyle(
                          //                 color: const Color(0xFFA9A8F6),
                          //                 fontSize: 52,
                          //                 fontFamily: 'Wosker',
                          //                 fontWeight: FontWeight.w400,
                          //                 height: 0.80,
                          //               ),
                          //             ),
                          //             Text(
                          //               '10:00',
                          //               textAlign: TextAlign.center,
                          //               style: TextStyle(
                          //                 color: const Color(0xFFA9A8F6),
                          //                 fontSize: 52,
                          //                 fontFamily: 'Wosker',
                          //                 fontWeight: FontWeight.w400,
                          //                 height: 0.80,
                          //               ),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // SizedBox(height: 20.h),
                          // Container(
                          //   width: 335,
                          //   child: Row(
                          //     mainAxisSize: MainAxisSize.min,
                          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       Row(
                          //         mainAxisSize: MainAxisSize.min,
                          //         mainAxisAlignment: MainAxisAlignment.start,
                          //         crossAxisAlignment: CrossAxisAlignment.center,
                          //         spacing: 8,
                          //         children: [
                          //           // Demo Button: Toggle Recording/Speaking
                          //           GestureDetector(
                          //             onTap: () {
                          //               if (controller.isRecording.value) {
                          //                 controller.stopRecording();
                          //               } else {
                          //                 controller.startRecording();
                          //               }
                          //             },
                          //             child: Container(
                          //               width: 64,
                          //               height: 64,
                          //               padding: const EdgeInsets.all(10),
                          //               decoration: ShapeDecoration(
                          //                 color: controller.isRecording.value
                          //                     ? Colors.red.withOpacity(0.2)
                          //                     : const Color(0xFFC3DBFF),
                          //                 shape: RoundedRectangleBorder(
                          //                   borderRadius: BorderRadius.circular(
                          //                     999,
                          //                   ),
                          //                 ),
                          //               ),
                          //               child: Icon(
                          //                 controller.isRecording.value
                          //                     ? Icons.stop
                          //                     : Icons.mic,
                          //                 color: const Color(0xFF4542EB),
                          //               ),
                          //             ),
                          //           ),
                          //           Container(
                          //             width: 64,
                          //             height: 64,
                          //             padding: const EdgeInsets.all(10),
                          //             decoration: ShapeDecoration(
                          //               color: const Color(0xFFC3DBFF),
                          //               shape: RoundedRectangleBorder(
                          //                 borderRadius: BorderRadius.circular(
                          //                   999,
                          //                 ),
                          //               ),
                          //             ),
                          //             child: Center(
                          //               child: Icon(
                          //                 Icons.keyboard,
                          //                 color: const Color(0xFF4542EB),
                          //               ),
                          //             ), // Keyboard placeholder
                          //           ),
                          //         ],
                          //       ),
                          //       Container(
                          //         width: 80,
                          //         child: Column(
                          //           mainAxisSize: MainAxisSize.min,
                          //           mainAxisAlignment: MainAxisAlignment.start,
                          //           crossAxisAlignment:
                          //               CrossAxisAlignment.center,
                          //           spacing: 12,
                          //           children: [
                          //             Container(
                          //               width: 64,
                          //               height: 64,
                          //               padding: const EdgeInsets.all(10),
                          //               decoration: ShapeDecoration(
                          //                 color: const Color(0xFFC3DBFF),
                          //                 shape: RoundedRectangleBorder(
                          //                   borderRadius: BorderRadius.circular(
                          //                     999,
                          //                   ),
                          //                 ),
                          //               ),
                          //               child: Center(
                          //                 child: Icon(
                          //                   Icons.check,
                          //                   color: const Color(0xFF4542EB),
                          //                 ),
                          //               ),
                          //             ),
                          //             SizedBox(
                          //               width: 80,
                          //               child: Text(
                          //                 'Mark as done',
                          //                 textAlign: TextAlign.center,
                          //                 style: GoogleFonts.workSans(
                          //                   color: const Color(0xFF011F54),
                          //                   fontSize: 12,
                          //                   fontWeight: FontWeight.w600,
                          //                   height: 1,
                          //                 ),
                          //               ),
                          //             ),
                          //           ],
                          //         ),
                          //       ),
                          // ],
                          // ),
                          // ),
                        ],
                      );
                    }),
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
                      color: Colors.black54, // Dim background
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
        color: const Color(0xFFFFFCF1) /* Background-bg-secondary-light */,
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
        spacing: 16,
        children: [
          SizedBox(
            width: 230.19,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  'Call ending soon!',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54) /* Text-text-default */,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),
                SizedBox(
                  width: 230.19,
                  child: Text(
                    'You can add 10 more minutes to your call!',
                    style: GoogleFonts.workSans(
                      color: const Color(
                        0xFF595754,
                      ) /* Text-text-secondary-default */,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.60,
                    ),
                  ),
                ),
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(
                      0xFFFF8F26,
                    ) /* Background-bg-secondary */,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [
                      SizedBox(width: 18, height: 18, child: Stack()),
                      Text(
                        'Add 10 minutes',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(
                            0xFF011F54,
                          ) /* Text-text-default */,
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
        color: const Color(0xFFFFFDF7) /* Background-bg-white */,
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
        spacing: 16,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  '10 more minutes added',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54) /* Text-text-default */,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),
                SizedBox(
                  width: 230.19,
                  child: Text(
                    'You can now talk to me 10 more minutes!',
                    style: GoogleFonts.workSans(
                      color: const Color(
                        0xFF595754,
                      ) /* Text-text-secondary-default */,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.60,
                    ),
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
        color: const Color(0xFFFFFDF7) /* Background-bg-white */,
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
        spacing: 16,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 8,
              children: [
                SizedBox(width: 24, height: 24, child: Stack()),
                Text(
                  'You’re muted',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54) /* Text-text-default */,
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
        color: const Color(0xFFFDDBDC) /* Background-bg-error-light */,
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
        spacing: 16,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                SizedBox(width: 24, height: 24, child: Stack()),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      Text(
                        'Network error',
                        style: GoogleFonts.workSans(
                          color: const Color(
                            0xFF011F54,
                          ) /* Text-text-default */,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.20,
                          letterSpacing: -0.50,
                        ),
                      ),
                      SizedBox(
                        width: 255,
                        child: Text(
                          'Please check your internet connection!',
                          style: GoogleFonts.workSans(
                            color: const Color(
                              0xFF011F54,
                            ) /* Text-text-default */,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.60,
                          ),
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
        color: const Color(0xFFFFFDF7) /* Background-bg-white */,
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
        spacing: 16,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  'Wrap up already?',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54) /* Text-text-default */,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.20,
                    letterSpacing: -0.50,
                  ),
                ),
                SizedBox(
                  width: 230.19,
                  child: Text(
                    'No rush — but if you’re done, let’s mark this quest complete.',
                    style: GoogleFonts.workSans(
                      color: const Color(
                        0xFF595754,
                      ) /* Text-text-secondary-default */,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.60,
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
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
                              color: const Color(
                                0xFF6A68EF,
                              ) /* Border-border-subtle */,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              'Continue a bit longer',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.workSans(
                                color: const Color(
                                  0xFF4542EB,
                                ) /* Text-text-primary */,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 0.80,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        decoration: ShapeDecoration(
                          color: const Color(
                            0xFF3F3CD6,
                          ) /* Background-bg-primary-on-press */,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              'Yes, I’m done',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.workSans(
                                color: const Color(
                                  0xFFFFFDF7,
                                ) /* Text-text-light */,
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
      // Use isSpeaking to drive animation:
      final isSpeaking = controller.isSpeaking.value;

      return Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller.speakingAnimationController!,
            builder: (context, child) {
              // Scale between 1.0 and 1.2 if speaking
              final scale = isSpeaking
                  ? 1.0 + (controller.speakingAnimationController!.value * 0.2)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 210.w,
                  height: 210.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // ignore: deprecated_member_use
                    color: const Color(0xFF5B9DFF).withOpacity(0.1),
                  ),
                  // child: CustomPaint(
                  //   size: const Size(300, 300),
                  //   painter: RingPainter(0.25), // 75% progress
                  // ),
                ),
              );
            },
          ),

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
                  color: const Color(0xFF3B82F6), // Blue progress
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
                // Outer gradient circle (largest 3 number coclor)
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
                // Middle layer (optional rounded rectangle)
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
                        image: AssetImage("assets/dea_png/Popup_Speaking.png"),
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

    // Progress
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final startAngle = -3.14159 / 2; // Start from top
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

    // Start animations with staggered delay
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
      child: PoupSpking(
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

    // Background ring
    // final bgPaint = Paint()
    //   // ignore: deprecated_member_use
    //   ..color = Colors.blue.withOpacity(0.15)
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 12;

    // canvas.drawCircle(center, radius, bgPaint);

    // Progress ring (ellipse end here)
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3D87F5), Color(0xFF68A2F9)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round; // 🔥 ellipse shape

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
