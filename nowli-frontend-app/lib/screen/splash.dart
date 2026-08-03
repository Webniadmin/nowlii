import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/core/app_routes/app_pages.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/services/call_reminder_service.dart';
import 'package:nowlii/services/subscription_service.dart';
import 'package:nowlii/services/trial_intro_gate.dart';

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

      // Refresh entitlement before routing. On a fresh install this call is also what
      // STARTS the 7-day free trial (the backend grants it on first contact), so a new
      // user lands in the app with full access and nothing extra to tap.
      //
      // It doubles as the session check. A stored token can be rejected while still
      // unexpired — the server key was rotated, the session was blacklisted, the password
      // changed — and `getMyStatus` reports that 401 to Session, which tries a refresh and
      // signs out if it cannot recover. Without the check below the user would be waved
      // into a home screen where every request quietly fails.
      final status = await SubscriptionService().getMyStatus();
      if (!mounted) return;

      // Re-read from disk: Session clears storage through its own instance, so the copy
      // held here can be stale.
      await prefs.reload();
      if (!mounted) return;
      if ((prefs.getString('access_token') ?? '').isEmpty) {
        // Session ended during that call. Send them somewhere that works.
        context.go(AppRoutespath.signInScreen);
        return;
      }

      if (status != null && !status.hasAccess) {
        context.go(AppRoutespath.nowliProSubscription); // trial over, nothing bought
        return;
      }

      // Show the "7 days free" explainer once, the first time a trial is running.
      // Normally the end of onboarding gets there first; this catches an existing install
      // whose trial has only just been granted, and anyone who quit before reaching it.
      if (await claimTrialIntro(status)) {
        if (!mounted) return;
        context.go(AppRoutespath.subscriptionPage);
        return;
      }

      context.go('/homeScreen');

      // Lay down this week's call reminders now that we know who is logged in. Also
      // re-checks the quota, so a reminder for a call the user can no longer make says so
      // rather than inviting them into a refusal. Fire-and-forget: never block the launch.
      unawaited(CallReminderService.instance.sync());

      // A reminder that started the app from cold never reaches the tap handler — the app
      // was not running to receive it. Pick it up here instead.
      unawaited(_openReminderThatLaunchedTheApp());
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

  /// If a call reminder launched the app, go straight to that call.
  ///
  /// Pushed on top of the home screen (rather than replacing it) so backing out of the call
  /// lands somewhere sensible instead of on a dead route.
  Future<void> _openReminderThatLaunchedTheApp() async {
    final response = await CallReminderService.instance.launchReminder();
    final parsed = CallReminderService.parsePayload(response?.payload);
    if (parsed == null || !mounted) return;

    final (scheduledCallId, questTitle) = parsed;
    AppPages.router.push(
      AppRoutespath.aiVoice,
      extra: {'questTitle': questTitle, 'scheduledCallId': scheduledCallId},
    );
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
