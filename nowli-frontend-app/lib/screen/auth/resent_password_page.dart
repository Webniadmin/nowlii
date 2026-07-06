import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart' show Assets;
import 'package:nowlii/themes/text_styles.dart' show AppsTextStyles;
import 'package:nowlii/api/auth_controller.dart';

class ResentPasswordPage extends StatefulWidget {
  const ResentPasswordPage({super.key});

  @override
  State<ResentPasswordPage> createState() => _ResentPasswordPageState();
}

class _ResentPasswordPageState extends State<ResentPasswordPage> {
  bool _isButtonEnabled = false;

  final _emailController = TextEditingController();

  final _emailFocus = FocusNode();

  bool _isEmailValid = true;
  final _authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => _onEmailChanged(_emailController.text));
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid =
        _emailController.text.isNotEmpty &&
        _isValidEmail(_emailController.text);
    if (isValid != _isButtonEnabled) {
      setState(() => _isButtonEnabled = isValid);
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  void _onEmailChanged(String value) {
    final valid = value.isEmpty || _isValidEmail(value);
    if (valid != _isEmailValid) {
      setState(() => _isEmailValid = valid);
    }
    _validateForm();
  }

  Future<void> _handleForgotPassword() async {
    final success = await _authController.forgotPassword(_emailController.text);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email!'),
            backgroundColor: Colors.green,
          ),
        );
        context.push('/resetPasswordOtpScreen', extra: _emailController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Icons Row
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
                    Assets.svgIcons.signInPageIcon.svg(height: 57, width: 62),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: SizedBox(
                  width: 335,
                  child: Text(
                    'RESET PASSWORD',
                    style: TextStyle(
                      color: const Color(0xFF011F54) /* Background-bg-dark */,
                      fontSize: 58,
                      fontFamily: 'Wosker',
                      fontWeight: FontWeight.w400,
                      height: 0.70,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  Text(
                    "Don't worry. It happens to the best of us.",
                    style: GoogleFonts.workSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF595754),
                      height: 1.20,
                      letterSpacing: -0.50,
                    ),
                  ),
                  Text(
                    'Enter your email to get back on track.',
                    style: GoogleFonts.workSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF595754),
                      height: 1,
                      letterSpacing: -0.50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Email Input Field
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                style: GoogleFonts.workSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: "Email address",
                  labelStyle: GoogleFonts.workSans(
                    color: const Color(0xFF595754),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.40,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  floatingLabelStyle: GoogleFonts.workSans(
                    color: _emailFocus.hasFocus
                        ? const Color(0xFF4542EB)
                        : const Color(0xFF595754),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  constraints: const BoxConstraints(minHeight: 64),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFC3DBFF),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFC3DBFF),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF4542EB),
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  suffixIcon: _emailController.text.isEmpty
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            _isEmailValid ? Icons.check_circle : Icons.cancel,
                            size: 22,
                            color: _isEmailValid
                                ? Colors.green
                                // ignore: deprecated_member_use
                                : const Color(0xFF4542EB).withOpacity(0.5),
                          ),
                        ),
                ),
                onChanged: _onEmailChanged,
              ),
              if (!_isEmailValid && _emailController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    "Please enter a valid email address.",
                    style: GoogleFonts.workSans(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Continue Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 65.h,
                  child: ElevatedButton(
                    onPressed: _isButtonEnabled && !_authController.isLoading.value
                        ? _handleForgotPassword
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F26),
                      disabledBackgroundColor: const Color(0xFFFF8F26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: _authController.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Send Reset Link",
                            style: AppsTextStyles.sendResetLinkButton,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Divider with "or"

              // Sign In Text
              GestureDetector(
                onTap: _isButtonEnabled ? _handleForgotPassword : null,
                child: SizedBox(
                  width: 335,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Didn't get the email? → ",
                          style: GoogleFonts.workSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF011F54),
                            height: 1,
                            letterSpacing: -0.50,
                          ),
                        ),
                        TextSpan(
                          text: 'Resend link',
                          style: GoogleFonts.workSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF8F26),
                            height: 1,
                            letterSpacing: -0.50,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
