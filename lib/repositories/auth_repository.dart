import 'dart:io';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

// A custom exception for handling authentication-related errors.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final AuthService _authService;
  final ProfileService _profileService;

  AuthRepository({AuthService? authService, ProfileService? profileService})
    : _authService = authService ?? AuthService(),
      _profileService = profileService ?? ProfileService();

  Future<T> _makeAuthenticatedRequest<T>(Future<T> Function() apiCall) async {
    try {
      if (!await _authService.isLoggedIn()) {
        throw AuthException('You must be logged in to perform this action.');
      }
      return await apiCall();
    } on Exception catch (e) {
      if (e.toString().contains('401') ||
          e.toString().contains('Authentication failed')) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return await apiCall(); // Retry the request once
        } else {
          throw AuthException('Your session has expired. Please log in again.');
        }
      }
      rethrow; // Re-throw other exceptions
    }
  }

  // In AuthRepository.dart (THIS IS THE FIX)
  Future<UserModel> googleLogin() async {
    print('DEBUG: AuthRepository.googleLogin() called');
    try {
      final String? idToken = await _authService.getGoogleIdToken();

      if (idToken == null) {
        print('DEBUG: AuthRepository - ID Token is null (canceled)');
        throw AuthException('Google Sign-In was canceled.');
      }
      print(
        'DEBUG: AuthRepository - ID Token obtained, calling loginWithGoogleToken...',
      );

      // Now it's clean, just like your other methods
      final result = await _authService.loginWithGoogleToken(idToken);

      if (result['success'] == true && result['data'] != null) {
        print('DEBUG: AuthRepository - Login successful, parsing user data...');
        return UserModel.fromJson(result['data']);
      } else {
        print('DEBUG: AuthRepository - Login failed: ${result['message']}');
        throw AuthException(result['message'] ?? 'Google login failed.');
      }
    } on AuthException catch (e) {
      print('DEBUG: AuthRepository - AuthException caught: $e');
      rethrow;
    } catch (e) {
      print('DEBUG: AuthRepository - Unexpected exception: $e');
      throw AuthException(e.toString());
    }
  }

  Future<UserModel> appleLogin() async {
    print('DEBUG: AuthRepository.appleLogin() called');
    try {
      final credentials = await _authService.getAppleIdToken();

      if (credentials == null || credentials['idToken'] == null) {
        print('DEBUG: AuthRepository - Apple ID Token is null (canceled)');
        throw AuthException('Apple Sign-In was canceled.');
      }
      print(
        'DEBUG: AuthRepository - Apple ID Token obtained, calling loginWithAppleToken...',
      );

      final idToken = credentials['idToken']!;
      final givenName = credentials['givenName'] ?? '';
      final familyName = credentials['familyName'] ?? '';
      final name = '$givenName $familyName'.trim();

      final result = await _authService.loginWithAppleToken(
        idToken,
        name: name.isEmpty ? null : name,
      );

      if (result['success'] == true && result['data'] != null) {
        print('DEBUG: AuthRepository - Login successful, parsing user data...');
        return UserModel.fromJson(result['data']);
      } else {
        print('DEBUG: AuthRepository - Login failed: ${result['message']}');
        throw AuthException(result['message'] ?? 'Apple login failed.');
      }
    } on AuthException catch (e) {
      print('DEBUG: AuthRepository - AuthException caught: $e');
      rethrow;
    } catch (e) {
      print('DEBUG: AuthRepository - Unexpected exception: $e');
      throw AuthException(e.toString());
    }
  }

  // Future<UserModel> googleLogin() async {
  //   final String? idToken = await _authService.getGoogleIdToken();

  //   if (idToken == null) {
  //     throw AuthException('Google Sign-In was canceled.');
  //   }

  //   final url = Uri.parse('${dotenv.env['API_BASE_URL']}/auth/google/');

  //   try {
  //     final response = await http.post(
  //       url,
  //       body: {'id_token': idToken},
  //     );

  //     final responseData = json.decode(response.body);

  //     if (response.statusCode == 200) {
  //       final String backendToken = responseData['token'];
  //       return UserModel.fromJson(responseData['user']);
  //     } else {
  //       throw AuthException(responseData['error'] ?? 'Google login failed.');
  //     }
  //   } catch (e) {
  //     throw AuthException(e.toString());
  //   }
  // }

  Stream<bool> get authStateChanges => AuthService.authStateChanges;

  Future<UserModel> login(String email, String password) async {
    final result = await _authService.loginUser(email, password);
    if (result['success'] == true && result['data'] != null) {
      return UserModel.fromJson(result['data']);
    } else {
      throw AuthException(result['message'] ?? 'Login failed.');
    }
  }

  Future<void> register(UserModel user) async {
    final result = await _authService.registerUser(user);
    if (result['success'] != true) {
      final errorMessage =
          result['message'] is Map
              ? (result['message'] as Map).values.first[0]
              : result['message'] ?? 'Registration failed.';
      throw AuthException(errorMessage);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<UserModel?> checkAuthStatus() async {
    if (await _authService.isLoggedIn()) {
      return await _authService.getUserData();
    }
    return null;
  }

  Future<UserModel> updateProfile(UserModel user) async {
    return _makeAuthenticatedRequest(() async {
      final result = await _authService.updateProfile(user);
      if (result['success'] == true && result['data'] != null) {
        return UserModel.fromJson(result['data']);
      } else {
        throw AuthException(result['message'] ?? 'Profile update failed.');
      }
    });
  }

  /// Updates the user's address fields
  Future<bool> updateAddress(Map<String, String> addressDetails) async {
    return _makeAuthenticatedRequest(() async {
      return await _authService.updateUserAddress(addressDetails);
    });
  }

  Future<UserModel> uploadProfileImage(File imageFile) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _authService.getAccessToken();
      if (token == null) throw AuthException('Authentication token not found');

      await _profileService.uploadProfileImage(imageFile);

      final updatedUser = await _authService.getUserProfile();
      if (updatedUser == null) {
        throw AuthException(
          'Failed to retrieve updated profile after image upload.',
        );
      }

      final refreshToken = await _authService.getRefreshToken();
      if (refreshToken == null) throw AuthException('Refresh token not found');

      await _authService.saveToken(
        token,
        refreshToken,
        updatedUser.toProfileJson(),
      );
      return updatedUser;
    });
  }

  Future<void> sendOtp(String identifier, String type) async {
    final result = await _authService.sendOtp(
      identifier: identifier,
      type: type,
    );
    if (result['success'] != true) {
      throw AuthException(result['message'] ?? 'Failed to send OTP.');
    }
  }

  Future<void> verifyOtp(String identifier, String otp, String type) async {
    final result = await _authService.verifyOtp(
      identifier: identifier,
      otp: otp,
      type: type,
    );
    if (result['success'] != true) {
      throw AuthException(result['message'] ?? 'OTP verification failed.');
    }
  }

  Future<void> deactivateAccount(String password) async {
    await _makeAuthenticatedRequest(() async {
      final result = await _authService.deactivateAccount(password);
      if (result['success'] != true) {
        throw AuthException(
          result['message'] ?? 'Failed to deactivate account.',
        );
      }
    });
  }

  Future<void> confirmDeactivateAccount(String otp) async {
    await _makeAuthenticatedRequest(() async {
      final result = await _authService.confirmDeactivateAccount(otp);
      if (result['success'] != true) {
        throw AuthException(
          result['message'] ?? 'Failed to confirm deactivation.',
        );
      }
    });
  }
}
