
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/api/nowlii_options_api.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';
import 'package:nowlii/widget/animated_onboarding_topbar.dart';

class AvatarLogoAndName extends StatefulWidget {
  const AvatarLogoAndName({super.key});

  @override
  State<AvatarLogoAndName> createState() => _AvatarLogoAndNameState();
}

class _AvatarLogoAndNameState extends State<AvatarLogoAndName> {
  final PageController _pageController = PageController();

  String _selectedName = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = screenHeight < 700;
    final isMediumDevice = screenHeight >= 700 && screenHeight < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5E6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimatedOnboardingTopbar(
                currentStep: 6,
                totalSteps: 6,
                backRoute: "/avatarLogo",
                skipRoute: "/popupSpeking",
                isSmallDevice: isSmallDevice,
                isMediumDevice: isMediumDevice,
                screenWidth: screenWidth,
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {});
                },
                children: [
                  NameSelectionPage(
                    selectedName: _selectedName,
                    onNameSelected: (name) {
                      setState(() {
                        _selectedName = name;
                      });
                      
                      // Save to onboarding data
                      final onboardingData = OnboardingData();
                      // Check if it's a custom name or default avatar name
                      final avatarNames = ['KNOTTY', 'BLOOBY', 'FUZZY', 'SNOOZY', 'GRUMPY', 'SLEEPY'];
                      if (avatarNames.contains(name)) {
                        // Default avatar name
                        onboardingData.setNowliiName(name);
                      } else {
                        // Custom typed name
                        onboardingData.setCustomNowliiName(name);
                      }
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push("/popupSpeking"),
              child: Container(
                width: 334,
                height: 116,
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 40,
                  right: 8,
                  bottom: 8,
                ),
                decoration: ShapeDecoration(
                  color: const Color(0xFFFF8F26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  shadows: const [
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
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class NameSelectionPage extends StatefulWidget {
  final String selectedName;
  final Function(String) onNameSelected;

  const NameSelectionPage({
    super.key,
    required this.selectedName,
    required this.onNameSelected,
  });

  @override
  State<NameSelectionPage> createState() => _NameSelectionPageState();
}

class _NameSelectionPageState extends State<NameSelectionPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  bool _showTextField = false;
  int _currentAvatarIndex = 0;
  bool _showNameDisplay = true;
  List<NowliiOption> avatars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _loadAvatarOptions();
  }
  
  Future<void> _loadAvatarOptions() async {
    try {
      final options = await NowliiOptionsApi.fetchNowliiOptions();
      setState(() {
        // Empty (200 []) from an unseeded backend → show the built-in companions.
        avatars = options.isNotEmpty ? options : _getFallbackOptions();
        isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSelection();
      });
    } catch (e) {
      print('Error loading avatar options: $e');
      // Fallback to local assets if API fails
      setState(() {
        avatars = _getFallbackOptions();
        isLoading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeSelection();
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
  
  void _initializeSelection() {
    if (avatars.isEmpty) return;
    
    // Load previously selected avatar logo from onboarding data
    final onboardingData = OnboardingData();
    final savedAvatarLogo = onboardingData.avatarLogo;
    
    // Find the index of the saved avatar logo
    if (savedAvatarLogo != null && savedAvatarLogo.isNotEmpty) {
      final index = avatars.indexWhere((avatar) => avatar.avatarLogo == savedAvatarLogo);
      if (index != -1) {
        setState(() {
          _currentAvatarIndex = index;
        });
      }
    }
    
    widget.onNameSelected(avatars[_currentAvatarIndex].name);
  }

  void _rotateAvatar() {
    if (avatars.isEmpty) return;
    
    setState(() {
      _currentAvatarIndex = (_currentAvatarIndex + 1) % avatars.length;
      _showTextField = false;
      _nameController.clear();
    });
    widget.onNameSelected(avatars[_currentAvatarIndex].name);
    _bounceController.forward(from: 0);
    
    // Save avatar logo to onboarding data
    final onboardingData = OnboardingData();
    onboardingData.setAvatarLogo(avatars[_currentAvatarIndex].avatarLogo);
    onboardingData.setNowliiName(avatars[_currentAvatarIndex].name);
  }

  void _showCustomNameInput() {
    setState(() {
      _showTextField = true;
    });
  }

  void _onCustomNameChanged(String value) {
    if (value.trim().length >= 2 && value.trim().length <= 12) {
      widget.onNameSelected(value.trim());
      _bounceController.forward(from: 0);
      
      // Save custom name to onboarding data
      final onboardingData = OnboardingData();
      onboardingData.setCustomNowliiName(value.trim());
    } else if (value.trim().isEmpty) {
      widget.onNameSelected('');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (avatars.isEmpty) {
      return const Center(child: Text('No avatars available'));
    }

    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            SizedBox(
              width: screenWidth * 0.85,
              child: Text(
                'HOW WOULD YOU LIKE TO CALL IT?',
                style: GoogleFonts.workSans(
                  color: const Color(0xFF011F54),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 0.90,
                  letterSpacing: -0.50,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Give your form a name.',
              style: AppsTextStyles.passwordDescription,
            ),
            const SizedBox(height: 16),

            // ── Avatar ──
            Flexible(
              flex: 4,
              child: ScaleTransition(
                scale: _bounceAnimation,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 120,
                    maxHeight: 260,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: CharacterWidget(
                      avatarOption: _showTextField
                          ? avatars[0]
                          : avatars[_currentAvatarIndex],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Name Display / TextField ──
            if (!_showTextField && _showNameDisplay) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    avatars[_currentAvatarIndex].name,
                    style: AppsTextStyles.signupText28,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _rotateAvatar,
                    child: Image.asset(
                      Assets.svgIcons.buttonRegular.path,
                      width: 66,
                      height: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 320,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _showCustomNameInput,
                    icon: Image.asset(
                      Assets.svgIcons.onBordingPlus.path,
                      width: 18,
                      height: 18,
                    ),
                    label: Text(
                      'Choose your own name',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColorsApps.darkBlue,
                      side: const BorderSide(
                        color: AppColorsApps.darkBlue,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ] else if (_showTextField) ...[
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                maxLength: 12,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'TYPE SOMETHING FUN...',
                  hintStyle: AppsTextStyles.typeSomeThingHere,
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: _onCustomNameChanged,
              ),
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 320,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showTextField = false;
                        _showNameDisplay = true;
                        if (_nameController.text.trim().isEmpty) {
                          widget.onNameSelected(
                            avatars[_currentAvatarIndex].name,
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(
                      'Back to suggestions',
                      style: GoogleFonts.workSans(
                        color: const Color(0xFF011F54),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 0.80,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColorsApps.darkBlue,
                      side: const BorderSide(
                        color: AppColorsApps.darkBlue,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── Spacer + Bottom hint ──
            const Spacer(),
            const Center(
              child: Text(
                'You can always rename it later.',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class AvatarData {
  final String name;
  final String assetPath;
  final bool isLottie;

  AvatarData({
    required this.name,
    required this.assetPath,
    this.isLottie = false,
  });
}

class CharacterWidget extends StatelessWidget {
  final NowliiOption avatarOption;

  const CharacterWidget({super.key, required this.avatarOption});

  @override
  Widget build(BuildContext context) {
    final isUrl = avatarOption.avatarLogo.startsWith('http');
    
    return Container(
      decoration: BoxDecoration(
        color: avatarOption.backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isUrl
            ? Image.network(
                avatarOption.avatarLogo,
                width: 260,
                height: 210,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image from ${avatarOption.avatarLogo}: $error');
                  // Fallback to local asset if network image fails
                  return Image.asset(
                    'assets/svg_images/A.png',
                    width: 260,
                    height: 210,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 260,
                        height: 210,
                        color: avatarOption.backgroundColor,
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
                    width: 260,
                    height: 210,
                    color: avatarOption.backgroundColor,
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
            : Image.asset(
                avatarOption.avatarLogo,
                width: 260,
                height: 210,
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
