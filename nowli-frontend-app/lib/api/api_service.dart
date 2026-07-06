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
      final response = await http.post(
        url,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'accept': ApiConstants.accept,
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Request successful');
        
        // Log tokens if present
        if (responseData['access'] != null) {
          print('🔑 Access Token: ${responseData['access']}');
        }
        if (responseData['refresh'] != null) {
          print('🔄 Refresh Token: ${responseData['refresh']}');
        }
        
        print('======================================\n');
        
        return {'success': true, 'data': responseData};
      } else {
        print('❌ Request failed');
        print('Error Details: $responseData');
        print('======================================\n');
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'data': responseData,
        };
      }
    } catch (e) {
      print('❌ EXCEPTION: ${e.toString()}');
      print('======================================\n');
      
      // Make error message more user-friendly
      String errorMessage = 'Network error occurred';
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Broken pipe')) {
        errorMessage = 'Connection lost. Please check your internet and try again.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response from server. Please try again later.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }
}
