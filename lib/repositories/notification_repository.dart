import 'package:grocery_app/utils/app_logger.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/token_service.dart';
import '../services/api_client.dart';
import '../models/notification_model.dart';
import 'package:grocery_app/service_locator.dart';

class NotificationException implements Exception {
  final String message;
  NotificationException(this.message);
  @override
  String toString() => message;
}


class NotificationRepository {
  final TokenService _tokenService;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  NotificationRepository({TokenService? tokenService})
      : _tokenService = tokenService ?? getIt<TokenService>();

  Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
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
    final token = await _tokenService.getAccessToken();
    if (token == null) {
      AppLogger.instance.log('Cannot register FCM token: User not authenticated.');
      return;
    }

    try {
      final deviceID = await getDeviceId();
      final response = await ApiClient.instance.post(
        '/api/notifications/register-token/',
        data: {
          'token': fcmToken,
          'device_id': deviceID,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
      if (response.statusCode != 200) {
        throw NotificationException('Backend failed to register token: ${response.data}');
      }
      AppLogger.instance.log('FCM token registered with backend successfully.');
    } catch (e) {
      AppLogger.instance.log('Error registering FCM token with backend: $e');
    }
  }

  Future<void> removeToken() async {
    final token = await _tokenService.getAccessToken();
    final fcmToken = await getStoredFCMToken();

    if (token == null || fcmToken == null) {
      AppLogger.instance.log('Cannot remove FCM token: Missing auth token or FCM token.');
      return;
    }

    try {
      final deviceID = await getDeviceId();
      final response = await ApiClient.instance.post(
        '/api/notifications/logout-device/',
        data: {'token': fcmToken, 'device_id': deviceID},
      );
      if (response.statusCode != 200) {
        throw NotificationException('Backend failed to remove token: ${response.data}');
      }
      AppLogger.instance.log('FCM token removed from backend successfully.');
    } catch (e) {
      AppLogger.instance.log('Error removing FCM token from backend: $e');
    }
  }

  // --- NEW SYNCHRONIZATION BACKEND ENDPOINTS ---

  Future<Response> _post(String endpoint, Map<String, dynamic> body) async {
    debugPrint('[SyncManager] POST Request URL: $endpoint');
    return await ApiClient.instance.post(endpoint, data: body);
  }

  Future<Response> _get(String endpoint, {Map<String, String>? queryParams}) async {
    debugPrint('[SyncManager] GET Request URL: $endpoint');
    return await ApiClient.instance.get(endpoint, queryParameters: queryParams);
  }

  /// Register a local notification with the backend database
  Future<NotificationModel> registerLocalNotification(NotificationModel notification) async {
    final response = await _post('/api/notifications/register-local/', notification.toJson());
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = response.data;
      return NotificationModel.fromJson(responseData);
    } else {
      throw NotificationException('Failed to register local notification: ${response.data}');
    }
  }

  /// Synchronize notification state incrementally based on since_version
  Future<Map<String, dynamic>> syncNotifications(int sinceVersion) async {
    final response = await _get(
      '/api/notifications/sync/',
      queryParams: {'since_version': sinceVersion.toString()},
    );
    if (response.statusCode == 200) {
      final responseData = response.data;
      final List<dynamic> notifList = responseData['notifications'] ?? [];
      final List<NotificationModel> notifications = notifList
          .map((n) => NotificationModel.fromJson(n))
          .toList();
      return {
        'latest_version': responseData['latest_version'] ?? sinceVersion,
        'notifications': notifications,
      };
    } else {
      throw NotificationException('Failed to sync notifications: ${response.data}');
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
      return response.data;
    } else {
      throw NotificationException('Failed to mark notifications as read: ${response.data}');
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
      return response.data;
    } else {
      throw NotificationException('Failed to mark notifications as dismissed: ${response.data}');
    }
  }

  /// Get the current active unread count
  Future<int> getUnreadCount() async {
    final response = await _get('/api/notifications/unread-count/');
    if (response.statusCode == 200) {
      final responseData = response.data;
      return responseData['unread_count'] ?? 0;
    } else {
      throw NotificationException('Failed to get unread count: ${response.data}');
    }
  }
}