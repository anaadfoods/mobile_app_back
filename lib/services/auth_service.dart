import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/favorite_model.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String registerEndpoint = '/api/auth/register/';
  static const String loginEndpoint = '/api/auth/token/';
  static const String refreshEndpoint = '/api/auth/token/refresh/';
  static const String favoritesEndpoint = '/api/auth/favorites/';

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Stream controller for auth state changes
  static final _authStateController = StreamController<bool>.broadcast();
  static Stream<bool> get authStateChanges => _authStateController.stream;

  // Current user data
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Save JWT tokens and user data
  Future<void> saveToken(
    String accessToken,
    String refreshToken,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('user_data', jsonEncode(userData));

    // Set the current user
    _currentUser = UserModel.fromJson(userData);
    _authStateController.add(true);
  }

  // Get stored access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get stored refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  // Get stored user data
  Future<UserModel?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userData));
      return _currentUser;
    }
    return null;
  }

  // Clear tokens and user data on logout
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    _currentUser = null;
    _authStateController.add(false);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token != null) {
      // If we have a token but no current user, try to load user data
      if (_currentUser == null) {
        await getUserData();
      }
      return true;
    }
    return false;
  }

  // Initialize auth state
  Future<void> initializeAuthState() async {
    final isLoggedIn = await this.isLoggedIn();
    _authStateController.add(isLoggedIn);
  }

  // Dispose the stream controller
  void dispose() {
    _authStateController.close();
  }

  // Register User
  Future<Map<String, dynamic>> registerUser(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$registerEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
          'message': 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
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

  // Login User
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print('Making login request to: $baseUrl$loginEndpoint');

      // Create the client outside the try block to ensure proper cleanup
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse('$baseUrl$loginEndpoint'),
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
            // Save tokens and user data
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

  // Helper method to get authenticated headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Check if access token is expired and refresh if needed
  Future<bool> _checkAndRefreshToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      // Check if token is expired by making a test request
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/test-token/'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 401) {
        // Token expired, try to refresh
        return await refreshAccessToken();
      }

      return true;
    } catch (e) {
      print('Token check error: $e');
      return false;
    }
  }

Future<Map<String, dynamic>> toggleFavorite(int productId) async {
  try {
    // Check if the user is authenticated
    final isAuthenticated = await isLoggedIn();
    if (!isAuthenticated) {
      return {
        'success': false,
        'message': 'Please login to manage favorites',
        'requiresLogin': true,
      };
    }

    // Refresh token if needed
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
      final url = Uri.parse('$baseUrl$favoritesEndpoint$productId/toggle/');
      final headers = await _getAuthHeaders();

      // Send the POST request to toggle the favorite
      final response = await client
          .post(url, headers: headers)
          .timeout(Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Request timed out');
      });

      print('Toggle favorite response status: ${response.statusCode}');
      print('Response body: "${response.body}"');

      // Handle empty or non-JSON responses
      if (response.body.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Element Removed from favorites',
        };
      }

      // Attempt to parse the response
      final responseData = jsonDecode(response.body);

      // Handle known error format
      if (responseData is Map<String, dynamic> && responseData['status'] == 'error') {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update favorite',
        };
      }

      // Handle successful responses
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if the item was added or removed
        final isAdded = responseData['message']
            ?.toLowerCase()
            .contains('added successfully') ??
            false;

        final message = isAdded
            ? 'Added to favorites successfully'
            : 'Removed from favorites successfully';

        return {
          'success': true,
          'message': message,
          'data': responseData['data'],
          'isAdded': isAdded,
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        return {
          'success': false,
          'message': 'Please login again',
          'requiresLogin': true,
        };
      } else {
        // Handle unexpected status codes
        return {
          'success': false,
          'message': responseData['message'] ?? 'Unexpected error occurred',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please try again.',
      };
    } catch (e, stackTrace) {
      print('Toggle favorite error: $e');
      print('Stack Trace: $stackTrace');
      return {
        'success': false,
        'message': 'Failed to update favorite: ${e.toString()}',
      };
    } finally {
      client.close();
    }
  } catch (e, stackTrace) {
    print('Toggle favorite error: $e');
    print('Stack Trace: $stackTrace');
    return {
      'success': false,
      'message': 'Unexpected error: ${e.toString()}',
    };
  }
}

  // Refresh Access Token
  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$refreshEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear tokens and user data
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');

      // Clear current user
      _currentUser = null;
      // Notify listeners about auth state change
      _authStateController.add(false);
    } catch (e) {
      print('Error during logout: $e');
      throw Exception('Failed to logout');
    }
  }

  // Get user's favorite items
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
        Uri.parse('$baseUrl$favoritesEndpoint'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      print('Favorites API Response Status: ${response.statusCode}');
      print('Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> favoritesJson = jsonDecode(response.body);
        print('Decoded favorites JSON: $favoritesJson');

        final favorites =
            favoritesJson.map((json) {
              try {
                // Each item in the list is already a complete favorite object
                return FavoriteModel.fromJson(json);
              } catch (e, stack) {
                print('Error parsing favorite: $json');
                print('Parse error: $e');
                print('Stack trace: $stack');
                rethrow;
              }
            }).toList();

        return {
          'success': true,
          'data': favorites,
          'message': 'Favorites fetched successfully',
        };
      } else if (response.statusCode == 401) {
        // Try to refresh the token
        final refreshResult = await refreshAccessToken();
        if (refreshResult) {
          // Retry with new token
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
}
