import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nowlii/api/profile_model.dart';
import 'package:nowlii/api/profile_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Create Profile
  Future<bool> createProfile({
    required String name,
    required String gender,
    String? profileImage,
    String? avatarLogo,
    String? nowliiName,
    String? customNowliiName,
    required String language,
    required String voice,
    File? avatarLogoFile,
    File? profileImageFile,
    XFile? avatarLogoXFile,
    XFile? profileImageXFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = CreateProfileRequest(
        name: name,
        gender: gender,
        profileImage: profileImage,
        avatarLogo: avatarLogo,
        nowliiName: nowliiName,
        customNowliiName: customNowliiName,
        language: language,
        voice: voice,
      );

      final result = await ProfileService.createProfile(
        request,
        avatarLogoFile: avatarLogoFile,
        profileImageFile: profileImageFile,
        avatarLogoXFile: avatarLogoXFile,
        profileImageXFile: profileImageXFile,
      );

      if (result['success']) {
        _profile = result['profile'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get Profile
  Future<bool> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ProfileService.getProfile();

      if (result['success']) {
        _profile = result['profile'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update Profile
  Future<bool> updateProfile({
    String? name,
    String? gender,
    String? profileImage,
    String? avatarLogo,
    String? nowliiName,
    String? customNowliiName,
    String? language,
    String? voice,
    int? predefinedOption,
    File? avatarLogoFile,
    File? profileImageFile,
    XFile? avatarLogoXFile,
    XFile? profileImageXFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = UpdateProfileRequest(
        name: name,
        gender: gender,
        profileImage: profileImage,
        avatarLogo: avatarLogo,
        nowliiName: nowliiName,
        customNowliiName: customNowliiName,
        language: language,
        voice: voice,
        predefinedOption: predefinedOption,
      );

      final result = await ProfileService.updateProfile(
        request,
        avatarLogoFile: avatarLogoFile,
        profileImageFile: profileImageFile,
        avatarLogoXFile: avatarLogoXFile,
        profileImageXFile: profileImageXFile,
      );

      if (result['success']) {
        _profile = result['profile'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load cached profile
  Future<void> loadCachedProfile() async {
    _profile = await ProfileService.getCachedProfile();
    notifyListeners();
  }

  // Clear profile
  Future<void> clearProfile() async {
    await ProfileService.clearProfile();
    _profile = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
