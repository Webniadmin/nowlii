import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:nowlii/api/api_constant.dart';
import 'package:nowlii/api/profile_model.dart';
import 'package:nowlii/api/storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileService {
  // Create Profile (POST) - Always use multipart/form-data
  static Future<Map<String, dynamic>> createProfile(
    CreateProfileRequest request, {
    File? avatarLogoFile,
    File? profileImageFile,
    XFile? avatarLogoXFile,
    XFile? profileImageXFile,
  }) async {
    try {
      print('\n========== CREATE PROFILE API CALL ==========');
      
      // Get access token
      final token = await SecureStorage.getAccessToken();
      print('📱 Access Token: ${token ?? "NOT FOUND"}');
      
      if (token == null) {
        print('❌ ERROR: No access token found');
        return {
          'success': false,
          'message': 'No access token found. Please login again.',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createProfile}');
      print('🌐 URL: $url');
      
      // Always use MultipartRequest (backend requires multipart/form-data)
      print('📤 Using MultipartRequest');
      
      var multipartRequest = http.MultipartRequest('POST', url);
      
      // Add headers
      multipartRequest.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': ApiConstants.accept,
        'ngrok-skip-browser-warning': 'true',
      });
      
      // Add text fields
      final jsonData = request.toJson();
      jsonData.forEach((key, value) {
        if (value != null) {
          multipartRequest.fields[key] = value.toString();
        }
      });
      
      // Add avatar_logo file if provided
      if (kIsWeb && avatarLogoXFile != null) {
        print('📎 Adding avatar_logo file (Web): ${avatarLogoXFile.name}');
        final bytes = await avatarLogoXFile.readAsBytes();
        multipartRequest.files.add(
          http.MultipartFile.fromBytes(
            'avatar_logo',
            bytes,
            filename: avatarLogoXFile.name,
          ),
        );
      } else if (!kIsWeb && avatarLogoFile != null) {
        print('📎 Adding avatar_logo file (Mobile): ${avatarLogoFile.path}');
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'avatar_logo',
            avatarLogoFile.path,
          ),
        );
      }
      
      // Add profile_image file if provided
      if (kIsWeb && profileImageXFile != null) {
        print('📎 Adding profile_image file (Web): ${profileImageXFile.name}');
        final bytes = await profileImageXFile.readAsBytes();
        multipartRequest.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            bytes,
            filename: profileImageXFile.name,
          ),
        );
      } else if (!kIsWeb && profileImageFile != null) {
        print('📎 Adding profile_image file (Mobile): ${profileImageFile.path}');
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            profileImageFile.path,
          ),
        );
      }
      
      print('📤 Request Fields: ${multipartRequest.fields}');
      print('📤 Request Files: ${multipartRequest.files.map((f) => f.field).toList()}');
      
      // Send request
      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        final profile = ProfileModel.fromJson(responseData);
        await SecureStorage.saveProfileData(profile);
        
        print('✅ Profile created successfully!');
        print('👤 Profile Data: ${profile.toJson()}');
        print('=============================================\n');
        
        return {
          'success': true,
          'message': 'Profile created successfully',
          'profile': profile,
        };
      } else {
        print('❌ Profile creation failed');
        print('Error Details: $responseData');
        print('=============================================\n');
        
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['detail'] ?? 'Failed to create profile',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('❌ EXCEPTION: ${e.toString()}');
      print('=============================================\n');
      
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get Profile (GET)
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      print('\n========== GET PROFILE API CALL ==========');
      
      // Get access token
      final token = await SecureStorage.getAccessToken();
      print('📱 Access Token: ${token ?? "NOT FOUND"}');
      
      if (token == null) {
        print('❌ ERROR: No access token found');
        return {
          'success': false,
          'message': 'No access token found. Please login again.',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getProfile}');
      print('🌐 URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Profile fetched successfully
        final profile = ProfileModel.fromJson(responseData);
        
        // Save profile data to local storage
        await SecureStorage.saveProfileData(profile);
        
        print('✅ Profile fetched successfully!');
        print('👤 Profile Data: ${profile.toJson()}');
        print('==========================================\n');
        
        return {
          'success': true,
          'message': 'Profile fetched successfully',
          'profile': profile,
        };
      } else {
        print('❌ Profile fetch failed');
        print('Error Details: $responseData');
        print('==========================================\n');
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('❌ EXCEPTION: ${e.toString()}');
      print('==========================================\n');
      
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Update Profile (PATCH) - Always use multipart/form-data
  static Future<Map<String, dynamic>> updateProfile(
    UpdateProfileRequest request, {
    File? avatarLogoFile,
    File? profileImageFile,
    XFile? avatarLogoXFile,
    XFile? profileImageXFile,
  }) async {
    try {
      print('\n========== UPDATE PROFILE API CALL ==========');
      
      // Get access token
      final token = await SecureStorage.getAccessToken();
      print('📱 Access Token: ${token ?? "NOT FOUND"}');
      
      if (token == null) {
        print('❌ ERROR: No access token found');
        return {
          'success': false,
          'message': 'No access token found. Please login again.',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}');
      print('🌐 URL: $url');
      
      // Always use MultipartRequest (backend requires multipart/form-data)
      print('📤 Using MultipartRequest');
      
      var multipartRequest = http.MultipartRequest('PATCH', url);
      
      // Add headers
      multipartRequest.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': ApiConstants.accept,
        'ngrok-skip-browser-warning': 'true',
      });
      
      // Add text fields
      final jsonData = request.toJson();
      jsonData.forEach((key, value) {
        if (value != null) {
          multipartRequest.fields[key] = value.toString();
        }
      });
      
      // Add avatar_logo file if provided
      if (kIsWeb && avatarLogoXFile != null) {
        print('📎 Adding avatar_logo file (Web): ${avatarLogoXFile.name}');
        final bytes = await avatarLogoXFile.readAsBytes();
        multipartRequest.files.add(
          http.MultipartFile.fromBytes(
            'avatar_logo',
            bytes,
            filename: avatarLogoXFile.name,
          ),
        );
      } else if (!kIsWeb && avatarLogoFile != null) {
        print('📎 Adding avatar_logo file (Mobile): ${avatarLogoFile.path}');
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'avatar_logo',
            avatarLogoFile.path,
          ),
        );
      }
      
      // Add profile_image file if provided
      if (kIsWeb && profileImageXFile != null) {
        print('📎 Adding profile_image file (Web): ${profileImageXFile.name}');
        final bytes = await profileImageXFile.readAsBytes();
        multipartRequest.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            bytes,
            filename: profileImageXFile.name,
          ),
        );
      } else if (!kIsWeb && profileImageFile != null) {
        print('📎 Adding profile_image file (Mobile): ${profileImageFile.path}');
        multipartRequest.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            profileImageFile.path,
          ),
        );
      }
      
      print('📤 Request Fields: ${multipartRequest.fields}');
      print('📤 Request Files: ${multipartRequest.files.map((f) => f.field).toList()}');
      
      // Send request
      final streamedResponse = await multipartRequest.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final profile = ProfileModel.fromJson(responseData);
        await SecureStorage.saveProfileData(profile);
        
        print('✅ Profile updated successfully!');
        print('👤 Profile Data: ${profile.toJson()}');
        print('=============================================\n');
        
        return {
          'success': true,
          'message': 'Profile updated successfully',
          'profile': profile,
        };
      } else {
        print('❌ Profile update failed');
        print('Error Details: $responseData');
        print('=============================================\n');
        
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['detail'] ?? 'Failed to update profile',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('❌ EXCEPTION: ${e.toString()}');
      print('=============================================\n');
      
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Get cached profile from local storage
  static Future<ProfileModel?> getCachedProfile() async {
    return await SecureStorage.getProfileData();
  }

  // Clear profile data from local storage
  static Future<void> clearProfile() async {
    await SecureStorage.clearProfileData();
  }
}
