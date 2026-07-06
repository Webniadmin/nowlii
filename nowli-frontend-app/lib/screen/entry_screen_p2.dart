import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _imageOpacity;
  late Animation<Offset> _containerSlide;
  late Animation<double> _containerOpacity;
  late Animation<Offset> _headingSlide;
  late Animation<double> _headingOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _button1Scale;
  late Animation<double> _button1Opacity;
  late Animation<double> _button2Scale;
  late Animation<double> _button2Opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Image fade in
    _imageOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Container slide up from bottom
    _containerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _containerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    // Heading slide from left
    _headingSlide = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _headingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
      ),
    );

    // Subtitle slide from left (delayed)
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    // Button 1 scale and fade
    _button1Scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.85, curve: Curves.elasticOut),
      ),
    );

    _button1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 0.85, curve: Curves.easeOut),
      ),
    );

    // Button 2 scale and fade (delayed)
    _button2Scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 0.95, curve: Curves.elasticOut),
      ),
    );

    _button2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 0.95, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: w,
              height: h * 0.777, // 631/812
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(1.00, 0.10),
                  end: Alignment(-0.00, 0.11),
                  colors: [Color(0xFF6991B2), Color(0xFF80A1B9)],
                ),
              ),
            ),
          ),

          // Background Image with fade
          Positioned(
            left: 0,
            top: h * 0.071, // 58/812
            child: FadeTransition(
              opacity: _imageOpacity,
              child: Container(
                width: w,
                height: h * 0.649, // 527.57/812
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: AssetImage(Assets.svgImages.enttryTwoScrenn.path),
                    fit: BoxFit.cover,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.25),
                  ),
                ),
              ),
            ),
          ),



          // Bottom rounded container with slide and fade
          Positioned(
            left: 0,
            top: h * 0.503, // 409/812
            child: SlideTransition(
              position: _containerSlide,
              child: FadeTransition(
                opacity: _containerOpacity,
                child: Container(
                  width: w,
                  padding: EdgeInsets.only(
                    top: h * 0.049, // 40/812
                    left: w * 0.053, // 20/375
                    right: w * 0.053,
                    bottom: h * 0.041, // 34/812
                  ),
                  decoration: const ShapeDecoration(
                    color: Color(0xFF4542EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading with slide and fade
                      SlideTransition(
                        position: _headingSlide,
                        child: FadeTransition(
                          opacity: _headingOpacity,
                          child: SizedBox(
                            width: w * 0.893, // 335/375
                            child: Text(
                              'LET\'S GET THINGS DONE.',
                              style: TextStyle(
                                color: const Color(0xFFFFFDF7),
                                fontSize: w * 0.138, // 52/375
                                fontFamily: 'Wosker',
                                fontWeight: FontWeight.w400,
                                height: 0.80,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.019), // 16/812

                      // Subtitle with slide and fade
                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _subtitleOpacity,
                          child: SizedBox(
                            width: w * 0.837, // 314/375
                            child: Text(
                              'Your daily push to start - with real voice support.',
                              style: GoogleFonts.workSans(
                                color: const Color(0xFFC8CBD2),
                                fontSize: w * 0.048, // 18/375
                                fontWeight: FontWeight.w400,
                                height: 1.40,
                                letterSpacing: -0.72,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.029), // 24/812

                      // Get Started Button with scale and fade
                      ScaleTransition(
                        scale: _button1Scale,
                        child: FadeTransition(
                          opacity: _button1Opacity,
                          child: Container(
                            width: double.infinity,
                            height: h * 0.098, // 80/812
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8F26),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: w * 0.106, // 40/375
                                  vertical: h * 0.034, // 28/812
                                ),
                              ),
                              onPressed: () {
                                context.push("/readyToStartScreen");
                              },
                              child: Text(
                                'Get Started',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF011F54),
                                  fontSize: w * 0.064, // 24/375
                                  fontWeight: FontWeight.w900,
                                  height: 0.80,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.009), // 8/812

                      // Have an Account Button with scale and fade
                      ScaleTransition(
                        scale: _button2Scale,
                        child: FadeTransition(
                          opacity: _button2Opacity,
                          child: Container(
                            width: double.infinity,
                            height: h * 0.098, // 80/812
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  width: 2,
                                  color: Color(0xFFFFFDF7),
                                ),
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: w * 0.106,
                                  vertical: h * 0.034,
                                ),
                              ),
                              onPressed: () {
                                context.push("/signInScreen");
                              },
                              child: Text(
                                'Have an account?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFFFFFDF7),
                                  fontSize: w * 0.064, // 24/375
                                  fontWeight: FontWeight.w900,
                                  height: 0.80,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}