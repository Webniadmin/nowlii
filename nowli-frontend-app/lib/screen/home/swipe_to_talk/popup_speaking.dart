import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';

class EmotionSpeakingScreen extends StatefulWidget {
  const EmotionSpeakingScreen({super.key});

  @override
  State<EmotionSpeakingScreen> createState() => _EmotionSpeakingScreenState();
}

class _EmotionSpeakingScreenState extends State<EmotionSpeakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isRecording = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Simulate recording - user will release to stop
    _startListening();
  }

  void _startListening() {
    // This will be triggered when user releases the hold
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isRecording) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    // Navigate to processing screen
    context.go(AppRoutespath.emotionProcessingScreen);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF91BBF9),
      body: SafeArea(
        child: GestureDetector(
          onLongPressEnd: (_) => _stopRecording(),
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
                    
                    // Center Avatar with Pulsing Animation
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outermost pulse circle
                                Container(
                                  width: size.width * 0.9 * _pulseController.value,
                                  height: size.width * 0.9 * _pulseController.value,
                                  decoration: BoxDecoration(
                                    color: Color(0x334542EB),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Middle pulse circle
                                Container(
                                  width: size.width * 0.69,
                                  height: size.width * 0.69,
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
                                // Listening Logo Image
                                Image.asset(
                                  'assets/images/listeningLogo.png',
                                  width: size.width * 0.35,
                                  height: size.width * 0.35,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Bottom Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Column(
                        children: [
                          Text(
                            r"I'm listening… take your time 💭",
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
      ),
    );
  }
}
