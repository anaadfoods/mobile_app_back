import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:dio/dio.dart' as dio;

import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/favorite_state_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => getIt<ProfileService>();
  ProfileService._internal();
  static ProfileService create() => ProfileService._internal();

  static final _addressChangeController =
      StreamController<UserModel?>.broadcast();
  static Stream<UserModel?> get addressChanges =>
      _addressChangeController.stream;

  static final Map<int, int> _favoriteToggleCounts = {};
  static final Map<int, Timer> _favoriteDebouncers = {};

  void _notifyAddressChange() {
    final user = TokenService().currentUser;
    _addressChangeController.add(user);
  }

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      final formData = dio.FormData.fromMap({
        'profile_picture': await dio.MultipartFile.fromFile(imageFile.path),
      });

      final response = await ApiClient.instance.patch(
        '/api/auth/profile/',
        data: formData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Profile image updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update profile image: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error uploading profile image: $e'};
    }
  }

  Future<bool> updateUserAddress(Map<String, String> addressDetails) async {
    try {
      final currentUser =
          TokenService().currentUser ?? await TokenService().getUserData();
      if (currentUser == null) {
        debugPrint('updateUserAddress: no current user data');
        return false;
      }

      final bodyMap = {
        'username': currentUser.username,
        'email': currentUser.email,
        'first_name': currentUser.firstName,
        'last_name': currentUser.lastName,
        'phone_number': addressDetails['phone'] ?? currentUser.phoneNumber,
        'address': addressDetails['address'] ?? '',
        'city': addressDetails['city'] ?? '',
        'state': addressDetails['state'] ?? '',
        'pincode': addressDetails['pincode'] ?? '',
      };

      try {
        final response = await ApiClient.instance.put(
          ApiConfig.profileEndpoint,
          data: bodyMap,
        );

        if (response.statusCode == 200) {
          await getUserProfile();
          _notifyAddressChange();
          return true;
        }
      } catch (firstError) {
        debugPrint(
          'updateUserAddress: first attempt failed (possibly duplicate phone): $firstError',
        );

        // Fallback: If the user entered a phone number different from current profile phone number,
        // try saving the address WITHOUT updating the profile's phone number.
        if (addressDetails['phone'] != null &&
            addressDetails['phone'] != currentUser.phoneNumber) {
          debugPrint(
            'updateUserAddress: retrying without updating profile phone number',
          );
          final fallbackBodyMap = Map<String, dynamic>.from(bodyMap);
          // Revert phone number to the profile's existing value (null or whatever it was)
          fallbackBodyMap['phone_number'] = currentUser.phoneNumber;

          final response = await ApiClient.instance.put(
            ApiConfig.profileEndpoint,
            data: fallbackBodyMap,
          );

          if (response.statusCode == 200) {
            await getUserProfile();
            _notifyAddressChange();
            return true;
          }
        } else {
          // If phone was not changed, the error was due to something else. Re-throw.
          rethrow;
        }
      }
      return false;
    } catch (e, st) {
      debugPrint('updateUserAddress: unexpected error: $e\n$st');
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    try {
      final isAuthenticated = await TokenService().isLoggedIn();
      if (!isAuthenticated) {
        return {
          'success': false,
          'message': 'Please login to manage favorites',
          'requiresLogin': true,
        };
      }

      // Record the tap
      _favoriteToggleCounts[productId] =
          (_favoriteToggleCounts[productId] ?? 0) + 1;
      _favoriteDebouncers[productId]?.cancel();

      // Return a fake optimistic success immediately so the UI can update
      final immediateResult = {
        'success': true,
        'message': 'Favorite updated',
        'isAdded':
            true, // The UI just toggles its boolean, so this exact value is less critical
      };

      // Set a 500ms debounce timer
      _favoriteDebouncers[productId] = Timer(
        const Duration(milliseconds: 500),
        () async {
          final tapCount = _favoriteToggleCounts[productId] ?? 0;
          _favoriteToggleCounts[productId] = 0; // Reset

          // If even number of taps, the net state is unchanged. Do nothing.
          if (tapCount % 2 == 0) return;

          try {
            // If odd number of taps, execute the backend toggle
            await ApiClient.instance.post(
              '${ApiConfig.favoritesEndpoint}$productId/toggle/',
            );
            FavoriteStateService().notifyFavoriteChanged();
          } catch (e) {
            AppLogger.instance.log('Background toggle favorite error: $e');
          }
        },
      );

      return immediateResult;
    } catch (e, stackTrace) {
      AppLogger.instance.log('Toggle favorite error: $e');
      AppLogger.instance.log('Stack Trace: $stackTrace');
      return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final response = await ApiClient.instance.get(
        ApiConfig.favoritesEndpoint,
      );

      if (response.statusCode == 200) {
        final List<dynamic> favoritesJson = response.data;
        final favorites =
            favoritesJson.map((json) => FavoriteModel.fromJson(json)).toList();

        return {
          'success': true,
          'data': favorites,
          'message': 'Favorites fetched successfully',
        };
      } else {
        AppLogger.instance.log(
          'Failed to fetch favorites. Status code: ${response.statusCode}',
        );
        AppLogger.instance.log('Response data: ${response.data}');
        return {
          'success': false,
          'message': 'Failed to fetch favorites',
          'code': 'fetch_error',
        };
      }
    } catch (e, stack) {
      AppLogger.instance.log('Error fetching favorites: $e');
      AppLogger.instance.log('Stack trace: $stack');
      return {
        'success': false,
        'message': 'An error occurred while fetching favorites',
        'error': e.toString(),
      };
    }
  }

  Future<UserModel?> getUserProfile() async {
    try {
      final response = await ApiClient.instance.get(ApiConfig.profileEndpoint);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final userData = responseData['data'];
          final userProfile = UserModel.fromJson(userData);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(userData));
          await prefs.setString('user_data', jsonEncode(userData));

          TokenService().setCurrentUser(userProfile);

          return userProfile;
        }
      }
      return null;
    } catch (e) {
      AppLogger.instance.log('Error getting user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile(UserModel updatedProfile) async {
    try {
      AppLogger.instance.log('Sending update profile request...');

      final response = await ApiClient.instance.put(
        ApiConfig.profileEndpoint,
        data: {
          'first_name': updatedProfile.firstName,
          'last_name': updatedProfile.lastName,
          'address': updatedProfile.address,
          'city': updatedProfile.city,
          'state': updatedProfile.state,
          'pincode': updatedProfile.pincode,
          'username': updatedProfile.username,
          'email': updatedProfile.email,
          'phone_number': updatedProfile.phoneNumber,
        },
      );

      AppLogger.instance.log(
        'Update Profile Response Status: ${response.statusCode}',
      );
      AppLogger.instance.log('Response Body: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        final userData = responseData['data'] ?? responseData;

        if (userData != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(userData));
          await prefs.setString('user_data', jsonEncode(userData));

          final userProfile = UserModel.fromJson(userData);
          TokenService().setCurrentUser(userProfile);
          _notifyAddressChange();

          return {
            'success': true,
            'message': 'Profile updated successfully',
            'data': userData,
          };
        }
      }

      try {
        final responseData = response.data;
        final message =
            responseData['message'] ??
            responseData['detail'] ??
            responseData['error'] ??
            'Failed to update profile';
        return {'success': false, 'message': message};
      } catch (_) {
        return {
          'success': false,
          'message': 'Failed to update profile. Please try again.',
        };
      }
    } catch (e) {
      AppLogger.instance.log('Error updating profile: $e');
      return {
        'success': false,
        'message':
            'An error occurred while updating profile. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> sendOtp({
    required String identifier,
    required String type,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.sendOtpEndpoint,
        data: {'identifier': identifier, 'type': type},
      );
      final responseData = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      AppLogger.instance.log('Send OTP error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otp,
    required String type,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/api/auth/verify-otp/',
        data: {'identifier': identifier, 'otp': otp, 'type': type},
      );
      final responseData = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP verified successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to verify OTP',
        };
      }
    } catch (e) {
      AppLogger.instance.log('Verify OTP error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deactivateAccount(String password) async {
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.deactivateEndpoint,
        data: {'password': password},
      );

      final responseData = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              responseData['detail'] ??
              'Failed to request deactivation',
        };
      }
    } on dio.DioException catch (e) {
      AppLogger.instance.log('Deactivate account DioException: $e');
      String errorMessage = 'Failed to deactivate account';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage =
              responseData['message'] ??
              responseData['detail'] ??
              responseData['error'] ??
              errorMessage;
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMessage = responseData;
        }
      }
      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    } catch (e) {
      AppLogger.instance.log('Deactivate account error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> confirmDeactivateAccount(String otp) async {
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.deactivateConfirmEndpoint,
        data: {'otp': otp},
      );

      final responseData = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await TokenService().clearToken();
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Account deactivated successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              responseData['detail'] ??
              'Failed to confirm deactivation',
        };
      }
    } on dio.DioException catch (e) {
      AppLogger.instance.log('Confirm deactivate account DioException: $e');
      String errorMessage = 'Failed to confirm deactivation';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage =
              responseData['message'] ??
              responseData['detail'] ??
              responseData['error'] ??
              errorMessage;
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMessage = responseData;
        }
      }
      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    } catch (e) {
      AppLogger.instance.log('Confirm deactivate account error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }
}
