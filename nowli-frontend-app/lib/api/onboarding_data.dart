import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything the onboarding flow collects, before it becomes a Profile.
///
/// **Persisted.** This used to live purely in memory, so killing the app halfway
/// through onboarding silently threw away every answer — and because the user was
/// already authenticated by that point, the next launch sent them straight to home
/// with no profile and no route back. State is now mirrored into
/// `SharedPreferences` on every change and restored on start.
class OnboardingData extends ChangeNotifier {
  static final OnboardingData _instance = OnboardingData._internal();
  factory OnboardingData() => _instance;
  OnboardingData._internal();

  static const String _prefsKey = 'onboarding_data_v1';

  // User profile data
  String? _name;
  String? _gender;
  String? _language;
  String? _voice;
  String? _avatarLogo;
  int? _predefinedOption;
  String? _profileImage;
  String? _nowliiName;
  String? _customNowliiName;

  // Getters
  String? get name => _name;
  String? get gender => _gender;
  String? get language => _language;
  String? get voice => _voice;
  String? get avatarLogo => _avatarLogo;
  int? get predefinedOption => _predefinedOption;
  String? get profileImage => _profileImage;
  String? get nowliiName => _nowliiName;
  String? get customNowliiName => _customNowliiName;

  /// The name to greet the user with. Falls back to a neutral address rather than
  /// a placeholder — screens used to hardcode "JULIE", the name from the mock.
  String get greetingName =>
      (_name != null && _name!.trim().isNotEmpty) ? _name!.trim() : 'there';

  /// What the companion is actually called: a typed name wins over a suggested
  /// one, and there is a neutral fallback so no screen has to hardcode "Fuzzy".
  String get companionName {
    if (_customNowliiName != null && _customNowliiName!.trim().isNotEmpty) {
      return _customNowliiName!.trim();
    }
    if (_nowliiName != null && _nowliiName!.trim().isNotEmpty) {
      return _nowliiName!.trim();
    }
    return 'Nowlii';
  }

  // Setters
  void setName(String value) {
    _name = value;
    _customNowliiName = value.toLowerCase().replaceAll(' ', '');
    _changed('Name set');
  }

  void setGender(String value) {
    _gender = value;
    _changed('Gender set');
  }

  void setLanguage(String value) {
    _language = value;
    _changed('Language set');
  }

  void setVoice(String value) {
    _voice = value;
    _changed('Voice set');
  }

  /// The chosen companion's picture, for showing it back during onboarding.
  ///
  /// Not what selects the companion — [setPredefinedOption] is. The backend derives
  /// `avatar_logo` from `predefined_option` and treats the URL as read-only.
  void setAvatarLogo(String value) {
    _avatarLogo = value;
    _changed('Avatar logo set');
  }

  /// The id of the chosen `NowliiPredefinedOption` — the only field that actually sets
  /// the companion, and with it the AI voice.
  void setPredefinedOption(int value) {
    _predefinedOption = value;
    _changed('Companion set');
  }

  void setProfileImage(String value) {
    _profileImage = value;
    _changed('Profile image set');
  }

  void setNowliiName(String value) {
    _nowliiName = value;
    _changed('Nowlii name set');
  }

  void setCustomNowliiName(String value) {
    _customNowliiName = value;
    _changed('Custom Nowlii name set');
  }

  void _changed(String action) {
    notifyListeners();
    _logData(action);
    // Fire and forget: the setters are synchronous and callers are widget
    // callbacks, so blocking them on disk would be worse than a late write.
    unawaited(_persist());
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

  // ── Persistence ────────────────────────────────────────────────────────────

  Map<String, dynamic> _toStorageMap() => {
        'name': _name,
        'gender': _gender,
        'language': _language,
        'voice': _voice,
        'avatarLogo': _avatarLogo,
        'predefinedOption': _predefinedOption,
        'profileImage': _profileImage,
        'nowliiName': _nowliiName,
        'customNowliiName': _customNowliiName,
      };

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_toStorageMap()));
    } catch (e) {
      // Losing a write is recoverable — the user simply re-answers. Crashing an
      // onboarding step over it is not.
      if (kDebugMode) debugPrint('OnboardingData: could not persist — $e');
    }
  }

  /// Reload whatever survived a previous run. Safe to call more than once.
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      _name = map['name'] as String?;
      _gender = map['gender'] as String?;
      _language = map['language'] as String?;
      _voice = map['voice'] as String?;
      _avatarLogo = map['avatarLogo'] as String?;
      _predefinedOption = map['predefinedOption'] as int?;
      _profileImage = map['profileImage'] as String?;
      _nowliiName = map['nowliiName'] as String?;
      _customNowliiName = map['customNowliiName'] as String?;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('OnboardingData: could not restore — $e');
    }
  }

  // Convert to map for API
  Map<String, dynamic> toJson() {
    // Valid gender choices from backend
    final validGenders = ["I'm a man", "I'm a woman", "Another gender"];

    // Validate gender - if not in valid list, default to first option
    final validatedGender =
        validGenders.contains(_gender) ? _gender : "I'm a man";

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

  /// Wipe both memory and disk. Called once the profile has actually been created.
  Future<void> clear() async {
    _name = null;
    _gender = null;
    _language = null;
    _voice = null;
    _avatarLogo = null;
    _predefinedOption = null;
    _profileImage = null;
    _nowliiName = null;
    _customNowliiName = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {
      // Nothing useful to do; the next successful write overwrites it anyway.
    }
    if (kDebugMode) debugPrint('Onboarding data cleared');
  }

  /// Debug-only. This is the user's name, gender and companion — it has no place
  /// in a release logcat.
  void _logData(String action) {
    if (!kDebugMode) return;
    debugPrint(
      'Onboarding [$action] '
      'complete=$isComplete '
      '(${(completionPercentage * 100).toStringAsFixed(0)}%)',
    );
  }

  // Log all data
  void logAllData() {
    _logData('Current State');
  }
}
