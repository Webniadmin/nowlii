import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_constant.dart';

class ApiService {
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    print('\n========== API POST REQUEST ==========');
    print('🌐 URL: $url');
    print('📤 Request Body: ${jsonEncode(body)}');
    
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': ApiConstants.contentType,
              'accept': ApiConstants.accept,
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Parse defensively — the server can return non-JSON (e.g. an HTML 400/502 page).
      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        responseData = null;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Request successful');

        if (responseData is Map && responseData['access'] != null) {
          print('🔑 Access Token: ${responseData['access']}');
        }
        if (responseData is Map && responseData['refresh'] != null) {
          print('🔄 Refresh Token: ${responseData['refresh']}');
        }

        print('======================================\n');

        return {'success': true, 'data': responseData};
      } else {
        print('❌ Request failed [HTTP ${response.statusCode}]');
        print('Error Details: $responseData');
        print('======================================\n');

        // Surface the REAL server error instead of a generic label.
        String serverMsg = 'HTTP ${response.statusCode}';
        if (responseData is Map) {
          final detail = responseData['detail'] ??
              responseData['error'] ??
              responseData['message'] ??
              responseData['non_field_errors'];
          if (detail != null) serverMsg = '$detail (HTTP ${response.statusCode})';
        } else if (response.body.isNotEmpty) {
          final snippet = response.body.length > 120
              ? '${response.body.substring(0, 120)}…'
              : response.body;
          serverMsg = '$snippet (HTTP ${response.statusCode})';
        }

        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': serverMsg,
          'data': responseData,
        };
      }
    } catch (e) {
      print('❌ EXCEPTION: ${e.toString()}');
      print('🌐 Target was: $url');
      print('======================================\n');

      // DEBUG BUILD: include the raw exception + target host so failures are diagnosable
      // on-device. Revert to friendly copy before release.
      String errorMessage;
      final es = e.toString();
      if (es.contains('SocketException') || es.contains('Broken pipe')) {
        errorMessage = 'Cannot reach server ${url.host}:${url.port} — $es';
      } else if (es.contains('TimeoutException')) {
        errorMessage = 'Timed out reaching ${url.host}:${url.port} (20s)';
      } else if (es.contains('HandshakeException')) {
        errorMessage = 'TLS/handshake error to ${url.host} — is the URL http vs https? $es';
      } else if (es.contains('ClientException')) {
        errorMessage = 'HTTP client error to ${url.host}:${url.port} — $es';
      } else {
        errorMessage = 'Network error to ${url.host}:${url.port} — $es';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }
}
