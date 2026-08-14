import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/services/companion_avatar.dart';

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
  }) : backgroundColor = backgroundColor ??
            _tileColours[CompanionIdentity.slotFor(
              imageUrl: avatarLogo,
              presetName: name,
              optionId: id,
            )];

  /// Which slot in the design's palette this option is — see [CompanionIdentity.slotFor].
  int get _slot => CompanionIdentity.slotFor(
        imageUrl: avatarLogo,
        presetName: name,
        optionId: id,
      );

  /// Zee's tile is a gradient in the design, not a flat colour; every other
  /// companion sits on [backgroundColor]. Null for the other five.
  Gradient? get backgroundGradient => _slot == 5 ? _zeeGradient : null;

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

  /// The tile colour behind each companion in the picker, from the design
  /// (Figma `44:8829`), in the canonical slot order milo, bloop, gumo, knotty,
  /// fizzy, zee.
  ///
  /// **Indexed by slot, never by id.** This list was right all along; what was
  /// wrong was reaching into it with `(id - 1) % 6`. Production serves ids
  /// `2, 3, 4, 6, 10, 12`, so that arithmetic handed milo bloop's orange, gave
  /// two pairs of companions a single colour between them, and left the picker
  /// disagreeing with the design for five of the six. Same trap that had the
  /// wrong *character* drawn until 2026-08-12; see `companion_avatar.dart`.
  static const List<Color> _tileColours = [
    Color(0xFF011F54), // milo   — navy
    Color(0xFFFF8F26), // bloop  — orange
    Color(0xFFFAE3CE), // gumo   — peach
    Color(0xFFDFEFFF), // knotty — pale blue
    Color(0xFF4542EB), // fizzy  — indigo
    Color(0xFF3BB64B), // zee    — under the gradient below
  ];

  /// Zee's tile in the design runs green → blue → orange across the diagonal.
  static const Gradient _zeeGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFF3BB64B),
      Color(0xFF4B9BF5),
      Color(0xFFFF8F26),
    ],
    stops: [0.0, 0.55, 1.0],
  );
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
