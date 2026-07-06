import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/api/storage.dart';

/// One message in the user's support conversation (mirrors the backend model).
class SupportMessage {
  final int id;
  final String sender; // 'user' | 'admin'
  final String? category;
  final String body;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.sender,
    this.category,
    required this.body,
    required this.createdAt,
  });

  bool get isFromUser => sender == 'user';

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
        id: json['id'] as int,
        sender: (json['sender'] ?? 'user') as String,
        category: json['category'] as String?,
        body: (json['body'] ?? '') as String,
        createdAt:
            DateTime.tryParse((json['created_at'] ?? '') as String)?.toLocal() ??
                DateTime.now(),
      );
}

/// Talks to the Django support endpoints (`/api/support/messages/`).
class SupportService {
  final StorageService _storage = StorageService();

  String get _url => '${ApiConstants.baseUrl}${ApiConstants.supportMessages}';

  Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await _storage.getAccessToken();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// The authenticated user's full support thread (oldest first).
  Future<List<SupportMessage>> getMessages() async {
    final res = await http.get(Uri.parse(_url), headers: await _headers());
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load support messages (${res.statusCode})');
  }

  /// Send a message to support. Returns the created message.
  Future<SupportMessage> sendMessage(String body, {String? category}) async {
    final res = await http.post(
      Uri.parse(_url),
      headers: await _headers(json: true),
      body: jsonEncode({
        'body': body,
        if (category != null && category.isNotEmpty) 'category': category,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return SupportMessage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to send support message (${res.statusCode})');
  }
}
