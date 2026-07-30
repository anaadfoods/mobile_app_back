import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/models/notification_model.dart';
import 'package:grocery_app/features/notifications/domain/failures/notification_failure.dart';
import 'package:grocery_app/service_locator.dart';

abstract class NotificationsRemoteDataSource {
  Future<String> getDeviceId();
  Future<void> registerDeviceToken(String fcmToken);
  Future<void> unregisterDeviceToken(String fcmToken);
  Future<NotificationModel> registerLocalNotification(NotificationModel notification);
  Future<Map<String, dynamic>> syncNotifications(int sinceVersion);
  Future<void> markNotificationsAsRead(List<String> ids);
  Future<void> markNotificationsAsDismissed(List<String> ids);
  Future<int> getUnreadCount();
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final TokenService _tokenService;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  NotificationsRemoteDataSourceImpl({TokenService? tokenService})
      : _tokenService = tokenService ?? getIt<TokenService>();

  @override
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
    } catch (_) {
      return 'unknown_device_id';
    }
  }

  @override
  Future<void> registerDeviceToken(String fcmToken) async {
    final token = await _tokenService.getAccessToken();
    if (token == null) return;

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
        throw NotificationFailure.server('Failed to register token');
      }
    } catch (e) {
      if (e is NotificationFailure) rethrow;
      throw NotificationFailure.network('Network error during token registration');
    }
  }

  @override
  Future<void> unregisterDeviceToken(String fcmToken) async {
    final token = await _tokenService.getAccessToken();
    if (token == null) return;

    try {
      final deviceID = await getDeviceId();
      await ApiClient.instance.post(
        '/api/notifications/logout-device/',
        data: {'token': fcmToken, 'device_id': deviceID},
      );
    } catch (_) {}
  }

  @override
  Future<NotificationModel> registerLocalNotification(NotificationModel notification) async {
    try {
      final response = await ApiClient.instance.post(
        '/api/notifications/register-local/',
        data: notification.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return NotificationModel.fromJson(response.data);
      }
      throw NotificationFailure.server('Failed to register local notification');
    } catch (e) {
      if (e is NotificationFailure) rethrow;
      throw NotificationFailure.network('Network error registering local notification');
    }
  }

  @override
  Future<Map<String, dynamic>> syncNotifications(int sinceVersion) async {
    try {
      final response = await ApiClient.instance.get(
        '/api/notifications/sync/',
        queryParameters: {'since_version': sinceVersion.toString()},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> notifList = data['notifications'] ?? [];
        final notifications = notifList
            .map((n) => NotificationModel.fromJson(n))
            .toList();
        return {
          'latest_version': data['latest_version'] ?? sinceVersion,
          'notifications': notifications,
        };
      }
      throw NotificationFailure.server('Sync failed');
    } catch (e) {
      if (e is NotificationFailure) rethrow;
      throw NotificationFailure.network('Network error during sync');
    }
  }

  @override
  Future<void> markNotificationsAsRead(List<String> ids) async {
    try {
      final deviceId = await getDeviceId();
      await ApiClient.instance.post(
        '/api/notifications/read/',
        data: {
          'notification_ids': ids,
          'origin_device_id': deviceId,
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> markNotificationsAsDismissed(List<String> ids) async {
    try {
      final deviceId = await getDeviceId();
      await ApiClient.instance.post(
        '/api/notifications/dismiss/',
        data: {
          'notification_ids': ids,
          'origin_device_id': deviceId,
        },
      );
    } catch (_) {}
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await ApiClient.instance.get('/api/notifications/unread-count/');
      if (response.statusCode == 200) {
        return response.data['unread_count'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
