import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/api/nowlii_options_api.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/widget/animated_onboarding_topbar.dart';

class AvatarLogo extends StatefulWidget {
  const AvatarLogo({super.key});

  @override
  State<AvatarLogo> createState() => _AvatarLogoState();
}

class _AvatarLogoState extends State<AvatarLogo> {
  int selectedIndex = -1;
  List<NowliiOption> avatarOptions = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAvatarOptions();
  }
  
  Future<void> _loadAvatarOptions() async {
    try {
      final options = await NowliiOptionsApi.fetchNowliiOptions();
      setState(() {
        // The API returns 200 with an empty list when the backend has no predefined
        // options seeded — treat that like a failure and show the built-in companions.
        avatarOptions = options.isNotEmpty ? options : _getFallbackOptions();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading avatar options: $e');
      // Fallback to local assets if API fails
      setState(() {
        avatarOptions = _getFallbackOptions();
        isLoading = false;
      });
    }
  }
  
  List<NowliiOption> _getFallbackOptions() {
    return [
      NowliiOption(id: 1, name: 'milo', avatarLogo: 'assets/svg_images/A.png'),
      NowliiOption(id: 2, name: 'bloop', avatarLogo: 'assets/svg_images/B.png'),
      NowliiOption(id: 3, name: 'gumo', avatarLogo: 'assets/svg_images/C.png'),
      NowliiOption(id: 4, name: 'knotty', avatarLogo: 'assets/svg_images/D.png'),
      NowliiOption(id: 5, name: 'fizzy', avatarLogo: 'assets/svg_images/E.png'),
      NowliiOption(id: 6, name: 'zee', avatarLogo: 'assets/svg_images/F.png'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = screenHeight < 700;
    final isMediumDevice = screenHeight >= 700 && screenHeight < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8ED),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            // Header with back button, progress bar, and skip
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedOnboardingTopbar(
                currentStep: 5,
                totalSteps: 6,
                backRoute: "/nowliHowToUse",
                skipRoute: "/avatarLogoAndName",
                isSmallDevice: isSmallDevice,
                isMediumDevice: isMediumDevice,
                screenWidth: screenWidth,
              ),
            ),

            // Title and subtitle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LET'S SHAPE YOUR NOWLI!",
                    style: AppsTextStyles.black24Uppercase,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Give it a form so we can face it, instead of chase it!',
                    style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF595754),
                      height: 1.4,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Character grid - Non-scrollable
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (avatarOptions.length >= 2)
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCharacterCard(0, avatarOptions[0]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCharacterCard(1, avatarOptions[1]),
                            ),
                          ],
                        ),
                      ),
                    if (avatarOptions.length >= 4) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCharacterCard(2, avatarOptions[2]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCharacterCard(3, avatarOptions[3]),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (avatarOptions.length >= 6) ...[
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCharacterCard(4, avatarOptions[4]),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCharacterCard(5, avatarOptions[5]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Next button
            // CustomNextButton(
            //   isEnabled: true,
            //   onTap: () {
            //     context.push("/onboardingScreen");
            //   },
            //   buttonText: "Next",
            //   iconPath: Assets.svgIcons.startLetsGo.path,
            //   // textStyle: AppsTextStyles.letsStartNext,
            //   textStyle: AppsTextStyles.letsStartNext.copyWith(fontSize: 36),
            // ),
            GestureDetector(
              onTap: () => context.push("/avatarLogoAndName"),
              child: Container(
                width: 354,
                height: 116,
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 60,
                  right: 8,
                  bottom: 8,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFF8F26) /* Background-bg-secondary */,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x070A0C12),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Color(0x140A0C12),
                      blurRadius: 16,
                      offset: Offset(0, 12),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 170,
                      child: Text(
                        'Next',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(width: 20), // spacing
                    Container(
                      padding: const EdgeInsets.all(16), // আগে 24 ছিল
                      decoration: ShapeDecoration(
                        color: const Color(0xFF011F54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: SvgPicture.asset(
                        Assets.svgIcons.startLetsGo.path,
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(int index, NowliiOption option) {
    final isSelected = selectedIndex == index;
    final isUrl = option.avatarLogo.startsWith('http');

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
        
        // Save avatar logo and name to onboarding data
        final onboardingData = OnboardingData();
        onboardingData.setAvatarLogo(option.avatarLogo);
        onboardingData.setNowliiName(option.name);
      },
      child: Container(
        decoration: BoxDecoration(
          color: option.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4B7BF5) : Colors.transparent,
            width: 8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isUrl
                ? Image.network(
                    option.avatarLogo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image from ${option.avatarLogo}: $error');
                      // Fallback to local asset if network image fails
                      return Image.asset(
                        'assets/svg_images/${String.fromCharCode(65 + index)}.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: option.backgroundColor,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.white54,
                            ),
                          );
                        },
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: option.backgroundColor,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )
                : Image.asset(option.avatarLogo, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
