import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Voice Check / AI Call States
enum VoiceCheckState { idle, recording, processing, error }

enum AiCallState {
  ongoing,
  endingSoon,
  minutesAdded,
  muted,
  networkError,
  callEnded,
  questCompleted,
}

/// Controller for Voice Check Popup / AI Call
class VoiceCheckController extends GetxController
    with GetTickerProviderStateMixin {
  final state = VoiceCheckState.idle.obs;
  final aiCallState = AiCallState.ongoing.obs; // New generic call state
  final recordingDuration = Duration.zero.obs;
  final isRecording = false.obs;

  // Simulation trigger (for demo purposes)
  final isSpeaking = false.obs;

  Timer? _recordingTimer;
  Timer? _silenceTimer;
  Timer? _callDurationTimer;
  AnimationController? pulseController;
  AnimationController? speakingAnimationController;

  @override
  void onInit() {
    super.onInit();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animation for "RingPainter tar circile e RIngPainter ta barte takbe"
    speakingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Start timer to show "Call ending soon" after 1 minute
    _callDurationTimer = Timer(const Duration(minutes: 1), () {
      aiCallState.value = AiCallState.endingSoon;
    });

    // After 2 minutes, quest is completed
    Timer(const Duration(minutes: 2), () {
      aiCallState.value = AiCallState.questCompleted;
    });
  }

  @override
  void onClose() {
    _recordingTimer?.cancel();
    _silenceTimer?.cancel();
    _callDurationTimer?.cancel();
    pulseController?.dispose();
    speakingAnimationController?.dispose();
    super.onClose();
  }

  void startRecording() {
    state.value = VoiceCheckState.recording;
    isRecording.value = true;
    isSpeaking.value = true; // Simulate speaking when recording starts
    pulseController?.repeat();

    // Start recording timer
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordingDuration.value += const Duration(seconds: 1);
    });

    // Start silence detection timer (extended for demo)
    _silenceTimer = Timer(const Duration(seconds: 30), () {
      stopRecording();
    });
  }

  void stopRecording({bool hasVoice = true}) {
    _recordingTimer?.cancel();
    _silenceTimer?.cancel();
    pulseController?.stop();
    isRecording.value = false;
    isSpeaking.value = false;

    if (!hasVoice) {
      state.value = VoiceCheckState.error;
      recordingDuration.value = Duration.zero;
    } else {
      state.value = VoiceCheckState.processing;
      _processVoiceNote();
    }
  }

  void _processVoiceNote() async {
    await Future.delayed(const Duration(seconds: 2));
    Get.back(closeOverlays: true);
  }

  void resetToIdle() {
    state.value = VoiceCheckState.idle;
    aiCallState.value = AiCallState.ongoing;
    recordingDuration.value = Duration.zero;
  }

  void dismissPopup(BuildContext context) {
    Navigator.of(context).pop();
  }

  VoidCallback getDismissCallback(BuildContext context) {
    return () => Navigator.of(context).pop();
  }

  String getFormattedTime() {
    final minutes = recordingDuration.value.inMinutes.toString().padLeft(
      2,
      '0',
    );
    final seconds = (recordingDuration.value.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds';
  }
}
