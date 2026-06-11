import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:grocery_app/service_locator.dart';

class OAuthService {
  static final OAuthService _instance = OAuthService._internal();
  factory OAuthService() => getIt<OAuthService>();
  OAuthService._internal();
  static OAuthService create() => OAuthService._internal();

  final String serverClientId = dotenv.env["GOOGLE_SERVER_CLIENT_ID"] ?? "";
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: serverClientId,
    scopes: ['email'],
  );

  Future<String?> getGoogleIdToken() async {
    AppLogger.instance.log('DEBUG: Starting Google Sign-In flow...');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      return googleAuth.idToken;
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

      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            webAuthenticationOptions: webOptions,
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
    try {
      final response = await ApiClient.instance.post(
        '/api/auth/google/',
        data: {'id_token': idToken},
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
          'message': responseData['error'] ?? 'Google login failed.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
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
