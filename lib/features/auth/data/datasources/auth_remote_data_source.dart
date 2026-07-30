import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/utils/app_logger.dart';
import 'package:grocery_app/core/utils/apple_auth_state.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(String email, String password);
  Future<void> register(UserModel user);
  Future<AuthResponse> googleLogin();
  Future<AuthResponse> appleLogin();
  Future<bool> verifyToken();
  Future<Map<String, String>?> refreshAccessToken(String refreshToken);
  Future<UserModel> updateProfile(UserModel user);
  Future<bool> updateAddress(UserModel currentUser, Map<String, String> addressDetails);
  Future<void> uploadProfileImage(File imageFile);
  Future<UserModel> getUserProfile();
  Future<void> sendOtp(String identifier, String type);
  Future<void> verifyOtp(String identifier, String otp, String type);
  Future<void> deactivateAccount(String password);
  Future<void> confirmDeactivateAccount(String otp);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;
  
  AuthRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  final String serverClientId = dotenv.env["GOOGLE_SERVER_CLIENT_ID"] ?? "";
  final String iosClientId = dotenv.env["GOOGLE_IOS_CLIENT_ID"] ?? "";

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS && iosClientId.isNotEmpty ? iosClientId : null,
    serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
    scopes: ['email'],
  );

  @override
  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiConfig.loginEndpoint,
      data: {'email': email, 'password': password},
    );

    final responseData = response.data;
    if (response.statusCode == 200) {
      if (responseData['access'] != null &&
          responseData['refresh'] != null &&
          responseData['user'] != null) {
        return AuthResponse.fromJson(responseData);
      }
    }
    throw dio.DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Invalid email or password',
    );
  }

  @override
  Future<void> register(UserModel user) async {
    final Map<String, dynamic> requestData = user.toJson();
    final String deviceId = await NotificationService.getDeviceId();
    requestData['device_id'] = deviceId;

    await _apiClient.post(
      ApiConfig.registerEndpoint,
      data: requestData,
    );
  }

  @override
  Future<AuthResponse> googleLogin() async {
    AppLogger.instance.log('DEBUG: Starting Google Sign-In flow in data source...');
    // Ensure previous sign-in is cleared to prevent issues
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw PlatformException(code: 'CANCELED', message: 'Google Sign-In cancelled');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Failed to obtain Google ID token.');
    }

    final response = await _apiClient.post(
      '/api/auth/google/',
      data: {'id_token': idToken},
    );

    if (response.statusCode == 200 && response.data != null) {
      return AuthResponse.fromJson(response.data);
    }
    throw Exception('Google login failed: ${response.statusCode}');
  }

  @override
  Future<AuthResponse> appleLogin() async {
    WebAuthenticationOptions? webOptions;
    if (Platform.isAndroid) {
      final serviceId = dotenv.env["APPLE_SERVICE_ID"] ?? "com.anaad.foods.ios.signin";
      final baseUrl = dotenv.env["API_BASE_URL"] ?? ApiConfig.baseUrl;
      final redirectUrl = dotenv.env["APPLE_REDIRECT_URI"] ?? "$baseUrl/api/auth/apple/callback/";

      webOptions = WebAuthenticationOptions(
        clientId: serviceId,
        redirectUri: Uri.parse(redirectUrl),
      );
    }

    final String platform = Platform.isAndroid ? 'flutter_android' : 'flutter_ios';
    final String appleState = AppleAuthState.build(platform);

    final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: webOptions,
      state: appleState,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Failed to obtain Apple ID token.');
    }

    final givenName = credential.givenName ?? '';
    final familyName = credential.familyName ?? '';
    final name = '$givenName $familyName'.trim();

    final body = <String, dynamic>{'id_token': idToken};
    if (name.isNotEmpty) {
      body['name'] = name;
    }

    final response = await _apiClient.post(
      '/api/auth/apple/',
      data: body,
    );

    if (response.statusCode == 200 && response.data != null) {
      return AuthResponse.fromJson(response.data);
    }
    throw Exception('Apple login failed: ${response.statusCode}');
  }

  @override
  Future<bool> verifyToken() async {
    try {
      final response = await _apiClient.get(ApiConfig.testTokenEndpoint);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, String>?> refreshAccessToken(String refreshToken) async {
    final client = dio.Dio();
    final response = await client.post(
      '${ApiConfig.baseUrl}${ApiConfig.refreshEndpoint}',
      data: {'refresh': refreshToken},
      options: dio.Options(headers: ApiConfig.getBaseHeaders()),
    );

    if (response.statusCode == 200 && response.data['access'] != null) {
      return {
        'access': response.data['access'] as String,
        'refresh': response.data['refresh'] as String? ?? refreshToken,
      };
    }
    return null;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final response = await _apiClient.put(
      ApiConfig.profileEndpoint,
      data: {
        'first_name': user.firstName,
        'last_name': user.lastName,
        'address': user.address,
        'city': user.city,
        'state': user.state,
        'pincode': user.pincode,
        'username': user.username,
        'email': user.email,
        'phone_number': user.phoneNumber,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] ?? response.data;
      if (data != null) {
        return UserModel.fromJson(data);
      }
    }
    throw Exception('Failed to update profile');
  }

  @override
  Future<bool> updateAddress(UserModel currentUser, Map<String, String> addressDetails) async {
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
      final response = await _apiClient.put(
        ApiConfig.profileEndpoint,
        data: bodyMap,
      );
      return response.statusCode == 200;
    } catch (e) {
      // Fallback if phone was updated and failed due to duplicate
      if (addressDetails['phone'] != null && addressDetails['phone'] != currentUser.phoneNumber) {
        final fallbackBodyMap = Map<String, dynamic>.from(bodyMap);
        fallbackBodyMap['phone_number'] = currentUser.phoneNumber;
        final response = await _apiClient.put(
          ApiConfig.profileEndpoint,
          data: fallbackBodyMap,
        );
        return response.statusCode == 200;
      }
      rethrow;
    }
  }

  @override
  Future<void> uploadProfileImage(File imageFile) async {
    final formData = dio.FormData.fromMap({
      'profile_picture': await dio.MultipartFile.fromFile(imageFile.path),
    });

    final response = await _apiClient.patch(
      '/api/auth/profile/',
      data: formData,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload profile picture: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> getUserProfile() async {
    final response = await _apiClient.get(ApiConfig.profileEndpoint);
    if (response.statusCode == 200 && response.data['data'] != null) {
      return UserModel.fromJson(response.data['data']);
    }
    throw Exception('Failed to fetch user profile');
  }

  @override
  Future<void> sendOtp(String identifier, String type) async {
    await _apiClient.post(
      ApiConfig.sendOtpEndpoint,
      data: {'identifier': identifier, 'type': type},
    );
  }

  @override
  Future<void> verifyOtp(String identifier, String otp, String type) async {
    await _apiClient.post(
      '/api/auth/verify-otp/',
      data: {'identifier': identifier, 'otp': otp, 'type': type},
    );
  }

  @override
  Future<void> deactivateAccount(String password) async {
    await _apiClient.post(
      ApiConfig.deactivateEndpoint,
      data: {'password': password},
    );
  }

  @override
  Future<void> confirmDeactivateAccount(String otp) async {
    await _apiClient.post(
      ApiConfig.deactivateConfirmEndpoint,
      data: {'otp': otp},
    );
  }
}
