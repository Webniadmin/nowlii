import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emotion_detection_helper.dart';

class EmotionProcessingScreen extends StatefulWidget {
  const EmotionProcessingScreen({super.key});

  @override
  State<EmotionProcessingScreen> createState() => _EmotionProcessingScreenState();
}

class _EmotionProcessingScreenState extends State<EmotionProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  int _activeDot = 0;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _activeDot = (_dotController.value * 4).floor() % 4;
          });
        }
      });
    
    _dotController.repeat();
    
    // After processing, mark as complete and go to home
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        await EmotionDetectionHelper.markEmotionDetectionComplete();
        
        // Set flag to show popup on home screen
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('show_voice_saved_popup', true);
        
        // Go to home screen where popup will be shown
        context.go(AppRoutespath.homeScreen);
      }
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF91BBF9),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDFEFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(750),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const SizedBox(width: 20, height: 20),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 24, height: 24),
                      const SizedBox(width: 8),
                      Text(
                        'AI',
                        style: TextStyle(
                          color: const Color(0xFF4542EB),
                          fontSize: 28,
                          fontFamily: 'Work Sans',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title and Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
                    child: Column(
                      children: [
                        Text(
                          'SHARE HOW YOU FEEL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF011F54),
                            fontSize: size.width * 0.12,
                            fontFamily: 'Wosker',
                            fontWeight: FontWeight.w400,
                            height: 0.9,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          'Tell me how you feel today - no pressure, just say it out loud. 🎧',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF011F54),
                            fontSize: 18,
                            fontFamily: 'Work Sans',
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Center with Processing Animation
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Inner gradient circle
                          Container(
                            width: size.width * 0.48,
                            height: size.width * 0.48,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.73,
                                colors: [
                                  const Color(0xFF7270F3),
                                  const Color(0xFF3F3CD6)
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x995550FF),
                                  blurRadius: 20,
                                  spreadRadius: 11,
                                ),
                              ],
                            ),
                          ),
                          // Animated dots
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(4, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: _activeDot == index
                                      ? const Color(0xFFA4CAFE)
                                      : const Color(0xFFA4CAFE).withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      children: [
                        Text(
                          'Got it — thanks for sharing 💭',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4542EB),
                            fontSize: 20,
                            fontFamily: 'Work Sans',
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Bottom indicator
                        Container(
                          width: 134,
                          height: 5,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFFFFEF8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
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
      ),
    );
  }
}
