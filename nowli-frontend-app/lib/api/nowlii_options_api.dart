import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';

/// Model for Nowlii avatar options from API
class NowliiOption {
  final int id;
  final String name;
  final String avatarLogo;
  final Color backgroundColor;

  NowliiOption({
    required this.id,
    required this.name,
    required this.avatarLogo,
    Color? backgroundColor,
  }) : backgroundColor = backgroundColor ?? _getDefaultBackgroundColor(id);

  factory NowliiOption.fromJson(Map<String, dynamic> json) {
    String avatarUrl = json['avatar_logo'] as String;
    
    // Convert Google Drive view link to direct download link
    if (avatarUrl.contains('drive.google.com/file/d/')) {
      final fileIdMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(avatarUrl);
      if (fileIdMatch != null) {
        final fileId = fileIdMatch.group(1);
        avatarUrl = 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    }
    
    return NowliiOption(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarLogo: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_logo': avatarLogo,
    };
  }

  // Default background colors based on design
  static Color _getDefaultBackgroundColor(int id) {
    final colors = [
      const Color(0xFF011F54), // Light peach - milo
      const Color(0xFFFF8F26), // Light blue - bloop
      const Color(0xFFFAE3CE), // Purple - gumo
      const Color(0xFFDFEFFF), // Dark blue - knotty
      const Color(0xFF4542EB), // Orange - fizzy
      const Color(0xB53BB64B), // Green - zee
    ];
    return colors[(id - 1) % colors.length];
  }
}

/// API service for fetching Nowlii avatar options
class NowliiOptionsApi {
  // Single source of truth: same env-driven base URL as the rest of the app
  // (set via --dart-define BASE_URL; see ApiConstants).
  static const String baseUrl = ApiConstants.baseUrl;
  
  /// Fetch all available Nowlii avatar options
  static Future<List<NowliiOption>> fetchNowliiOptions({String? token}) async {
    try {
      final headers = {
        'accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('🌐 Fetching Nowlii options from: $baseUrl/api/nowlii-options/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/nowlii-options/'),
        headers: headers,
      );

      print('📥 Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('✅ Successfully loaded ${jsonData.length} avatar options');
        
        final options = jsonData.map((json) => NowliiOption.fromJson(json)).toList();
        
        // Log converted URLs for debugging
        for (var option in options) {
          print('  - ${option.name}: ${option.avatarLogo}');
        }
        
        return options;
      } else {
        print('❌ Failed to load Nowlii options: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load Nowlii options: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching Nowlii options: $e');
      rethrow;
    }
  }
}
