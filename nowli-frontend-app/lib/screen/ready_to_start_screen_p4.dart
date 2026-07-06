import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';
import 'package:nowlii/api/google_sign_in_flow.dart';

class ReadyToStartScreen extends StatefulWidget {
  const ReadyToStartScreen({super.key});

  @override
  State<ReadyToStartScreen> createState() => _ReadyToStartScreenState();
}

class _ReadyToStartScreenState extends State<ReadyToStartScreen>
    with SingleTickerProviderStateMixin {
  bool _isWelcomeBack = true;
  late AnimationController _animController;
  late Animation<double> _backButtonFade;
  late Animation<Offset> _backButtonSlide;
  late Animation<double> _illustrationScale;
  late Animation<double> _illustrationFade;
  late Animation<double> _button1Scale;
  late Animation<double> _button1Fade;
  late Animation<double> _button2Scale;
  late Animation<double> _button2Fade;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _backButtonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _backButtonSlide = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutCubic),
      ),
    );

    _illustrationScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _illustrationFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _button1Scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 0.75, curve: Curves.elasticOut),
      ),
    );

    _button1Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    _button2Scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.6, 0.85, curve: Curves.elasticOut),
      ),
    );

    _button2Fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsApps.lightBlueBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SlideTransition(
                  position: _backButtonSlide,
                  child: FadeTransition(
                    opacity: _backButtonFade,
                    child: SizedBox(
                      width: 57,
                      height: 55,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.black87,
                            size: 34,
                          ),
                          onPressed: () {
                            context.pop();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Illustration - tap to toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isWelcomeBack = !_isWelcomeBack;
                  });
                },
                child: Center(
                  child: ScaleTransition(
                    scale: _illustrationScale,
                    child: FadeTransition(
                      opacity: _illustrationFade,
                      child: _isWelcomeBack
                          ? Assets.svgImages.welcomeBack.svg(height: 180)
                          : Assets.svgImages.readyToStart.svg(height: 180),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Google Button
              ScaleTransition(
                scale: _button1Scale,
                child: FadeTransition(
                  opacity: _button1Fade,
                  child: SizedBox(
                    width: double.infinity,
                    height: 74,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A46FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      icon:
                          Assets.svgIcons.googleIcon.svg(height: 24, width: 24),
                      label: Text(
                        'Continue with Google',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFFFFFDF7),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 0.80,
                        ),
                      ),
                      onPressed: () => handleGoogleSignIn(context),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Apple Button
              ScaleTransition(
                scale: _button2Scale,
                child: FadeTransition(
                  opacity: _button2Fade,
                  child: SizedBox(
                    width: double.infinity,
                    height: 74,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A46FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      icon:
                          Assets.svgIcons.appleIcon.svg(height: 24, width: 24),
                      label: Text(
                        'Continue with Apple',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFFFFFDF7),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 0.80,
                        ),
                      ),
                      onPressed: () => handleAppleSignIn(context),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              FadeTransition(
                opacity: _textFade,
                child: SizedBox(
                  width: double.infinity,
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        height: 1.60,
                        color: const Color(0xFF4C586E),
                      ),
                      children: [
                        const TextSpan(
                          text: 'By signing up, you agree to Nowlii\'s ',
                        ),
                        TextSpan(
                          text: 'Privacy Policy ',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4542EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: '  & '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
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
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
