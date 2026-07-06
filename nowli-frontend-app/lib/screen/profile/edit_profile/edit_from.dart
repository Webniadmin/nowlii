import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/api/profile_controller.dart';
import 'package:nowlii/api/nowlii_options_api.dart';

class EditFrom extends StatefulWidget {
  const EditFrom({super.key});

  @override
  State<EditFrom> createState() => _EditFromState();
}

class _EditFromState extends State<EditFrom> {
  final ProfileController _profileController = ProfileController();
  
  int selectedIndex = -1;
  bool showConfirmation = false;
  bool _isLoading = false;
  List<NowliiOption> avatarOptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load avatar options from API
    try {
      final options = await NowliiOptionsApi.fetchNowliiOptions();
      setState(() {
        avatarOptions = options;
      });
    } catch (e) {
      print('Error loading avatar options: $e');
      // Fallback to local assets if API fails
      avatarOptions = _getFallbackOptions();
    }
    
    // Load current profile
    await _profileController.fetchProfile();
    
    // Check if current avatar matches any of the loaded avatars
    if (_profileController.profile?.avatarLogo != null && avatarOptions.isNotEmpty) {
      final currentAvatarUrl = _profileController.profile!.avatarLogo!;
      
      // Try to match with loaded avatar options
      for (int i = 0; i < avatarOptions.length; i++) {
        if (currentAvatarUrl == avatarOptions[i].avatarLogo ||
            currentAvatarUrl.contains(avatarOptions[i].name.toLowerCase())) {
          setState(() {
            selectedIndex = i;
          });
          break;
        }
      }
    }
    
    setState(() => _isLoading = false);
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

  Future<void> _updateAvatar() async {
    if (selectedIndex == -1 || avatarOptions.isEmpty) {
      _showErrorDialog('Please select an avatar');
      return;
    }

    setState(() {
      _isLoading = true;
      showConfirmation = false;
    });

    // Get selected avatar option
    final selectedOption = avatarOptions[selectedIndex];

    // Update profile with avatar URL and nowlii name
    final success = await _profileController.updateProfile(
      avatarLogo: selectedOption.avatarLogo,
      nowliiName: selectedOption.name,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialogAndReturn('Avatar updated successfully!');
    } else {
      _showErrorDialog(_profileController.errorMessage ?? 'Failed to update avatar');
    }
  }

  void _showSuccessDialogAndReturn(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Go back with success result
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8ED),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with back button, progress bar, and skip
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          Assets.svgIcons.editProfilePng.path,
                          height: 32,
                          width: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                // Title and subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      "Choose your form",
                      textAlign: TextAlign.left,
                      style: GoogleFonts.workSans(
                        color: Color(0xFF011F54),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // Character grid - Non-scrollable
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: avatarOptions.isEmpty
                        ? const Center(child: Text('No avatars available'))
                        : Column(
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
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showConfirmation = true;
                    });
                  },
                  child: Container(
                    width: 335,
                    height: 80,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 28,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(
                        0xFF4542EB,
                      ) /* Background-bg-primary */,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 20,
                      children: [
                        Text(
                          'Update',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.workSans(
                            color: const Color(0xFFFFFDF7),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 0.80,
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

          // Confirmation Dialog
          if (showConfirmation)
            Positioned(
              left: 10,
              right: 10,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: ShapeDecoration(
                  color: const Color(
                    0xFFDFEFFF,
                  ) /* Background-bg-primary-light */,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 12,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFBEC3CB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 24,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 24,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Are you sure you want to update your form?',
                                    style: GoogleFonts.workSans(
                                      color: const Color(
                                        0xFF011F54,
                                      ), // Text color
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.20,
                                      letterSpacing: -0.50,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  width: 287,
                                  child: Text(
                                    'Your new friend will replace the current one - but don’t worry, your progress stays safe.',
                                    style: GoogleFonts.workSans(
                                      color: const Color(
                                        0xFF4C586E,
                                      ), // Text color
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      height: 1.40,
                                      letterSpacing: -0.50,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 8,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 8,
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    showConfirmation = false;
                                                  });
                                                },
                                                child: Container(
                                                  height: 66,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                  decoration: ShapeDecoration(
                                                    shape: RoundedRectangleBorder(
                                                      side: BorderSide(
                                                        width: 3,
                                                        color: const Color(
                                                          0xFF6A68EF,
                                                        ) /* Border-border-subtle */,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    spacing: 8,
                                                    children: [
                                                      Text(
                                                        'Cancel',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            GoogleFonts.workSans(
                                                              color: const Color(
                                                                0xFF4542EB,
                                                              ), // Text color
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              height: 0.80,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  _updateAvatar();
                                                },
                                                child: Container(
                                                  height: 65,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 14,
                                                      ),
                                                  decoration: ShapeDecoration(
                                                    color: const Color(
                                                      0xFF4542EB,
                                                    ) /* Background-bg-primary */,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    spacing: 8,
                                                    children: [
                                                      Text(
                                                        'Yes, update',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            GoogleFonts.workSans(
                                                              color: const Color(
                                                                0xFFFFFDF7,
                                                              ), // Text color
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              height: 0.80,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
