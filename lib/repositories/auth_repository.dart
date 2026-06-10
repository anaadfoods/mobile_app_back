import 'package:grocery_app/utils/app_logger.dart';
import 'dart:io';

import '../models/user_model.dart';
import '../services/token_service.dart';
import '../services/oauth_service.dart';
import '../services/profile_service.dart';
import 'package:grocery_app/service_locator.dart';


// A custom exception for handling authentication-related errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}


class AuthRepository {
  final TokenService _tokenService;
  final OAuthService _oauthService;
  final ProfileService _profileService;

  AuthRepository({
    TokenService? tokenService,
    OAuthService? oauthService,
    ProfileService? profileService,
  })  : _tokenService = tokenService ?? getIt<TokenService>(),
        _oauthService = oauthService ?? getIt<OAuthService>(),
        _profileService = profileService ?? getIt<ProfileService>();

  Future<UserModel> googleLogin() async {
    AppLogger.instance.log('DEBUG: AuthRepository.googleLogin() called');
    try {
      final String? idToken = await _oauthService.getGoogleIdToken();

      if (idToken == null) {
        AppLogger.instance.log('DEBUG: AuthRepository - ID Token is null (canceled)');
        throw AuthException('Google Sign-In was canceled.');
      }
      AppLogger.instance.log(
        'DEBUG: AuthRepository - ID Token obtained, calling loginWithGoogleToken...',
      );

      final result = await _oauthService.loginWithGoogleToken(idToken);

      if (result['success'] == true && result['data'] != null) {
        AppLogger.instance.log('DEBUG: AuthRepository - Login successful, parsing user data...');
        return UserModel.fromJson(result['data']);
      } else {
        AppLogger.instance.log('DEBUG: AuthRepository - Login failed: ${result['message']}');
        throw AuthException(result['message'] ?? 'Google login failed.');
      }
    } on AuthException catch (e) {
      AppLogger.instance.log('DEBUG: AuthRepository - AuthException caught: $e');
      rethrow;
    } catch (e) {
      AppLogger.instance.log('DEBUG: AuthRepository - Unexpected exception: $e');
      throw AuthException(e.toString());
    }
  }

  Future<UserModel> appleLogin() async {
    AppLogger.instance.log('DEBUG: AuthRepository.appleLogin() called');
    try {
      final credentials = await _oauthService.getAppleIdToken();

      if (credentials == null || credentials['idToken'] == null) {
        AppLogger.instance.log('DEBUG: AuthRepository - Apple ID Token is null (canceled)');
        throw AuthException('Apple Sign-In was canceled.');
      }
      AppLogger.instance.log(
        'DEBUG: AuthRepository - Apple ID Token obtained, calling loginWithAppleToken...',
      );

      final idToken = credentials['idToken']!;
      final givenName = credentials['givenName'] ?? '';
      final familyName = credentials['familyName'] ?? '';
      final name = '$givenName $familyName'.trim();

      final result = await _oauthService.loginWithAppleToken(
        idToken,
        name: name.isEmpty ? null : name,
      );

      if (result['success'] == true && result['data'] != null) {
        AppLogger.instance.log('DEBUG: AuthRepository - Login successful, parsing user data...');
        return UserModel.fromJson(result['data']);
      } else {
        AppLogger.instance.log('DEBUG: AuthRepository - Login failed: ${result['message']}');
        throw AuthException(result['message'] ?? 'Apple login failed.');
      }
    } on AuthException catch (e) {
      AppLogger.instance.log('DEBUG: AuthRepository - AuthException caught: $e');
      rethrow;
    } catch (e) {
      AppLogger.instance.log('DEBUG: AuthRepository - Unexpected exception: $e');
      throw AuthException(e.toString());
    }
  }

  Stream<bool> get authStateChanges => TokenService.authStateChanges;

  Future<UserModel> login(String email, String password) async {
    final result = await _tokenService.loginUser(email, password);
    if (result['success'] == true && result['data'] != null) {
      return UserModel.fromJson(result['data']);
    } else {
      throw AuthException(result['message'] ?? 'Login failed.');
    }
  }

  Future<void> register(UserModel user) async {
    final result = await _tokenService.registerUser(user);
    if (result['success'] != true) {
      final errorMessage =
          result['message'] is Map
              ? (result['message'] as Map).values.first[0]
              : result['message'] ?? 'Registration failed.';
      throw AuthException(errorMessage);
    }
  }

  Future<void> logout() async {
    await _tokenService.logout();
  }

  Future<UserModel?> checkAuthStatus() async {
    if (await _tokenService.isLoggedIn()) {
      return await _tokenService.getUserData();
    }
    return null;
  }

  Future<bool> verifyAndRefreshToken() async {
    return await _tokenService.verifyAndRefreshToken();
  }

  Future<UserModel> updateProfile(UserModel user) async {
    if (!await _tokenService.isLoggedIn()) {
      throw AuthException('You must be logged in to perform this action.');
    }
    final result = await _profileService.updateProfile(user);
    if (result['success'] == true && result['data'] != null) {
      return UserModel.fromJson(result['data']);
    } else {
      throw AuthException(result['message'] ?? 'Profile update failed.');
    }
  }

  /// Updates the user's address fields
  Future<bool> updateAddress(Map<String, String> addressDetails) async {
    if (!await _tokenService.isLoggedIn()) {
      throw AuthException('You must be logged in to perform this action.');
    }
    return await _profileService.updateUserAddress(addressDetails);
  }

  Future<UserModel> uploadProfileImage(File imageFile) async {
    if (!await _tokenService.isLoggedIn()) {
      throw AuthException('You must be logged in to perform this action.');
    }
    final token = await _tokenService.getAccessToken();
    if (token == null) throw AuthException('Authentication token not found');

    await _profileService.uploadProfileImage(imageFile);

    final updatedUser = await _profileService.getUserProfile();
    if (updatedUser == null) {
      throw AuthException(
        'Failed to retrieve updated profile after image upload.',
      );
    }

    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) throw AuthException('Refresh token not found');

    await _tokenService.saveToken(
      token,
      refreshToken,
      updatedUser.toProfileJson(),
    );
    return updatedUser;
  }

  Future<void> sendOtp(String identifier, String type) async {
    final result = await _profileService.sendOtp(
      identifier: identifier,
      type: type,
    );
    if (result['success'] != true) {
      throw AuthException(result['message'] ?? 'Failed to send OTP.');
    }
  }

  Future<void> verifyOtp(String identifier, String otp, String type) async {
    final result = await _profileService.verifyOtp(
      identifier: identifier,
      otp: otp,
      type: type,
    );
    if (result['success'] != true) {
      throw AuthException(result['message'] ?? 'OTP verification failed.');
    }
  }

  Future<void> deactivateAccount(String password) async {
    if (!await _tokenService.isLoggedIn()) {
      throw AuthException('You must be logged in to perform this action.');
    }
    final result = await _profileService.deactivateAccount(password);
    if (result['success'] != true) {
      throw AuthException(
        result['message'] ?? 'Failed to deactivate account.',
      );
    }
  }

  Future<void> confirmDeactivateAccount(String otp) async {
    if (!await _tokenService.isLoggedIn()) {
      throw AuthException('You must be logged in to perform this action.');
    }
    final result = await _profileService.confirmDeactivateAccount(otp);
    if (result['success'] != true) {
      throw AuthException(
        result['message'] ?? 'Failed to confirm deactivation.',
      );
    }
  }
}
