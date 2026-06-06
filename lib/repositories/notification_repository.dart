import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../models/notification_model.dart';

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

  // --- NEW SYNCHRONIZATION BACKEND ENDPOINTS ---

  Future<http.Response> _sendWithRetry(Future<http.Response> Function() requestFn) async {
    var response = await requestFn();
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshAccessToken();
      if (refreshed) {
        response = await requestFn();
      }
    }
    return response;
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    return _sendWithRetry(() async {
      final token = await _authService.getAccessToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      debugPrint('[SyncManager] POST Request URL: $uri');
      return http.post(
        uri,
        headers: ApiConfig.getAuthHeaders(token ?? ''),
        body: jsonEncode(body),
      );
    });
  }

  Future<http.Response> _get(String endpoint, {Map<String, String>? queryParams}) async {
    return _sendWithRetry(() async {
      final token = await _authService.getAccessToken();
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      debugPrint('[SyncManager] GET Request URL: $uri');
      return http.get(
        uri,
        headers: ApiConfig.getAuthHeaders(token ?? ''),
      );
    });
  }

  /// Register a local notification with the backend database
  Future<NotificationModel> registerLocalNotification(NotificationModel notification) async {
    final response = await _post('/api/notifications/register-local/', notification.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return NotificationModel.fromJson(responseData);
    } else {
      throw NotificationException('Failed to register local notification: ${response.body}');
    }
  }

  /// Synchronize notification state incrementally based on since_version
  Future<Map<String, dynamic>> syncNotifications(int sinceVersion) async {
    final response = await _get(
      '/api/notifications/sync/',
      queryParams: {'since_version': sinceVersion.toString()},
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> notifList = responseData['notifications'] ?? [];
      final List<NotificationModel> notifications = notifList
          .map((n) => NotificationModel.fromJson(n))
          .toList();
      return {
        'latest_version': responseData['latest_version'] ?? sinceVersion,
        'notifications': notifications,
      };
    } else {
      throw NotificationException('Failed to sync notifications: ${response.body}');
    }
  }

  /// Bulk mark notifications as read in database
  Future<Map<String, dynamic>> markNotificationsAsRead(List<String> ids) async {
    final deviceId = await getDeviceId();
    final response = await _post('/api/notifications/read/', {
      'notification_ids': ids,
      'origin_device_id': deviceId,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw NotificationException('Failed to mark notifications as read: ${response.body}');
    }
  }

  /// Bulk mark notifications as dismissed (swiped away) in database
  Future<Map<String, dynamic>> markNotificationsAsDismissed(List<String> ids) async {
    final deviceId = await getDeviceId();
    final response = await _post('/api/notifications/dismiss/', {
      'notification_ids': ids,
      'origin_device_id': deviceId,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw NotificationException('Failed to mark notifications as dismissed: ${response.body}');
    }
  }

  /// Get the current active unread count
  Future<int> getUnreadCount() async {
    final response = await _get('/api/notifications/unread-count/');
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['unread_count'] ?? 0;
    } else {
      throw NotificationException('Failed to get unread count: ${response.body}');
    }
  }
}