import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart' show Assets;
import 'package:nowlii/themes/text_styles.dart' show AppsTextStyles;
import 'package:nowlii/api/auth_controller.dart';

class ResetPasswordOtpScreen extends StatefulWidget {
  final String email;

  const ResetPasswordOtpScreen({super.key, required this.email});

  @override
  State<ResetPasswordOtpScreen> createState() => _ResetPasswordOtpScreenState();
}

class _ResetPasswordOtpScreenState extends State<ResetPasswordOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isButtonEnabled = false;
  bool _canResend = false;
  int _resendTimer = 30;
  Timer? _timer;
  final _authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (var controller in _otpControllers) {
      controller.addListener(_validateOtp);
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  void _validateOtp() {
    final isComplete = _otpControllers.every(
      (controller) => controller.text.isNotEmpty,
    );
    if (isComplete != _isButtonEnabled) {
      setState(() => _isButtonEnabled = isComplete);
    }
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  // ignore: deprecated_member_use
  void _onKeyPressed(RawKeyEvent event, int index) {
    // ignore: deprecated_member_use
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_canResend) {
      final success = await _authController.forgotPassword(widget.email);
      if (success) {
        _startResendTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP has been resent!'),
              backgroundColor: Color(0xFF4A3AFF),
            ),
          );
        }
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_isButtonEnabled) {
      final otp = _otpCode;
      final success = await _authController.verifyForgotPasswordOtp(
        widget.email,
        otp,
      );

      if (success) {
        if (mounted) {
          context.push('/enterNewPassword', extra: widget.email);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_authController.errorMessage.value),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Assets.svgIcons.backIconSvg.svg(
                  height: 60,
                  width: 60,
                ),
              ),
              const SizedBox(width: 12),
              Assets.svgIcons.signInPageIcon.svg(height: 80, width: 80),
            ],
          ),
        ),
        const SizedBox(height: 0),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            child: Text(
              'VERIFY',
              style: TextStyle(
                color: const Color(0xFF011F54),
                fontSize: 86,
                fontFamily: 'Wosker',
                fontWeight: FontWeight.w400,
                height: 0.80,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'We sent a verification code to',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF595754),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            widget.email,
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF011F54),
            ),
          ),
        ),
        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) => _buildOtpField(index)),
        ),
        const SizedBox(height: 30),

        Center(
          child: Column(
            children: [
              Text(
                "Didn't receive the code?",
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF595754),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _canResend ? _resendOtp : null,
                child: Text(
                  _canResend ? 'Resend OTP' : 'Resend OTP in ${_resendTimer}s',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _canResend
                        ? const Color(0xFFFF8F26)
                        : const Color(0xFF595754),
                    decoration: _canResend
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isButtonEnabled && !_authController.isLoading.value
                  ? _verifyOtp
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8F26),
                disabledBackgroundColor: const Color(0xFFFF8F26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _authController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppsTextStyles.continueButton.copyWith(
                        color: _isButtonEnabled
                            ? Colors.white
                            : const Color(0xFFA9A8F6),
                      ),
                      child: const Text("Verify"),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 50,
      height: 55,
      // ignore: deprecated_member_use
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onKeyPressed(event, index),
        child: TextFormField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: GoogleFonts.workSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF011F54),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFC3DBFF), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFC3DBFF), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFFF8F26), width: 2),
            ),
          ),
          onChanged: (value) => _onOtpChanged(value, index),
        ),
      ),
    );
  }
}
