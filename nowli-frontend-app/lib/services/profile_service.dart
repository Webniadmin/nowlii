import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_constant.dart';

class ProfileData {
  final String profileImage;
  final String avatarLogo;
  final String name;
  final String nowliiName;
  final String customNowliiName;

  ProfileData({
    required this.profileImage,
    required this.avatarLogo,
    required this.name,
    this.nowliiName = '',
    this.customNowliiName = '',
  });

  /// The user's companion display name: their custom name if set, otherwise the
  /// chosen predefined companion. Empty string if the profile has neither.
  String get companionName =>
      customNowliiName.isNotEmpty ? customNowliiName : nowliiName;

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      profileImage: json['profile_image'] ?? '',
      avatarLogo: json['avatar_logo'] ?? '',
      name: json['name'] ?? 'User',
      nowliiName: json['nowlii_name'] ?? '',
      customNowliiName: json['custom_nowlii_name'] ?? '',
    );
  }
}

class ProfileService {
  static String get baseUrl => '${ApiConstants.baseUrl}/api';

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  Future<ProfileData?> fetchProfile() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/profiles/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProfileData.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<int> fetchStreak() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/quests/streak/'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['streak'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching streak: $e');
      return 0;
    }
  }
}
