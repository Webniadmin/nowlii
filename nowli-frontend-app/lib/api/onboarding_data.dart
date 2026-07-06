import 'package:flutter/foundation.dart';

/// Global onboarding data storage
/// Collects all user data during onboarding flow
class OnboardingData extends ChangeNotifier {
  static final OnboardingData _instance = OnboardingData._internal();
  factory OnboardingData() => _instance;
  OnboardingData._internal();

  // User profile data
  String? _name;
  String? _gender;
  String? _language;
  String? _voice;
  String? _avatarLogo;
  String? _profileImage;
  String? _nowliiName;
  String? _customNowliiName;

  // Getters
  String? get name => _name;
  String? get gender => _gender;
  String? get language => _language;
  String? get voice => _voice;
  String? get avatarLogo => _avatarLogo;
  String? get profileImage => _profileImage;
  String? get nowliiName => _nowliiName;
  String? get customNowliiName => _customNowliiName;

  // Setters
  void setName(String value) {
    _name = value;
    _customNowliiName = value.toLowerCase().replaceAll(' ', '');
    notifyListeners();
    _logData('Name set');
  }

  void setGender(String value) {
    _gender = value;
    notifyListeners();
    _logData('Gender set');
  }

  void setLanguage(String value) {
    _language = value;
    notifyListeners();
    _logData('Language set');
  }

  void setVoice(String value) {
    _voice = value;
    notifyListeners();
    _logData('Voice set');
  }

  void setAvatarLogo(String value) {
    _avatarLogo = value;
    notifyListeners();
    _logData('Avatar logo set');
  }

  void setProfileImage(String value) {
    _profileImage = value;
    notifyListeners();
    _logData('Profile image set');
  }

  void setNowliiName(String value) {
    _nowliiName = value;
    notifyListeners();
    _logData('Nowlii name set');
  }

  void setCustomNowliiName(String value) {
    _customNowliiName = value;
    notifyListeners();
    _logData('Custom Nowlii name set');
  }

  // Check if all required data is collected
  bool get isComplete {
    return _name != null &&
        _gender != null &&
        _language != null &&
        _voice != null;
  }

  // Get completion percentage
  double get completionPercentage {
    int completed = 0;
    int total = 4; // name, gender, language, voice

    if (_name != null) completed++;
    if (_gender != null) completed++;
    if (_language != null) completed++;
    if (_voice != null) completed++;

    return completed / total;
  }

  // Convert to map for API
  Map<String, dynamic> toJson() {
    // Valid gender choices from backend
    final validGenders = ["I'm a man", "I'm a woman", "Another gender"];
    
    // Validate gender - if not in valid list, default to first option
    final validatedGender = validGenders.contains(_gender) ? _gender : "I'm a man";
    
    // Valid nowlii names from backend (case-sensitive!)
    final validNowliiNames = ['milo', 'bloop', 'gumo', 'knotty', 'Fizzy', 'zee'];
    final nowliiNameLower = _nowliiName?.toLowerCase() ?? '';
    
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
      'name': _name ?? '',
      'gender': validatedGender ?? '',
      'language': _language ?? 'English',
      'voice': _voice ?? 'Male',
      if (_profileImage != null) 'profile_image': _profileImage,
      // Send avatar_logo regardless of whether it's a URL or local path
      if (_avatarLogo != null && _avatarLogo!.isNotEmpty) 
        'avatar_logo': _avatarLogo,
      // Send either nowlii_name OR custom_nowlii_name, not both
      if (useNowliiName)
        'nowlii_name': matchedName
      else if (_customNowliiName != null && _customNowliiName!.isNotEmpty)
        'custom_nowlii_name': _customNowliiName,
    };
  }

  // Clear all data
  void clear() {
    _name = null;
    _gender = null;
    _language = null;
    _voice = null;
    _avatarLogo = null;
    _profileImage = null;
    _nowliiName = null;
    _customNowliiName = null;
    notifyListeners();
    print('\n🗑️ Onboarding data cleared\n');
  }

  // Log current data state
  void _logData(String action) {
    print('\n📝 Onboarding Data Updated: $action');
    print('👤 Name: ${_name ?? "NOT SET"}');
    print('⚧️ Gender: ${_gender ?? "NOT SET"}');
    print('🌍 Language: ${_language ?? "NOT SET"}');
    print('🎤 Voice: ${_voice ?? "NOT SET"}');
    print('🖼️ Avatar Logo: ${_avatarLogo ?? "NOT SET"}');
    print('📸 Profile Image: ${_profileImage ?? "NOT SET"}');
    print('🤖 Nowlii Name: ${_nowliiName ?? "NOT SET"}');
    print('✏️ Custom Nowlii Name: ${_customNowliiName ?? "NOT SET"}');
    print('✅ Complete: $isComplete (${(completionPercentage * 100).toStringAsFixed(0)}%)');
    print('═══════════════════════════════════════\n');
  }

  // Log all data
  void logAllData() {
    _logData('Current State');
  }
}
