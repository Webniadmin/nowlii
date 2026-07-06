import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowlii/core/gen/assets.gen.dart';
import 'package:nowlii/themes/text_styles.dart';
import 'package:nowlii/utils/color_palette/color_palette.dart';
import 'package:nowlii/api/profile_controller.dart';
import 'package:nowlii/api/profile_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final ProfileController _profileController = ProfileController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedGender = "I'm a woman";
  bool _isLoading = false;
  ProfileModel? _currentProfile;
  File? _selectedProfileImage;
  XFile? _selectedImageFile; // For web compatibility

  @override
  void initState() {
    super.initState();
    // Listen to profile controller changes
    _profileController.addListener(_onProfileChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _profileController.removeListener(_onProfileChanged);
    super.dispose();
  }

  // Called when profile controller notifies changes
  void _onProfileChanged() {
    if (mounted && _profileController.profile != null) {
      setState(() {
        _currentProfile = _profileController.profile;
        _usernameController.text = _currentProfile?.name ?? '';
        _selectedGender = _currentProfile?.gender ?? "I'm a woman";
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    await _profileController.fetchProfile();
    
    if (_profileController.profile != null) {
      setState(() {
        _currentProfile = _profileController.profile;
        _usernameController.text = _currentProfile?.name ?? '';
        _selectedGender = _currentProfile?.gender ?? "I'm a woman";
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileImage() {
    if (kIsWeb && _selectedImageFile != null) {
      // Web: Use Image.network with XFile path
      return Image.network(
        _selectedImageFile!.path,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    } else if (!kIsWeb && _selectedProfileImage != null) {
      // Mobile: Use FileImage
      return Image.file(
        _selectedProfileImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (_currentProfile?.profileImage != null) {
      // Network image from API
      return Image.network(
        _currentProfile!.profileImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    } else {
      return _buildFallbackImage();
    }
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      Assets.svgIcons.editProfilePng_.path,
      fit: BoxFit.cover,
      width: 120,
      height: 120,
    );
  }

  // Build avatar image for the Nowlii card
  Widget _buildAvatarImage() {
    if (_currentProfile?.avatarLogo != null && _currentProfile!.avatarLogo!.isNotEmpty) {
      final avatarUrl = _currentProfile!.avatarLogo!;
      
      // Check if it's a network URL
      if (avatarUrl.startsWith('http')) {
        return Image.network(
          avatarUrl,
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatarImage();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: Colors.white,
              ),
            );
          },
        );
      } else {
        // Local asset path
        return Image.asset(
          avatarUrl,
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatarImage();
          },
        );
      }
    }
    
    return _buildFallbackAvatarImage();
  }

  // Fallback avatar image
  Widget _buildFallbackAvatarImage() {
    return Center(
      child: Image.asset(
        'assets/svg_images/A.png',
        width: 60,
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person,
          size: 40,
          color: Colors.white54,
        ),
      ),
    );
  }

  // Get display name for avatar
  String _getDisplayName() {
    if (_currentProfile?.customNowliiName != null && 
        _currentProfile!.customNowliiName!.isNotEmpty) {
      return _currentProfile!.customNowliiName!;
    }
    
    if (_currentProfile?.nowliiName != null && 
        _currentProfile!.nowliiName!.isNotEmpty) {
      // Capitalize first letter
      final name = _currentProfile!.nowliiName!;
      return name[0].toUpperCase() + name.substring(1);
    }
    
    return 'Your Nowlii';
  }

  Future<void> _pickProfileImage() async {
    try {
      ImageSource? source;
      
      // On web, directly pick from gallery (no camera option)
      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        // Show bottom sheet to choose camera or gallery on mobile
        source = await showModalBottomSheet<ImageSource>(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose Profile Picture',
                    style: GoogleFonts.workSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF011F54),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Color(0xFF4542EB)),
                    title: Text(
                      'Camera',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: Color(0xFF4542EB)),
                    title: Text(
                      'Gallery',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      }

      if (source != null) {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() {
            _selectedImageFile = pickedFile;
            if (!kIsWeb) {
              _selectedProfileImage = File(pickedFile.path);
            }
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    final success = await _profileController.updateProfile(
      name: _usernameController.text.trim(),
      gender: _selectedGender,
      profileImageFile: !kIsWeb ? _selectedProfileImage : null,
      profileImageXFile: kIsWeb ? _selectedImageFile : null,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog('Profile updated successfully!');
    } else {
      _showErrorDialog(_profileController.errorMessage ?? 'Failed to update profile');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
      backgroundColor: AppColorsApps.iceBlue,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        Assets.svgIcons.editProfilePng.path,
                        height: 32,
                        width: 32,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'EDIT PROFILE',
                      style: AppsTextStyles.googleContinueButton32,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: ClipOval(
                            child: _buildProfileImage(),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4542EB),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Avatar Card (Nowlii Form)
                Container(
                  height: 140,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColorsApps.babyBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Avatar Image Container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColorsApps.royalBlue,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _buildAvatarImage(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Avatar Name and Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDisplayName(),
                              style: GoogleFonts.workSans(
                                color: const Color(0xFF011F54),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.20,
                                letterSpacing: -0.50,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                'Pick a new form or \ncustomize your current one',
                                style: GoogleFonts.workSans(
                                  color: const Color(0xFF011F54),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  height: 1.40,
                                  letterSpacing: -0.50,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit Icon
                      GestureDetector(
                        onTap: () async {
                          // Navigate to edit name screen and wait for result
                          final result = await context.push("/editNameScreen");
                          // Reload profile when returning (regardless of result)
                          if (mounted) {
                            await _loadProfile();
                          }
                        },
                        child: Image.asset(
                          Assets.svgIcons.editProfilIcon.path,
                          height: 34,
                          width: 34,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Username Field
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          style: GoogleFonts.workSans(
                            color: const Color(0xFF011F54),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.20,
                            letterSpacing: -0.50,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true, // extra height remove
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Gender Field
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: const Color(0xFFFFFEF8),
                            value: _selectedGender,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.check,
                              color: Color(0xFF4542EB),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return ["I'm a woman", "I'm a man", 'Another gender'].map((
                                String value,
                              ) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    value,
                                    style: GoogleFonts.workSans(
                                      color: const Color(0xFF011F54),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.20,
                                      letterSpacing: -0.50,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            items: [
                              DropdownMenuItem(
                                value: "I'm a woman",
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    "I'm a woman",
                                    style: GoogleFonts.workSans(
                                      color: const Color(0xFF011F54),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.20,
                                      letterSpacing: -0.50,
                                    ),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: "I'm a man",
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    "I'm a man",
                                    style: GoogleFonts.workSans(
                                      color: const Color(0xFF011F54),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.20,
                                      letterSpacing: -0.50,
                                    ),
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Another gender',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'Another gender',
                                    style: GoogleFonts.workSans(
                                      color: const Color(0xFF011F54),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.20,
                                      letterSpacing: -0.50,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // const Text(
                //   'Gender',
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: Colors.black54,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // Container(
                //   height: 80,
                //   padding: const EdgeInsets.symmetric(horizontal: 16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(15),
                //   ),
                //   child: DropdownButtonHideUnderline(
                //     child: DropdownButton<String>(
                //       dropdownColor: const Color(0xFFFFFEF8),
                //       value: _selectedGender,
                //       isExpanded: true,
                //       icon: const Icon(Icons.check, color: Color(0xFF4542EB)),
                //       style: const TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.bold,
                //         color: Color(0xFF4542EB),
                //       ),
                //       selectedItemBuilder: (BuildContext context) {
                //         return ['Women', 'Men', 'Another gender'].map((
                //           String value,
                //         ) {
                //           return Align(
                //             alignment: Alignment.centerLeft,
                //             child: Text(
                //               value,
                //               style: const TextStyle(
                //                 fontSize: 16,
                //                 fontWeight: FontWeight.bold,
                //                 color: Color(0xFF4542EB),
                //               ),
                //             ),
                //           );
                //         }).toList();
                //       },
                //       items: const [
                //         DropdownMenuItem<String>(
                //           value: 'Women',
                //           child: Text('Women'),
                //         ),
                //         DropdownMenuItem<String>(
                //           value: 'Men',
                //           child: Text('Men'),
                //         ),
                //         DropdownMenuItem<String>(
                //           value: 'Another gender',
                //           child: Text('Another gender'),
                //         ),
                //       ],
                //       onChanged: (String? newValue) {
                //         if (newValue != null) {
                //           setState(() {
                //             _selectedGender = newValue;
                //           });
                //         }
                //       },
                //     ),
                //   ),
                // ),
                const SizedBox(height: 40),

                // Save Button
                GestureDetector(
                  onTap: _isLoading ? null : _saveProfile,
                  child: Container(
                    width: 335,
                    height: 80,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 28,
                    ),
                    decoration: ShapeDecoration(
                      color: _isLoading 
                          ? Colors.grey 
                          : const Color(0xFF4542EB),
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
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Text(
                            'Save',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
