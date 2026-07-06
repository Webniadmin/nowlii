import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_controller.dart';
import 'package:nowlii/services/profile_service.dart';

/// Shared "Continue with Google" flow used by every auth screen.
Future<void> handleGoogleSignIn(BuildContext context) async {
  final authController = Get.put(AuthController());
  final success = await authController.signInWithGoogle();
  await _routeAfterSocialLogin(context, authController, success);
}

/// Shared "Continue with Apple" flow used by every auth screen.
Future<void> handleAppleSignIn(BuildContext context) async {
  final authController = Get.put(AuthController());
  final success = await authController.signInWithApple();
  await _routeAfterSocialLogin(context, authController, success);
}

/// After any social login: existing profile → home, otherwise → onboarding.
/// On failure/cancellation, show a red snackbar.
Future<void> _routeAfterSocialLogin(
  BuildContext context,
  AuthController authController,
  bool success,
) async {
  if (!context.mounted) return;

  if (success) {
    final profile = await ProfileService().fetchProfile();
    if (!context.mounted) return;

    if (profile != null && profile.name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_new_user', false);
      if (!context.mounted) return;
      context.go('/homeScreen');
    } else {
      context.push('/onboardingFlow');
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
