import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:dio/dio.dart' as dio;

import 'package:grocery_app/service_locator.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => getIt<TokenService>();
  TokenService._internal();
  static TokenService create() => TokenService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static final _authStateController = StreamController<bool>.broadcast();
  static Stream<bool> get authStateChanges => _authStateController.stream;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    if (user != null) {
      _authStateController.add(true);
    }
  }

  Future<void> saveToken(
    String accessToken,
    String refreshToken,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    await prefs.setString('user_data', jsonEncode(userData));

    _currentUser = UserModel.fromJson(userData);
    _authStateController.add(true);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
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
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('user_profile');
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
    final loggedIn = await isLoggedIn();
    _authStateController.add(loggedIn);
  }

  Future<Map<String, dynamic>> registerUser(UserModel user) async {
    try {
      final Map<String, dynamic> requestData = user.toJson();
      final String deviceId = await NotificationService.getDeviceId();
      requestData['device_id'] = deviceId;

      final response = await ApiClient.instance.post(
        ApiConfig.registerEndpoint,
        data: requestData,
      );

      final responseData = response.data;
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
    } on dio.DioException catch (e) {
      String errorMessage = 'Registration failed.';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          if (responseData['detail'] != null) {
            errorMessage = responseData['detail'].toString();
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          } else if (responseData['error'] != null) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.isNotEmpty) {
            final errors = <String>[];
            responseData.forEach((key, value) {
              if (value is List) {
                errors.add('$key: ${value.join(", ")}');
              } else {
                errors.add('$key: $value');
              }
            });
            errorMessage = errors.join('; ');
          }
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMessage = responseData;
        }
      } else {
        errorMessage = 'Network error occurred: ${e.message ?? e.toString()}';
      }
      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      final responseData = response.data;
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
          'message': responseData['detail'] ?? responseData['message'] ?? 'Server error occurred',
          'errors': responseData['errors'] ?? {},
        };
      }
    } on dio.DioException catch (e) {
      String errorMessage = 'Invalid email or password';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          if (responseData['detail'] != null) {
            errorMessage = responseData['detail'].toString();
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          } else if (responseData['error'] != null) {
            errorMessage = responseData['error'].toString();
          } else if (responseData.isNotEmpty) {
            final errors = <String>[];
            responseData.forEach((key, value) {
              if (value is List) {
                errors.add('$key: ${value.join(", ")}');
              } else {
                errors.add('$key: $value');
              }
            });
            errorMessage = errors.join('; ');
          }
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMessage = responseData;
        }
      } else {
        errorMessage = 'Network error occurred: ${e.message ?? e.toString()}';
      }
      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  Future<bool> verifyAndRefreshToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final response = await ApiClient.instance.get(ApiConfig.testTokenEndpoint);
      return response.statusCode == 200;
    } catch (e) {
      return await getAccessToken() != null;
    }
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final dioClient = dio.Dio();
      final response = await dioClient.post(
        '${ApiConfig.baseUrl}${ApiConfig.refreshEndpoint}',
        data: {'refresh': refreshToken},
        options: dio.Options(headers: ApiConfig.getBaseHeaders()),
      );

      if (response.statusCode == 200 && response.data['access'] != null) {
        await _secureStorage.write(
          key: 'access_token',
          value: response.data['access'],
        );
        // Save rotated refresh token — the old one is now invalidated
        if (response.data['refresh'] != null) {
          await _secureStorage.write(
            key: 'refresh_token',
            value: response.data['refresh'],
          );
        }
        return true;
      }
    } catch (e) {
      AppLogger.instance.log('Token refresh error: $e');
    }

    return false;
  }

  Future<void> logout() async {
    try {
      await clearToken();
    } catch (e) {
      AppLogger.instance.log('Error during logout: $e');
      throw Exception('Failed to logout');
    }
  }
}
