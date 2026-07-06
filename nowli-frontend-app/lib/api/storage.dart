import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowlii/api/profile_model.dart';

class StorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _usernameKey = 'username';
  static const String _profileDataKey = 'profile_data';

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    print('\n💾 Saving tokens to storage...');
    print('🔑 Access Token: $accessToken');
    print('🔄 Refresh Token: $refreshToken');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    
    print('✅ Tokens saved successfully\n');
  }

  Future<void> saveUserData(int userId, String email, String username) async {
    print('\n💾 Saving user data to storage...');
    print('👤 User ID: $userId');
    print('📧 Email: $email');
    print('👤 Username: $username');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_usernameKey, username);
    
    print('✅ User data saved successfully\n');
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    print('🔍 Retrieved Access Token: ${token ?? "NOT FOUND"}');
    return token;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_refreshTokenKey);
    print('🔍 Retrieved Refresh Token: ${token ?? "NOT FOUND"}');
    return token;
  }

  // Profile data methods
  Future<void> saveProfileData(ProfileModel profile) async {
    print('\n💾 Saving profile data to storage...');
    print('👤 Profile: ${profile.toJson()}');
    
    final prefs = await SharedPreferences.getInstance();
    final profileJson = jsonEncode(profile.toJson());
    await prefs.setString(_profileDataKey, profileJson);
    
    print('✅ Profile data saved successfully\n');
  }

  Future<ProfileModel?> getProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileDataKey);
    
    if (profileJson != null) {
      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
      final profile = ProfileModel.fromJson(profileMap);
      print('🔍 Retrieved Profile: ${profile.toJson()}');
      return profile;
    }
    
    print('🔍 No profile data found in storage');
    return null;
  }

  Future<void> clearProfileData() async {
    print('\n🗑️ Clearing profile data from storage...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileDataKey);
    print('✅ Profile data cleared\n');
  }

  Future<void> clearAll() async {
    print('\n🗑️ Clearing all data from storage...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ All data cleared\n');
  }
}

// Alias for backward compatibility
class SecureStorage {
  static final _storage = StorageService();

  static Future<String?> getAccessToken() => _storage.getAccessToken();
  static Future<String?> getRefreshToken() => _storage.getRefreshToken();
  static Future<void> saveTokens(String accessToken, String refreshToken) =>
      _storage.saveTokens(accessToken, refreshToken);
  static Future<void> saveUserData(int userId, String email, String username) =>
      _storage.saveUserData(userId, email, username);
  static Future<void> saveProfileData(ProfileModel profile) =>
      _storage.saveProfileData(profile);
  static Future<ProfileModel?> getProfileData() => _storage.getProfileData();
  static Future<void> clearProfileData() => _storage.clearProfileData();
  static Future<void> clearAll() => _storage.clearAll();
}
