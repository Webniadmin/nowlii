import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart' show Assets;
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/themes/text_styles.dart' show AppsTextStyles;
import 'package:nowlii/api/auth_controller.dart';
import 'package:nowlii/api/google_sign_in_flow.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _isButtonEnabled = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isEmailValid = true;
  final _authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(() {
      _onEmailChanged(_emailController.text);
    });
    _passwordController.addListener(_validateForm);

    // 👇 Add listeners to rebuild UI when focus changes
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ✅ Check if any field is focused
  bool get _isAnyFieldFocused =>
      _nameFocus.hasFocus || _emailFocus.hasFocus || _passwordFocus.hasFocus;

  void _validateForm() {
    final isValid =
        _nameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
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

  Future<void> _handleSignUp() async {
    final success = await _authController.register(
      _emailController.text,
      _nameController.text,
      _passwordController.text,
    );

    if (success) {
      if (mounted) {
        context.push(
          AppRoutespath.otpVerificationScreen,
          extra: _emailController.text,
        );
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
      backgroundColor: const Color(0xFFDFEFFF),
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
        // 🔙 Back button + logo
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Assets.svgIcons.signUnBackScrren.svg(
                  height: 60,
                  width: 60,
                ),
              ),
              const SizedBox(width: 12),
              // Assets.svgIcons.appStoreAppIconSvg.svg(height: 80, width: 80),
              Image.asset(
                'assets/images/sadik.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            child: Text(
              'SIGN UP',
              style: TextStyle(
                color: const Color(0xFF011F54) /* Background-bg-dark */,
                fontSize: 86,
                fontFamily: 'Wosker',
                fontWeight: FontWeight.w400,
                height: 0.80,
              ),
            ),
          ),
        ),
        const SizedBox(height: 0),

        // 🧑 Name Field
        SizedBox(
          height: 64,
          child: TextFormField(
            controller: _nameController,
            focusNode: _nameFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_emailFocus),
            decoration: InputDecoration(
              labelText: "Full Name",
              hintText: "Maria",
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              floatingLabelAlignment: FloatingLabelAlignment.start,
              floatingLabelStyle: TextStyle(
                color: const Color(0xFF4A3AFF),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF4C586E),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFC3DBFF),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFC3DBFF),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF4A3AFF),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _nameController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 5),
        // const SizedBox(height: 8),

        // 📧 Email Field
        SizedBox(
          height: 64,
          child: TextFormField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passwordFocus),
            decoration: InputDecoration(
              labelText: "Email Address",
              hintText: "maria@gmail.com",
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              floatingLabelAlignment: FloatingLabelAlignment.start,
              floatingLabelStyle: TextStyle(
                color: (!_isEmailValid && _emailController.text.isNotEmpty)
                    ? Colors.red
                    : const Color(0xFF4A3AFF),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF4C586E),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFC3DBFF),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFC3DBFF),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF4A3AFF),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              suffixIcon: _emailController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        _isEmailValid
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        size: 20,
                        color: _isEmailValid ? Colors.green : Colors.red,
                      ),
                      onPressed: () => _emailController.clear(),
                    ),
            ),
            onChanged: _onEmailChanged,
          ),
        ),
        if (!_isEmailValid && _emailController.text.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Text(
              "Please enter a valid email address.",
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 5),

        // 🔒 Password Field
        SizedBox(
          height: 64,
          child: TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: "Password",
              hintText: "*****",
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              floatingLabelAlignment: FloatingLabelAlignment.start,
              floatingLabelStyle: TextStyle(
                color: const Color(0xFF4A3AFF),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              labelStyle: const TextStyle(
                color: Color(0xFF4C586E),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFC3DBFF),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFC3DBFF),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFF4A3AFF),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.workSans(
                fontSize: 14,
                height: 1.60,
                color: const Color(0xFF4C586E),
              ),
              children: [
                const TextSpan(text: 'By signing up, you agree to Nowlii’s'),
                TextSpan(
                  text: 'Privacy Policy ',
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4542EB),
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: '&'),
                TextSpan(
                  text: 'Terms of Service',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4542EB),
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),

        // 🔘 Continue Button
        SizedBox(height: 20),
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isButtonEnabled && !_authController.isLoading.value
                  ? _handleSignUp
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A3AFF),
                disabledBackgroundColor: const Color(0xFF4A3AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _authController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: AppsTextStyles.continueButton.copyWith(
                        color: _isAnyFieldFocused
                            ? Colors.white
                            : const Color(0xFFA9A8F6),
                      ),
                      child: const Text("Continue"),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: const [
            Expanded(child: Divider(thickness: 2, color: Color(0xFFC3DBFF))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("or", style: TextStyle(color: Color(0xFF4C586E))),
            ),
            Expanded(child: Divider(thickness: 2, color: Color(0xFFC3DBFF))),
          ],
        ),
        const SizedBox(height: 25),

        _socialButton(
          icon: Assets.svgIcons.googleIconsBlue.path,
          text: "Continue with Google",
          onPressed: () => handleGoogleSignIn(context),
        ),
        const SizedBox(height: 15),
        _socialButton(
          icon: Assets.svgIcons.appleIconsBlue.path,
          text: "Continue with Apple",
          onPressed: () => handleAppleSignIn(context),
        ),
        const SizedBox(height: 60),

        Center(
          child: RichText(
            text: TextSpan(
              text: "Already have an account? → ",
              style: AppsTextStyles.workSansSemiBold16,
              children: [
                TextSpan(
                  text: "Sign in",
                  style: AppsTextStyles.workSansSemiBold16SignInalredy,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Navigate to the Sign-In page
                      context.push("/signInScreen");
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required String icon,
    required String text,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF4542EB), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: onPressed ??
            () {
              context.push("/onboardingFlow");
            },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(icon, height: 20, width: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: AppsTextStyles.googleContinueButton,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _socialButton({required String icon, required String text}) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 60,
  //     child: OutlinedButton.icon(
  //       icon: SvgPicture.asset(icon, height: 20, width: 20),
  //       SizedBox(width: 12),
  //       label: Text(text, style: AppsTextStyles.googleContinueButton),
  //       style: OutlinedButton.styleFrom(
  //         side: const BorderSide(color: Color(0xFF4542EB), width: 2),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(30),
  //         ),
  //       ),
  //       onPressed: () {},
  //     ),
  //   );
  // }
}
