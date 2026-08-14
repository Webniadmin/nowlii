
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/api/onboarding_data.dart';
import 'package:nowlii/api/nowlii_options_api.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/screen/onboarding/onboarding_features/companion_name_suggestions.dart';
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
                totalSteps: kOnboardingTotalSteps,
                backRoute: "/avatarLogo",
                skipRoute: "/limitedByDesign",
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
                    // The page tells us which kind of name this is. It used to be
                    // guessed here against a hardcoded list
                    // (['KNOTTY','BLOOBY','FUZZY',…]) that never matched the real
                    // companions (milo/bloop/gumo/knotty/fizzy/zee), so *every*
                    // suggested name was filed as a custom one.
                    onNameSelected: (name, isCustom) {
                      setState(() {
                        _selectedName = name;
                      });

                      final onboardingData = OnboardingData();
                      if (isCustom) {
                        onboardingData.setCustomNowliiName(name);
                      } else {
                        onboardingData.setNowliiName(name);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Disabled until there is a usable name. `_selectedName` is cleared by
            // the page whenever validation fails, so this covers both the empty
            // field and the too-short / too-long cases.
            GestureDetector(
              onTap: _selectedName.trim().isEmpty
                  ? null
                  : () => context.go("/limitedByDesign"),
              child: Opacity(
                opacity: _selectedName.trim().isEmpty ? 0.5 : 1.0,
                child: Container(
                // Was 334, the design width at 375; clamped on a 320dp screen
                // the fixed parts of the row no longer fit and it overflowed
                // by 10. See the same button on the previous step. The margin
                // keeps it aligned with the card above instead of edge to edge.
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 116,
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 24,
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
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Next',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
/// Companion-name length limits, from the design spec.
const int kCompanionNameMin = 2;
const int kCompanionNameMax = 12;

class NameSelectionPage extends StatefulWidget {
  final String selectedName;

  /// `isCustom` distinguishes a name the user typed from one we suggested — the
  /// backend stores them in different columns (`custom_nowlii_name` vs
  /// `nowlii_name`), so the caller must not have to guess.
  final void Function(String name, bool isCustom) onNameSelected;

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

  /// Which suggested name is showing for the current companion (see `_rotateName`).
  int _suggestionIndex = 0;

  /// Live validation message for the typed name; null when there is nothing wrong.
  String? _nameError;

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
    
    _suggestionIndex = 0;
    widget.onNameSelected(_currentSuggestion, false);
  }

  /// Names we can offer for the companion the user picked on the previous screen.
  ///
  /// The companion's own name always leads, so the first thing shown matches what
  /// they just chose.
  List<String> get _suggestionsForCurrentCompanion {
    if (avatars.isEmpty) return const [];
    final companion = avatars[_currentAvatarIndex].name;
    final extras = kCompanionNameSuggestions[companion.toLowerCase()] ?? const [];
    return [companion, ...extras];
  }

  String get _currentSuggestion {
    final pool = _suggestionsForCurrentCompanion;
    if (pool.isEmpty) return '';
    return pool[_suggestionIndex % pool.length];
  }

  /// The ↻ control cycles *names for the chosen companion*.
  ///
  /// It used to advance `_currentAvatarIndex`, i.e. silently swap the companion
  /// itself — undoing the choice made one screen earlier, on a screen whose only
  /// job is naming.
  void _rotateName() {
    if (_suggestionsForCurrentCompanion.length < 2) return;

    setState(() {
      _suggestionIndex =
          (_suggestionIndex + 1) % _suggestionsForCurrentCompanion.length;
      _showTextField = false;
      _nameController.clear();
      _nameError = null;
    });
    widget.onNameSelected(_currentSuggestion, false);
    _bounceController.forward(from: 0);
  }

  void _showCustomNameInput() {
    setState(() {
      _showTextField = true;
      _nameError = null;
    });
  }

  /// Real-time validation, per the design: min 2, max 12.
  ///
  /// An empty field shows no error — the user has not typed anything wrong yet,
  /// they simply have not finished. Continue stays disabled either way.
  String? _validateCompanionName(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (value.length < kCompanionNameMin) {
      return 'A little longer — at least $kCompanionNameMin characters.';
    }
    if (value.length > kCompanionNameMax) {
      return 'That is a bit long — $kCompanionNameMax characters max.';
    }
    return null;
  }

  /// Whether the flow may advance: either a suggested name is showing, or the
  /// typed one passes validation.
  bool get canContinue {
    if (!_showTextField) return _currentSuggestion.isNotEmpty;
    final value = _nameController.text.trim();
    return value.length >= kCompanionNameMin &&
        value.length <= kCompanionNameMax;
  }

  void _onCustomNameChanged(String value) {
    final trimmed = value.trim();
    setState(() {
      _nameError = _validateCompanionName(value);
    });

    if (_nameError == null && trimmed.isNotEmpty) {
      widget.onNameSelected(trimmed, true);
      _bounceController.forward(from: 0);
    } else {
      // Nothing valid to carry forward — clear it so a half-typed name cannot
      // leak into the profile if the user taps on regardless.
      widget.onNameSelected('', true);
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
                    // Always the companion the user picked on the previous
                    // screen. Tapping "Choose your own name" used to swap this
                    // to `avatars[0]` — so someone who had chosen the green one
                    // watched it turn into a different character the moment they
                    // went to type a name, on the one screen whose entire job is
                    // naming the thing they already chose. Same class of bug the
                    // ↻ control had, noted just above `_rotateName`.
                    child: CharacterWidget(
                      avatarOption: avatars[_currentAvatarIndex],
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
                    _currentSuggestion,
                    style: AppsTextStyles.signupText28,
                  ),
                  const SizedBox(width: 16),
                  // Hidden when there is only the companion's own name to show —
                  // a control that visibly does nothing is worse than no control.
                  if (_suggestionsForCurrentCompanion.length > 1)
                    GestureDetector(
                      onTap: _rotateName,
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
                  // 320 was the whole width of the narrowest phone we support,
                  // leaving nothing for the screen's own padding, so the label
                  // beside the + icon had to wrap. Full width inside the
                  // padding, with the label scaling rather than wrapping.
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _showCustomNameInput,
                    icon: Image.asset(
                      Assets.svgIcons.onBordingPlus.path,
                      width: 18,
                      height: 18,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Choose your own name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.workSans(
                          color: const Color(0xFF011F54),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 0.80,
                        ),
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
                // Deliberately NOT `maxLength: 12`. A hard cap silently swallows
                // the 13th keystroke, so the over-length error the design draws
                // could never appear. Let them type past it and say so instead.
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
              if (_nameError != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFE4E4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: Color(0xFFC0362C),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _nameError!,
                            style: GoogleFonts.workSans(
                              color: const Color(0xFFC0362C),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                        _nameError = null;
                        _nameController.clear();
                      });
                      // Going back to suggestions discards whatever was typed, so
                      // restore the suggested name — otherwise a half-typed custom
                      // name stays selected behind a screen that no longer shows it.
                      widget.onNameSelected(_currentSuggestion, false);
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
