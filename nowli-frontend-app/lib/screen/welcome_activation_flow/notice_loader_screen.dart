import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/api/profile_controller.dart';
import 'package:nowlii/api/file_helper.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/services/subscription_service.dart';
import 'package:nowlii/services/trial_intro_gate.dart';

class NoticeLoaderScreen extends StatefulWidget {
  const NoticeLoaderScreen({super.key});

  @override
  State<NoticeLoaderScreen> createState() => _NoticeLoaderScreenState();
}

class _NoticeLoaderScreenState extends State<NoticeLoaderScreen> {
  final ProfileController _profileController = ProfileController();

  /// Gates both "onboarding is done" and where we navigate next.
  bool _profileCreated = false;

  @override
  void initState() {
    super.initState();
    _completeOnboardingAndCreateProfile();
  }

  Future<void> _completeOnboardingAndCreateProfile() async {
    // Get all collected onboarding data
    final onboardingData = OnboardingData();

    // Create profile with all collected data
    if (onboardingData.isComplete) {
      // Convert avatar logo asset to file if it's an asset path
      final avatarLogoPath = onboardingData.avatarLogo;
      File? avatarLogoFile;
      
      if (avatarLogoPath != null && FileHelper.isAssetPath(avatarLogoPath)) {
        // A null result is tolerated: the profile is still created, just
        // without the bundled image file.
        avatarLogoFile = await FileHelper.assetToFile(avatarLogoPath);
      }
      
      final success = await _profileController.createProfile(
        name: onboardingData.name!,
        gender: onboardingData.gender!,
        language: onboardingData.language!,
        voice: onboardingData.voice!,
        profileImage: onboardingData.profileImage,
        avatarLogo: onboardingData.avatarLogo,  // ✅ Add avatar logo URL
        nowliiName: onboardingData.nowliiName,
        customNowliiName: onboardingData.customNowliiName,
        avatarLogoFile: avatarLogoFile,
      );

      if (success) {
        _profileCreated = true;
        // Mark user as new user (for showing tooltips on first home screen visit)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_new_user', true);

        // Only safe to discard the answers once they exist on the server.
        await onboardingData.clear();
      } else if (kDebugMode) {
        debugPrint(
          'Profile creation failed: ${_profileController.errorMessage}',
        );
      }
    } else if (kDebugMode) {
      debugPrint('Onboarding data incomplete — profile not created');
    }

    // `isFirstTime` used to be cleared unconditionally, including when the
    // profile call failed or the data was incomplete. That marked the user as
    // done with onboarding while leaving them without a profile, and nothing in
    // the app ever sent them back — a permanent dead end. Only record completion
    // when a profile actually exists.
    if (_profileCreated) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);
    }

    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    if (_profileCreated) {
      // The "Seven days. On us." screen belongs here, at the end of sign-up — the
      // trial was granted on the account's first authenticated request, so by now it
      // is already running. The splash carries the same check as a fallback for anyone
      // who quits before reaching this point.
      final status = await SubscriptionService().getMyStatus();
      if (!mounted) return;
      final showIntro = await claimTrialIntro(status);
      if (!mounted) return;

      // `go`, not `push`: onboarding is finished, so it should not stay on the
      // stack underneath home.
      context.go(showIntro
          ? AppRoutespath.subscriptionPage
          : "/homeScreen");
    } else {
      // Send them back to the first unanswered step rather than into an app
      // that has no idea who they are. Their answers survived (they are
      // persisted), so this resumes rather than restarts.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "We couldn't finish setting up your profile. Let's try that again.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      context.go("/onboardingFlow");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF1),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 60.sp,
                height: 60.sp,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9228),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFF011F54),
                  size: 48,
                ),
              ),
              SizedBox(height: 32.sp),

              // Title
              SizedBox(
                width: 295,
                child: Text(
                  textAlign: TextAlign.center,
                  'Noted! Thanks for \n your honesty!',
                  style: GoogleFonts.workSans(
                    color: const Color(0xFF011F54), // Text-text-default
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.40,
                    letterSpacing: -0.50,
                  ),
                ),
              ),
              SizedBox(height: 16.sp),

              // Subtitle
              Text(
                // Was hardcoded "Fuzzy" — the user has just named their
                // companion two screens earlier, so use what they chose.
                "${OnboardingData().companionName}'s here to make today \n a little easier.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              // Show loading indicator while creating profile
              if (_profileController.isLoading) ...[
                SizedBox(height: 24.sp),
                const CircularProgressIndicator(),
                SizedBox(height: 12.sp),
                Text(
                  'Creating your profile...',
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
