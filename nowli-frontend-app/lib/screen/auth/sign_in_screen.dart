import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/core/gen/assets.gen.dart' show Assets;
import 'package:nowlii/screen/auth/sign_in_controller.dart';
import 'package:nowlii/themes/text_styles.dart' show AppsTextStyles;
import 'package:nowlii/api/auth_controller.dart';
import 'package:nowlii/api/google_sign_in_flow.dart' show handleAppleSignIn;
import 'package:nowlii/services/profile_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonScale;
  late Animation<double> _buttonFade;
  late Animation<double> _socialFade;
  late Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 0.75, curve: Curves.elasticOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    _socialFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 0.9, curve: Curves.easeOut),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn(
    BuildContext context,
    SignInController controller,
    AuthController authController,
  ) async {
    final success = await authController.login(
      controller.emailController.text,
      controller.passwordController.text,
    );

    if (success) {
      if (context.mounted) {
        // Check if user has completed profile setup
        final profileService = ProfileService();
        final profile = await profileService.fetchProfile();
        
        if (profile != null && profile.name.isNotEmpty) {
          // Profile exists - Returning user
          print('✅ Profile found - Navigating to home screen');
          
          // Ensure is_new_user flag is false for returning users
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_new_user', false);
          
          context.go('/homeScreen');
        } else {
          // No profile - go to onboarding
          print('⚠️ No profile found - Starting onboarding');
          context.push("/onboardingFlow");
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authController.errorMessage.value),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn(
    BuildContext context,
    AuthController authController,
  ) async {
    final success = await authController.signInWithGoogle();
    if (!context.mounted) return;

    if (success) {
      // Same profile-based routing as email login.
      final profileService = ProfileService();
      final profile = await profileService.fetchProfile();
      if (!context.mounted) return;

      if (profile != null && profile.name.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_new_user', false);
        if (!context.mounted) return;
        context.go('/homeScreen');
      } else {
        context.push("/onboardingFlow");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage.value),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignInController());
    final authController = Get.put(AuthController());

    InputDecoration fieldDecoration({
      required String label,
      required String hint,
      Widget? suffixIcon,
      required TextStyle labelStyle,
    }) {
      const borderSide = BorderSide(color: Color(0xFFC3DBFF), width: 1);
      final borderRadius = BorderRadius.circular(16);

      final fixedBorder = OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
        gapPadding: 8,
      );

      return InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelStyle: labelStyle,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFFFFEF8),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 24,
        ),
        enabledBorder: fixedBorder,
        focusedBorder: fixedBorder,
        errorBorder: fixedBorder.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: fixedBorder.copyWith(
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: suffixIcon,
      );
    }

    Widget socialButton({
      required String icon,
      required String text,
      VoidCallback? onPressed,
    }) {
      return SizedBox(
        width: double.infinity,
        height: 64,
        child: OutlinedButton.icon(
          icon: SvgPicture.asset(icon, height: 24, width: 24),
          label: Text(text, style: AppsTextStyles.workSansSemiBold16signIn),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF011F54), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: onPressed ??
              () {
                context.push("/onboardingFlow");
              },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Icons Row with animation
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Assets.svgIcons.backIconSvg.svg(
                          height: 80,
                          width: 80,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Assets.svgIcons.signInPageIcon.svg(height: 80, width: 80),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // Title with animation
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'SIGN IN',
                      style: TextStyle(
                        color: Color(0xFF011F54),
                        fontSize: 86,
                        fontFamily: 'Wosker',
                        fontWeight: FontWeight.w400,
                        height: 0.80,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // Form fields with animation
              SlideTransition(
                position: _formSlide,
                child: FadeTransition(
                  opacity: _formFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Field
                      Obx(() {
                        final isValid = controller.isEmailValid.value;
                        final hasText =
                            controller.emailController.text.isNotEmpty;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 59,
                              child: TextFormField(
                                controller: controller.emailController,
                                focusNode: controller.emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(controller.passwordFocus),
                                decoration: fieldDecoration(
                                  label: "Email address",
                                  hint: "",
                                  labelStyle:
                                      AppsTextStyles.fullNameAndEmailSignIn,
                                  suffixIcon: !hasText
                                      ? null
                                      : IconButton(
                                          icon: Icon(
                                            isValid
                                                ? Icons.check_circle
                                                : Icons.warning_amber_rounded,
                                            size: 20,
                                            color: isValid
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          onPressed: () => controller
                                              .emailController
                                              .clear(),
                                        ),
                                ),
                              ),
                            ),
                            if (!isValid && hasText) ...[
                              const SizedBox(height: 6),
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text(
                                  "Please enter a valid email address.",
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        );
                      }),

                      const SizedBox(height: 10),

                      // Password Field
                      Obx(
                        () => SizedBox(
                          height: 59,
                          child: TextFormField(
                            controller: controller.passwordController,
                            focusNode: controller.passwordFocus,
                            obscureText: controller.obscurePassword.value,
                            textInputAction: TextInputAction.done,
                            decoration: fieldDecoration(
                              label: "Password",
                              hint: "*****",
                              labelStyle:
                                  AppsTextStyles.fullNameAndEmailSignIn,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscurePassword.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Forgot Password Row
                      _buildForgotPasswordRow(context),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Continue Button with animation
              ScaleTransition(
                scale: _buttonScale,
                child: FadeTransition(
                  opacity: _buttonFade,
                  child: Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: !authController.isLoading.value
                            ? () => _handleSignIn(context, controller, authController)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8F26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: authController.isLoading.value
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Continue",
                                style: AppsTextStyles.signInContinueButton,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Divider with "or"
              FadeTransition(
                opacity: _socialFade,
                child: const Row(
                  children: [
                    Expanded(
                        child: Divider(thickness: 1, color: Colors.black26)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child:
                          Text("or", style: TextStyle(color: Colors.black54)),
                    ),
                    Expanded(
                        child: Divider(thickness: 1, color: Colors.black26)),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Social Buttons with animation
              FadeTransition(
                opacity: _socialFade,
                child: Column(
                  children: [
                    socialButton(
                      icon: Assets.svgIcons.signInGoole.path,
                      text: "Continue with Google",
                      onPressed: () =>
                          _handleGoogleSignIn(context, authController),
                    ),
                    const SizedBox(height: 15),
                    socialButton(
                      icon: Assets.svgIcons.appleIconSignIn.path,
                      text: "Continue with Apple",
                      onPressed: () => handleAppleSignIn(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 90),

              // Sign Up Link with animation
              FadeTransition(
                opacity: _footerFade,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? → ",
                      style: AppsTextStyles.workSansSemiBold16,
                      children: [
                        TextSpan(
                          text: "Sign up",
                          style:
                              AppsTextStyles.workSansSemiBold16SignInAlread,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.push("/signUpScreen");
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Forgot password?',
            style: GoogleFonts.workSans(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF595754),
              letterSpacing: -0.50,
            ),
          ),
        ),
        Flexible(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'It happens! ',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF595754),
                    letterSpacing: -0.50,
                  ),
                ),
                TextSpan(
                  text: 'Reset it here.',
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF011F54),
                    letterSpacing: -0.50,
                    decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF011F54),
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    context.push("/resentPasswordPage");
                  },
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }
}
