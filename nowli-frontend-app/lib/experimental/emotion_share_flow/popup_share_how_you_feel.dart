import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';

class EmotionShareScreen extends StatefulWidget {
  const EmotionShareScreen({super.key});

  @override
  State<EmotionShareScreen> createState() => _EmotionShareScreenState();
}

class _EmotionShareScreenState extends State<EmotionShareScreen> {
  bool _isListening = false;

  void _startRecording() {
    setState(() {
      _isListening = true;
    });
    // Show listening animation for a moment before navigating
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.go(AppRoutespath.emotionSpeakingScreen);
      }
    });
  }

  void _stopRecording() {
    setState(() {
      _isListening = false;
    });
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
                  
                  // Center Avatar with Animation
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressEnd: (_) => _stopRecording(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow circle
                            Container(
                              width: size.width * 0.64,
                              height: size.width * 0.64,
                              decoration: BoxDecoration(
                                color: const Color(0x664542EB),
                                shape: BoxShape.circle,
                              ),
                            ),
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
                            // Logo Image (changes based on listening state)
                            Image.asset(
                              _isListening 
                                ? 'assets/images/listeningLogo.png'
                                : 'assets/images/beforeLisentingLogo.png',
                              width: size.width * 0.35,
                              height: size.width * 0.35,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      children: [
                        Text(
                          'Hold to speak 🎙️\nNowlii will listen once you say something.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF4542EB),
                            fontSize: 18,
                            fontFamily: 'Work Sans',
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            letterSpacing: -0.9,
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
