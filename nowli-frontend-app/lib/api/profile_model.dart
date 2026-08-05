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

  /// Topics the user asked the companion to steer clear of. Sent to nowli-ai when a call
  /// starts, so this is one of the few settings that changes what the AI actually says.
  final List<String> restrictedTopics;

  /// Whether this user's conversations may be used to improve the AI.
  final bool useDataToImprove;

  /// Which companion this profile is on, by id.
  ///
  /// The only reliable way to know: screens used to infer it by matching the companion's
  /// *name* against the catalogue, which fails the moment the user renames it — and
  /// renaming is offered right next to the picture.
  final int? predefinedOption;

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
    this.restrictedTopics = const [],
    this.useDataToImprove = true,
    this.predefinedOption,
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
      // Female is the product default; an older row that never set one still reads as the
      // voice the caller actually hears, because nowli-ai falls back to the female voice.
      voice: json['voice'] ?? 'Female',
      restrictedTopics: (json['restricted_topics'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      useDataToImprove: json['use_data_to_improve'] ?? true,
      predefinedOption: json['predefined_option'] as int?,
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
      'restricted_topics': restrictedTopics,
      'use_data_to_improve': useDataToImprove,
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
    List<String>? restrictedTopics,
    bool? useDataToImprove,
    int? predefinedOption,
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
      restrictedTopics: restrictedTopics ?? this.restrictedTopics,
      useDataToImprove: useDataToImprove ?? this.useDataToImprove,
      predefinedOption: predefinedOption ?? this.predefinedOption,
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

  /// Id of a `NowliiPredefinedOption` — the ONLY field that sets the companion, exactly as
  /// on [UpdateProfileRequest]. Without it a brand-new account got whatever the backend
  /// defaults to, no matter which character the user picked during onboarding.
  final int? predefinedOption;

  /// The phone's IANA zone (e.g. "Europe/Belgrade").
  ///
  /// Sent at signup so the very first quest a new account creates is scheduled on the
  /// user's clock. Without it the backend reads their wall-clock times in the server's
  /// zone, which is UTC. See `services/device_timezone.dart`.
  final String? timezone;

  CreateProfileRequest({
    required this.name,
    required this.gender,
    this.profileImage,
    this.avatarLogo,
    this.nowliiName,
    this.customNowliiName,
    required this.language,
    required this.voice,
    this.predefinedOption,
    this.timezone,
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
      if (predefinedOption != null) 'predefined_option': predefinedOption,
      if (timezone != null && timezone!.isNotEmpty) 'timezone': timezone,
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
  /// AI Personalization → Restricted Topics. Validated server-side against a known list,
  /// because these end up inside the AI's prompt.
  final List<String>? restrictedTopics;
  final bool? useDataToImprove;

  /// The phone's IANA zone. Reported whenever it changes, so reminders follow a user who
  /// travels. See `services/device_timezone.dart`.
  final String? timezone;

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
    this.restrictedTopics,
    this.useDataToImprove,
    this.timezone,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (restrictedTopics != null) data['restricted_topics'] = restrictedTopics;
    if (useDataToImprove != null) data['use_data_to_improve'] = useDataToImprove;
    
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
    if (timezone != null && timezone!.isNotEmpty) data['timezone'] = timezone;
    return data;
  }
}
