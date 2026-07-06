class ProfileModel {
  final int? id;
  final String name;
  final String gender;
  final String? profileImage;
  final String? avatarLogo;
  final String? nowliiName;
  final String? customNowliiName;
  final String language;
  final String voice;

  ProfileModel({
    this.id,
    required this.name,
    required this.gender,
    this.profileImage,
    this.avatarLogo,
    this.nowliiName,
    this.customNowliiName,
    required this.language,
    required this.voice,
  });

  // From JSON
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      profileImage: json['profile_image'],
      avatarLogo: json['avatar_logo'],
      nowliiName: json['nowlii_name'],
      customNowliiName: json['custom_nowlii_name'],
      language: json['language'] ?? 'English',
      voice: json['voice'] ?? 'Male',
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'gender': gender,
      if (profileImage != null) 'profile_image': profileImage,
      if (avatarLogo != null) 'avatar_logo': avatarLogo,
      'nowlii_name': nowliiName ?? '',
      if (customNowliiName != null) 'custom_nowlii_name': customNowliiName,
      'language': language,
      'voice': voice,
    };
  }

  // CopyWith method for updates
  ProfileModel copyWith({
    int? id,
    String? name,
    String? gender,
    String? profileImage,
    String? avatarLogo,
    String? nowliiName,
    String? customNowliiName,
    String? language,
    String? voice,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      profileImage: profileImage ?? this.profileImage,
      avatarLogo: avatarLogo ?? this.avatarLogo,
      nowliiName: nowliiName ?? this.nowliiName,
      customNowliiName: customNowliiName ?? this.customNowliiName,
      language: language ?? this.language,
      voice: voice ?? this.voice,
    );
  }
}

// Request model for creating profile
class CreateProfileRequest {
  final String name;
  final String gender;
  final String? profileImage;
  final String? avatarLogo;
  final String? nowliiName;
  final String? customNowliiName;
  final String language;
  final String voice;

  CreateProfileRequest({
    required this.name,
    required this.gender,
    this.profileImage,
    this.avatarLogo,
    this.nowliiName,
    this.customNowliiName,
    required this.language,
    required this.voice,
  });

  Map<String, dynamic> toJson() {
    // Valid gender choices from backend
    final validGenders = ["I'm a man", "I'm a woman", "Another gender"];
    
    // Validate gender - if not in valid list, default to first option
    final validatedGender = validGenders.contains(gender) ? gender : "I'm a man";
    
    // Valid nowlii names from backend (case-sensitive!)
    final validNowliiNames = ['milo', 'bloop', 'gumo', 'knotty', 'Fizzy', 'zee'];
    final nowliiNameLower = nowliiName?.toLowerCase() ?? '';
    
    // Check if it matches any valid name (case-insensitive check)
    String? matchedName;
    for (var validName in validNowliiNames) {
      if (validName.toLowerCase() == nowliiNameLower) {
        matchedName = validName; // Use the exact case from backend
        break;
      }
    }
    
    // Logic: Either nowlii_name OR custom_nowlii_name, not both
    // If nowlii_name is valid, use it. Otherwise use custom_nowlii_name
    final bool useNowliiName = matchedName != null && matchedName.isNotEmpty;
    
    return {
      'name': name,
      'gender': validatedGender,
      if (profileImage != null) 'profile_image': profileImage,
      // Include avatar_logo regardless of whether it's a URL or local path
      if (avatarLogo != null && avatarLogo!.isNotEmpty) 
        'avatar_logo': avatarLogo,
      // Send either nowlii_name OR custom_nowlii_name, not both
      if (useNowliiName)
        'nowlii_name': matchedName
      else if (customNowliiName != null && customNowliiName!.isNotEmpty)
        'custom_nowlii_name': customNowliiName,
      'language': language,
      'voice': voice,
    };
  }
}

// Request model for updating profile
class UpdateProfileRequest {
  final String? name;
  final String? gender;
  final String? profileImage;
  final String? avatarLogo;
  final String? nowliiName;
  final String? customNowliiName;
  final String? language;
  final String? voice;
  // Id of a NowliiPredefinedOption — the ONLY way to set the companion avatar,
  // since `avatar_logo`/`nowlii_name` are read-only server-side (the backend copies
  // the avatar/name from the chosen predefined option in Profile.save()).
  final int? predefinedOption;

  UpdateProfileRequest({
    this.name,
    this.gender,
    this.profileImage,
    this.avatarLogo,
    this.nowliiName,
    this.customNowliiName,
    this.language,
    this.voice,
    this.predefinedOption,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    
    // Validate gender - only allow valid choices
    if (gender != null) {
      final validGenders = ["I'm a man", "I'm a woman", "Another gender"];
      if (validGenders.contains(gender)) {
        data['gender'] = gender;
      }
    }
    
    if (profileImage != null) data['profile_image'] = profileImage;
    // Include avatar_logo regardless of whether it's a URL or local path
    if (avatarLogo != null && avatarLogo!.isNotEmpty) {
      data['avatar_logo'] = avatarLogo;
    }
    
    // Logic: Either nowlii_name OR custom_nowlii_name, not both
    if (nowliiName != null || customNowliiName != null) {
      final validNowliiNames = ['milo', 'bloop', 'gumo', 'knotty', 'Fizzy', 'zee'];
      final nowliiNameLower = nowliiName?.toLowerCase() ?? '';
      
      String? matchedName;
      for (var validName in validNowliiNames) {
        if (validName.toLowerCase() == nowliiNameLower) {
          matchedName = validName;
          break;
        }
      }
      
      // If nowlii_name is valid, use it. Otherwise use custom_nowlii_name
      final bool useNowliiName = matchedName != null && matchedName.isNotEmpty;
      
      if (useNowliiName) {
        data['nowlii_name'] = matchedName;
      } else if (customNowliiName != null && customNowliiName!.isNotEmpty) {
        data['custom_nowlii_name'] = customNowliiName;
      }
    }
    
    if (language != null) data['language'] = language;
    if (voice != null) data['voice'] = voice;
    if (predefinedOption != null) data['predefined_option'] = predefinedOption;
    return data;
  }
}
