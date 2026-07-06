import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_constant.dart';
import 'api_service.dart';
import 'auth_model.dart';
import 'storage.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  // On native platforms we pass the web/server client id so Google mints an id_token
  // whose `aud` matches what the backend verifies. On web the client id comes from the
  // meta tag in web/index.html instead, so serverClientId must NOT be set there.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: kIsWeb || ApiConstants.googleWebClientId.isEmpty
        ? null
        : ApiConstants.googleWebClientId,
  );

  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    return await _apiService.post(
      ApiConstants.register,
      request.toJson(),
    );
  }

  Future<Map<String, dynamic>> verifyOtp(VerifyOtpRequest request) async {
    return await _apiService.post(
      ApiConstants.verifyOtp,
      request.toJson(),
    );
  }

  Future<Map<String, dynamic>> login(LoginRequest request) async {
    final result = await _apiService.post(
      ApiConstants.login,
      request.toJson(),
    );

    if (result['success'] == true) {
      final loginResponse = LoginResponse.fromJson(result['data']);
      
      await _storage.saveTokens(
        loginResponse.access,
        loginResponse.refresh,
      );
      
      await _storage.saveUserData(
        loginResponse.user.userId,
        loginResponse.user.email,
        loginResponse.user.username ?? '',
      );
    }

    return result;
  }

  /// Runs the Google Sign-In flow, exchanges the returned `id_token` for NOWLII JWTs
  /// via the backend, and (on success) stores them exactly like [login].
  Future<Map<String, dynamic>> signInWithGoogle() async {
    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } catch (e) {
      return {'success': false, 'message': 'Google sign-in failed. Please try again.'};
    }

    if (account == null) {
      // User dismissed the Google chooser.
      return {'success': false, 'message': 'Google sign-in was cancelled.'};
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      return {
        'success': false,
        'message': 'Could not obtain Google credentials. Check the app configuration.',
      };
    }

    final result = await _apiService.post(
      ApiConstants.googleLogin,
      {'id_token': idToken},
    );

    if (result['success'] == true) {
      final loginResponse = LoginResponse.fromJson(result['data']);

      await _storage.saveTokens(
        loginResponse.access,
        loginResponse.refresh,
      );

      await _storage.saveUserData(
        loginResponse.user.userId,
        loginResponse.user.email,
        loginResponse.user.username ?? '',
      );
    }

    return result;
  }

  /// Runs the Sign in with Apple flow, exchanges the returned `identity_token` for NOWLII
  /// JWTs via the backend, and (on success) stores them exactly like [login].
  Future<Map<String, dynamic>> signInWithApple() async {
    AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Needed only for the web / Android web-redirect flow (iOS native ignores it).
        webAuthenticationOptions: (ApiConstants.appleServiceId.isNotEmpty &&
                ApiConstants.appleRedirectUri.isNotEmpty)
            ? WebAuthenticationOptions(
                clientId: ApiConstants.appleServiceId,
                redirectUri: Uri.parse(ApiConstants.appleRedirectUri),
              )
            : null,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return {'success': false, 'message': 'Apple sign-in was cancelled.'};
      }
      return {'success': false, 'message': 'Apple sign-in failed. Please try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Apple sign-in failed. Please try again.'};
    }

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      return {
        'success': false,
        'message': 'Could not obtain Apple credentials. Check the app configuration.',
      };
    }

    final fullName = [credential.givenName, credential.familyName]
        .where((e) => e != null && e.isNotEmpty)
        .join(' ');

    final result = await _apiService.post(ApiConstants.appleLogin, {
      'identity_token': idToken,
      if (fullName.isNotEmpty) 'full_name': fullName,
      if (credential.email != null && credential.email!.isNotEmpty)
        'email': credential.email,
    });

    if (result['success'] == true) {
      final loginResponse = LoginResponse.fromJson(result['data']);

      await _storage.saveTokens(
        loginResponse.access,
        loginResponse.refresh,
      );

      await _storage.saveUserData(
        loginResponse.user.userId,
        loginResponse.user.email,
        loginResponse.user.username ?? '',
      );
    }

    return result;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<Map<String, dynamic>> forgotPassword(
    ForgotPasswordRequest request,
  ) async {
    return await _apiService.post(
      ApiConstants.forgotPassword,
      request.toJson(),
    );
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp(
    VerifyForgotPasswordOtpRequest request,
  ) async {
    return await _apiService.post(
      ApiConstants.verifyForgotPasswordOtp,
      request.toJson(),
    );
  }

  Future<Map<String, dynamic>> setNewPassword(
    SetNewPasswordRequest request,
  ) async {
    return await _apiService.post(
      ApiConstants.setNewPassword,
      request.toJson(),
    );
  }
}
