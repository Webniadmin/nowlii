import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/api/profile_controller.dart';
import 'package:nowlii/api/file_helper.dart';

class NoticeLoaderScreen extends StatefulWidget {
  const NoticeLoaderScreen({super.key});

  @override
  State<NoticeLoaderScreen> createState() => _NoticeLoaderScreenState();
}

class _NoticeLoaderScreenState extends State<NoticeLoaderScreen> {
  final ProfileController _profileController = ProfileController();

  @override
  void initState() {
    super.initState();
    _completeOnboardingAndCreateProfile();
  }

  Future<void> _completeOnboardingAndCreateProfile() async {
    // Get all collected onboarding data
    final onboardingData = OnboardingData();
    
    print('\n🎯 ========== CREATING PROFILE WITH ALL DATA ==========');
    onboardingData.logAllData();
    
    // Create profile with all collected data
    if (onboardingData.isComplete) {
      // Convert avatar logo asset to file if it's an asset path
      final avatarLogoPath = onboardingData.avatarLogo;
      File? avatarLogoFile;
      
      if (avatarLogoPath != null && FileHelper.isAssetPath(avatarLogoPath)) {
        print('📎 Converting avatar asset to file...');
        avatarLogoFile = await FileHelper.assetToFile(avatarLogoPath);
        
        if (avatarLogoFile != null) {
          print('✅ Avatar logo file ready: ${avatarLogoFile.path}');
        } else {
          print('⚠️ Failed to convert avatar, will send without file');
        }
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
        print('✅ Profile created successfully in onboarding!');
        print('👤 Profile: ${_profileController.profile?.toJson()}');
        
        // Mark user as new user (for showing tooltips on first home screen visit)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_new_user', true);
        
        // Clear onboarding data after successful creation
        onboardingData.clear();
      } else {
        print('❌ Profile creation failed: ${_profileController.errorMessage}');
      }
    } else {
      print('⚠️ Onboarding data incomplete! Missing:');
      if (onboardingData.name == null) print('  - Name');
      if (onboardingData.gender == null) print('  - Gender');
      if (onboardingData.language == null) print('  - Language');
      if (onboardingData.voice == null) print('  - Voice');
    }
    
    print('======================================================\n');
    
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    
    // Navigate to home after 4 seconds
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      context.push("/homeScreen");
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
                "Fuzzy's here to make today \n a little easier.",
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
