import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/services/oauth_service.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';
import 'package:grocery_app/core/utils/apple_auth_state.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:grocery_app/service_locator.dart';

class OAuthService {
  static final OAuthService _instance = OAuthService._internal();
  factory OAuthService() => getIt<OAuthService>();
  OAuthService._internal();
  static OAuthService create() => OAuthService._internal();

  final String serverClientId = dotenv.env["GOOGLE_SERVER_CLIENT_ID"] ?? "";
  final String iosClientId = dotenv.env["GOOGLE_IOS_CLIENT_ID"] ?? "";
  
  // IMPORTANT (iOS): The google_sign_in_ios plugin requires a non-null clientId
  // (from this parameter or GIDClientID in Info.plist), otherwise it crashes
  // natively. serverClientId is ALSO required so the issued idToken has
  // audience = server client ID, which the backend validates.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS && iosClientId.isNotEmpty ? iosClientId : null,
    serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
    scopes: ['email'],
  );

  Future<String?> getGoogleIdToken() async {
    AppLogger.instance.log('DEBUG: Starting Google Sign-In flow...');
    try {
      AppLogger.instance.log(
        'DEBUG: Google Sign-In preflight => platform: ${Platform.operatingSystem}, serverClientIdSet: ${serverClientId.isNotEmpty}, iosClientIdSet: ${iosClientId.isNotEmpty}',
      );

      if (serverClientId.isEmpty) {
        AppLogger.instance.log(
          'WARNING: GOOGLE_SERVER_CLIENT_ID is not set in .env - Google Sign-In will fail',
        );
      }
      if (Platform.isIOS && iosClientId.isEmpty) {
        AppLogger.instance.log(
          'WARNING: GOOGLE_IOS_CLIENT_ID is not set in .env - iOS sign-in may crash without GIDClientID in Info.plist',
        );
      }

      // Ensure previous sign-in is cleared to prevent issues
      AppLogger.instance.log('DEBUG: Clearing cached Google account before signIn()');
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        await _googleSignIn.signOut();
      }
      AppLogger.instance.log('DEBUG: cache clear completed, calling signIn()');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      AppLogger.instance.log('DEBUG: signIn() returned to Dart layer');
      if (googleUser == null) {
        AppLogger.instance.log('DEBUG: Google Sign-In was cancelled by user');
        return null;
      }

      AppLogger.instance.log('DEBUG: Google user signed in: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        AppLogger.instance.log('ERROR: Google Sign-In returned null ID token');
        throw Exception('Failed to obtain Google ID token. Please try again.');
      }
      
      AppLogger.instance.log('DEBUG: Successfully obtained Google ID token');
      return idToken;
    } on PlatformException catch (error) {
      AppLogger.instance.log(
        'DEBUG: Google Sign-In PlatformException: ${error.code} - ${error.message}',
      );
      throw Exception('Google Sign-In failed: ${error.message}');
    } catch (error) {
      AppLogger.instance.log(
        'DEBUG: Google Sign-In Error in getGoogleIdToken: $error',
      );
      rethrow;
    }
  }

  Future<Map<String, String?>?> getAppleIdToken() async {
    AppLogger.instance.log('DEBUG: Starting Apple Sign-In flow...');
    try {
      WebAuthenticationOptions? webOptions;
      if (Platform.isAndroid) {
        final serviceId =
            dotenv.env["APPLE_SERVICE_ID"] ?? "com.anaad.foods.ios.signin";
        final baseUrl = dotenv.env["API_BASE_URL"] ?? ApiConfig.baseUrl;
        final redirectUrl =
            dotenv.env["APPLE_REDIRECT_URI"] ??
            "$baseUrl/api/auth/apple/callback/";

        AppLogger.instance.log(
          'DEBUG: Configuring Apple Sign-in for Android. Service ID: $serviceId, Redirect URL: $redirectUrl',
        );
        AppLogger.instance.log('APPLE_SERVICE_ID = $serviceId');
        AppLogger.instance.log('APPLE_REDIRECT_URI = $redirectUrl');
        webOptions = WebAuthenticationOptions(
          clientId: serviceId,
          redirectUri: Uri.parse(redirectUrl),
        );
      }

      final String platform =
          Platform.isAndroid ? 'flutter_android' : 'flutter_ios';
      final String appleState = AppleAuthState.build(platform);

      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            webAuthenticationOptions: webOptions,
            state: appleState,
          );

      return {
        'idToken': credential.identityToken,
        'givenName': credential.givenName,
        'familyName': credential.familyName,
      };
    } catch (error) {
      AppLogger.instance.log(
        'DEBUG: Apple Sign-In Error in getAppleIdToken: $error',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithGoogleToken(String idToken) async {
    AppLogger.instance.log('DEBUG: loginWithGoogleToken() called with idToken length: ${idToken.length}');
    try {
      AppLogger.instance.log('DEBUG: Posting to /api/auth/google/ with id_token');
      final response = await ApiClient.instance.post(
        '/api/auth/google/',
        data: {'id_token': idToken},
      );

      final responseData = response.data;
      AppLogger.instance.log('DEBUG: Google login response status: ${response.statusCode}, data: $responseData');
      
      if (response.statusCode == 200) {
        await TokenService().saveToken(
          responseData['access'],
          responseData['refresh'],
          responseData['user'],
        );
        AppLogger.instance.log('DEBUG: Google login successful, token saved');
        return {'success': true, 'data': responseData['user']};
      } else {
        AppLogger.instance.log('DEBUG: Google login failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['error'] ?? 'Google login failed.',
        };
      }
    } on DioException catch (e) {
      AppLogger.instance.log('DEBUG: DioException in loginWithGoogleToken: ${e.type}');
      AppLogger.instance.log('DEBUG: Status code: ${e.response?.statusCode}');
      AppLogger.instance.log('DEBUG: Response body: ${e.response?.data}');
      AppLogger.instance.log('DEBUG: Error message: ${e.message}');
      
      final errorMessage = _extractErrorMessage(e);
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      AppLogger.instance.log('DEBUG: Unexpected error in loginWithGoogleToken: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response?.data as Map;
      if (data.containsKey('error')) return data['error']?.toString() ?? 'Google login failed';
      if (data.containsKey('detail')) return data['detail']?.toString() ?? 'Google login failed';
      if (data.containsKey('message')) return data['message']?.toString() ?? 'Google login failed';
    } else if (e.response?.data is String) {
      return e.response?.data as String;
    }
    return 'Google login failed: ${e.message}';
  }

  Future<Map<String, dynamic>> loginWithAppleToken(
    String idToken, {
    String? name,
  }) async {
    try {
      final body = <String, dynamic>{'id_token': idToken};
      if (name != null && name.trim().isNotEmpty) {
        body['name'] = name;
      }

      final response = await ApiClient.instance.post(
        '/api/auth/apple/',
        data: body,
      );

      final responseData = response.data;
      if (response.statusCode == 200) {
        await TokenService().saveToken(
          responseData['access'],
          responseData['refresh'],
          responseData['user'],
        );
        return {'success': true, 'data': responseData['user']};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Apple login failed.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
