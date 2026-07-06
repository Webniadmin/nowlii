import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(_controller);

    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future.delayed(Duration(seconds: 5));
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final accessToken = prefs.getString('access_token');
    
    // If user has valid access token, go to home
    if (accessToken != null && accessToken.isNotEmpty) {
      await prefs.setBool('is_new_user', false);
      if (!mounted) return;
      context.go('/homeScreen');
      return;
    }
    
    // No token - check if first time user
    if (isFirstTime) {
      // First time user - show onboarding
      if (!mounted) return;
      context.go('/entryScreen');
    } else {
      // Returning user without token - go to sign in
      if (!mounted) return;
      context.go('/signInScreen');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4542EB),
      body: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50), // Rounded border radius
            child: Image.asset(
              'assets/images/Android App Icon - Squircle.png', // তোমার PNG image path
              width: 154,
              height: 154,
              fit: BoxFit.contain, // optional
            ),
          ),
        ),
      ),
    );
  }
}
