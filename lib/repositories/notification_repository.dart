import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';

class NotificationException implements Exception {
  final String message;
  NotificationException(this.message);
  @override
  String toString() => message;
}

class NotificationRepository {
  final AuthService _authService;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  NotificationRepository({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // androidId is deprecated, 'id' is the replacement
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_id';
      }
      return 'unsupported_platform';
    } catch (e) {
      return 'unknown_device_id';
    }
  }

  Future<String?> getStoredFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  Future<void> registerToken(String fcmToken) async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      // Don't throw an error, just log it. The cubit will retry on next login.
      print('Cannot register FCM token: User not authenticated.');
      return;
    }

    try {
      final deviceID = await getDeviceId();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/register-token/'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({
          'token': fcmToken,
          'device_id': deviceID,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        }),
      );
      if (response.statusCode != 200) {
        throw NotificationException('Backend failed to register token: ${response.body}');
      }
      print('FCM token registered with backend successfully.');
    } catch (e) {
      // We catch the error here so the app doesn't crash if the backend call fails.
      print('Error registering FCM token with backend: $e');
    }
  }

  Future<void> removeToken() async {
    final token = await _authService.getAccessToken();
    final fcmToken = await getStoredFCMToken();

    if (token == null || fcmToken == null) {
      print('Cannot remove FCM token: Missing auth token or FCM token.');
      return;
    }

    try {
      final deviceID = await getDeviceId();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/logout-device/'),
        headers: ApiConfig.getAuthHeaders(token),
        body: jsonEncode({'token': fcmToken, 'device_id': deviceID}),
      );
      if (response.statusCode != 200) {
        throw NotificationException('Backend failed to remove token: ${response.body}');
      }
      print('FCM token removed from backend successfully.');
    } catch (e) {
      print('Error removing FCM token from backend: $e');
    }
  }
}