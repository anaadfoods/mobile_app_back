import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static final _authStateController = StreamController<bool>.broadcast();
  static Stream<bool> get authStateChanges => _authStateController.stream;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  final String serverClientId = dotenv.env["GOOGLE_SERVER_CLIENT_ID"] ?? "";

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: serverClientId,
    scopes: ['email'],
  );

  Future<String?> getGoogleIdToken() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      return googleAuth.idToken;
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  // In AuthService.dart
  Future<Map<String, dynamic>> loginWithGoogleToken(String idToken) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/google/',
    ); // Or your env var
    try {
      final response = await http.post(
        url,
        body: {'id_token': idToken},
        // Add headers if needed
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        // You must also save the token here, just like in loginUser
        await saveToken(
          responseData['access'], // Adjust keys as needed
          responseData['refresh'],
          responseData['user'],
        );
        return {'success': true, 'data': responseData['user']};
      } else {
        print("Errror occured with else reason");
        return {
          'success': false,
          'message': responseData['error'] ?? 'Google login failed.',
        };
      }
    } catch (e) {
      print('Google login error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> saveToken(
    String accessToken,
    String refreshToken,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_data', jsonEncode(userData));

    _currentUser = UserModel.fromJson(userData);
    _authStateController.add(true);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<UserModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userData));
      return _currentUser;
    }
    return null;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    _currentUser = null;
    _authStateController.add(false);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token != null) {
      if (_currentUser == null) {
        await getUserData();
      }
      return true;
    }
    return false;
  }

  Future<void> initializeAuthState() async {
    final isLoggedIn = await this.isLoggedIn();
    _authStateController.add(isLoggedIn);
  }

  void dispose() {
    _authStateController.close();
  }

  Future<Map<String, dynamic>> registerUser(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      final responseData = jsonDecode(response.body);
      print('Response data: $responseData');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': responseData ?? 'Registration failed',
          'errors': responseData['errors'] ?? {},
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print(
        'Making login request to: ${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
      );

      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'email': email, 'password': password}),
            )
            .timeout(
              Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Login request timed out');
              },
            );

        print('Response status code: ${response.statusCode}');

        if (response.body.isEmpty) {
          return {
            'success': false,
            'message': 'Server returned empty response',
          };
        }

        final responseData = jsonDecode(response.body);
        print('Response data received');

        if (response.statusCode == 200) {
          if (responseData['access'] != null &&
              responseData['refresh'] != null &&
              responseData['user'] != null) {
            await saveToken(
              responseData['access'],
              responseData['refresh'],
              responseData['user'],
            );

            return {
              'success': true,
              'data': responseData['user'],
              'message': 'Login successful',
            };
          } else {
            return {
              'success': false,
              'message': 'Invalid server response format',
              'errors': {'token': 'Missing required data in response'},
            };
          }
        } else if (response.statusCode == 401) {
          return {'success': false, 'message': 'Invalid email or password'};
        } else {
          return {
            'success': false,
            'message':
                responseData['detail'] ??
                responseData['message'] ??
                'Server error occurred',
            'errors': responseData['errors'] ?? {},
          };
        }
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      if (e is TimeoutException) {
        return {
          'success': false,
          'message': 'Connection timed out. Please try again.',
        };
      }

      print('Login error: $e');
      print('Stack trace: $stackTrace');

      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getAccessToken();
    return ApiConfig.getAuthHeaders(token ?? '');
  }

  Future<bool> _checkAndRefreshToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.testTokenEndpoint}'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 401) {
        return await refreshAccessToken();
      }

      return true;
    } catch (e) {
      print('Token check error: $e');
      return false;
    }
  }

  /// Returns true on success. On failure, logs server response and returns false.
  Future<bool> updateUserAddress(Map<String, String> addressDetails) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        debugPrint('updateUserAddress: no access token');
        return false;
      }

      // Get current user data to include required fields
      final currentUser = _currentUser ?? await getUserData();
      if (currentUser == null) {
        debugPrint('updateUserAddress: no current user data');
        return false;
      }

      // Use the correct profile endpoint from ApiConfig
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}');

      // Include all required user fields along with address updates
      final bodyMap = {
        // Required user fields from current profile
        'username': currentUser.username,
        'email': currentUser.email,
        'first_name': currentUser.firstName,
        'last_name': currentUser.lastName,
        'phone_number': addressDetails['phone'] ?? currentUser.phoneNumber,
        // Address fields to update
        'address': addressDetails['address'] ?? '',
        'city': addressDetails['city'] ?? '',
        'state': addressDetails['state'] ?? '',
        'pincode': addressDetails['pincode'] ?? '',
      };

      debugPrint('updateUserAddress: sending -> $bodyMap to $uri');

      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'updateUserAddress: status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode == 200) {
        // refresh local profile to update _currentUser
        await getUserProfile();
        return true;
      }

      // Handle 401 - try to refresh token and retry once
      if (response.statusCode == 401) {
        debugPrint(
          'updateUserAddress: Unauthorized - attempting token refresh',
        );
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry the request with new token
          return await updateUserAddress(addressDetails);
        }
        debugPrint('updateUserAddress: Token refresh failed');
        return false;
      }

      // Handle 400 - validation errors
      if (response.statusCode == 400) {
        try {
          final decoded = jsonDecode(response.body);
          debugPrint('updateUserAddress validation errors: $decoded');
        } catch (_) {}
      }

      return false;
    } on TimeoutException catch (_) {
      debugPrint('updateUserAddress: request timed out');
      return false;
    } catch (e, st) {
      debugPrint('updateUserAddress: unexpected error: $e\n$st');
      return false;
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    try {
      final isAuthenticated = await isLoggedIn();
      if (!isAuthenticated) {
        return {
          'success': false,
          'message': 'Please login to manage favorites',
          'requiresLogin': true,
        };
      }

      final tokenValid = await _checkAndRefreshToken();
      if (!tokenValid) {
        return {
          'success': false,
          'message': 'Authentication failed',
          'requiresLogin': true,
        };
      }

      final client = http.Client();
      try {
        final url = Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.favoritesEndpoint}$productId/toggle/',
        );
        final headers = await _getAuthHeaders();

        final response = await client
            .post(url, headers: headers)
            .timeout(
              Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Request timed out');
              },
            );

        if (response.body.trim().isEmpty) {
          return {
            'success': false,
            'message': 'Element Removed from favorites',
          };
        }

        final responseData = jsonDecode(response.body);

        if (responseData is Map<String, dynamic> &&
            responseData['status'] == 'error') {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to update favorite',
          };
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          final isAdded =
              responseData['message']?.toLowerCase().contains(
                'added successfully',
              ) ??
              false;
          final message =
              isAdded
                  ? 'Added to favorites successfully'
                  : 'Removed from favorites successfully';

          return {
            'success': true,
            'message': message,
            'data': responseData['data'],
            'isAdded': isAdded,
          };
        } else if (response.statusCode == 401) {
          return {
            'success': false,
            'message': 'Please login again',
            'requiresLogin': true,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Unexpected error occurred',
          };
        }
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      print('Toggle favorite error: $e');
      print('Stack Trace: $stackTrace');
      return {'success': false, 'message': 'Unexpected error: ${e.toString()}'};
    }
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshEndpoint}'),
        headers: ApiConfig.getBaseHeaders(),
        body: jsonEncode({'refresh': refreshToken}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['access'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', responseData['access']);
        return true;
      }
    } catch (e) {
      print('Token refresh error: $e');
    }

    return false;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');

      _currentUser = null;
      _authStateController.add(false);
    } catch (e) {
      print('Error during logout: $e');
      throw Exception('Failed to logout');
    }
  }

  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
          'code': 'unauthenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.favoritesEndpoint}'),
        headers: ApiConfig.getAuthHeaders(accessToken),
      );

      if (response.statusCode == 200) {
        final List<dynamic> favoritesJson = jsonDecode(response.body);
        final favorites =
            favoritesJson.map((json) => FavoriteModel.fromJson(json)).toList();

        return {
          'success': true,
          'data': favorites,
          'message': 'Favorites fetched successfully',
        };
      } else if (response.statusCode == 401) {
        final refreshResult = await refreshAccessToken();
        if (refreshResult) {
          return getFavorites();
        } else {
          return {
            'success': false,
            'message': 'Session expired',
            'code': 'token_expired',
          };
        }
      } else {
        print('Failed to fetch favorites. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Failed to fetch favorites',
          'code': 'fetch_error',
        };
      }
    } catch (e, stack) {
      print('Error fetching favorites: $e');
      print('Stack trace: $stack');
      return {
        'success': false,
        'message': 'An error occurred while fetching favorites',
        'error': e.toString(),
      };
    }
  }

  Future<UserModel?> getUserProfile() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final userData = responseData['data'];
          final userProfile = UserModel.fromJson(userData);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(userData));

          return userProfile;
        }
      } else if (response.statusCode == 401) {
        final refreshResult = await refreshAccessToken();
        if (refreshResult) {
          return getUserProfile();
        }
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile(UserModel updatedProfile) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print(
        'Sending update profile request to: ${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}',
      );

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profileEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': updatedProfile.firstName,
          'last_name': updatedProfile.lastName,
          'address': updatedProfile.address,
          'city': updatedProfile.city,
          'state': updatedProfile.state,
          'pincode': updatedProfile.pincode,
          'username': updatedProfile.username,
          'email': updatedProfile.email,
          'phone_number': updatedProfile.phoneNumber,
        }),
      );

      print('Update Profile Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final userData = responseData['data'] ?? responseData;

        if (userData != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(userData));
          await prefs.setString('user_data', jsonEncode(userData));

          _currentUser = UserModel.fromJson(userData);
          _authStateController.add(true);

          return {
            'success': true,
            'message': 'Profile updated successfully',
            'data': userData,
          };
        }
      } else if (response.statusCode == 401) {
        final refreshResult = await refreshAccessToken();
        if (refreshResult) {
          return updateProfile(updatedProfile);
        }
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      }

      try {
        final responseData = jsonDecode(response.body);
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
      print('Error updating profile: $e');
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sendOtpEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'type': type}),
      );
      final responseData = jsonDecode(response.body);
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
      print('Send OTP error: $e');
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'otp': otp, 'type': type}),
      );
      final responseData = jsonDecode(response.body);
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
      print('Verify OTP error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }
}
