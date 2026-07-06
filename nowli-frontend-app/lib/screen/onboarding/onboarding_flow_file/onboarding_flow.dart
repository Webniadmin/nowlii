import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/core/app_routes/app_routes.dart';
import 'package:nowlii/screen/onboarding/profile_setup/gender_page.dart';
import 'package:nowlii/screen/onboarding/profile_setup/name_page.dart'
    show NamePage;
import 'package:nowlii/widget/animated_onboarding_topbar.dart';

class OnboardingFlow extends StatefulWidget {
  final int initialPage;

  const OnboardingFlow({
    super.key,
    this.initialPage = 0,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late int currentPage;
  late PageController _pageController;
  String userName = '';
  String selectedGender = '';

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (currentPage < 4) {
      setState(() {
        currentPage++;
      });
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {}
  }

  void previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void updateName(String name) {
    setState(() {
      userName = name;
    });
    
    // Save to onboarding data
    final onboardingData = OnboardingData();
    onboardingData.setName(name);
  }

  void selectGender(String gender) {
    setState(() {
      selectedGender = gender;
    });
    
    // Save to onboarding data
    final onboardingData = OnboardingData();
    onboardingData.setGender(gender);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Don't create profile yet - wait for all data
        context.go(AppRoutespath.loadingOnboardingNowli);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = screenHeight < 700;
    final isMediumDevice = screenHeight >= 700 && screenHeight < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFD6E4F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedOnboardingTopbar(
                currentStep: currentPage + 1,
                totalSteps: 6,
                backRoute: "/welcome",
                skipRoute: "/onbordingFetures",
                isSmallDevice: isSmallDevice,
                isMediumDevice: isMediumDevice,
                screenWidth: screenWidth,
                onBackPressed: currentPage > 0 ? previousPage : null,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  NamePage(
                    onContinue: nextPage,
                    onNameChanged: updateName,
                    initialName: userName,
                  ),
                  GenderPage(
                    userName: userName,
                    selectedGender: selectedGender,
                    onGenderSelected: selectGender,
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
