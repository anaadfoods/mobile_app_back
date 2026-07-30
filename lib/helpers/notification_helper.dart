import 'package:grocery_app/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:grocery_app/features/notifications/data/datasources/notifications_local_data_source.dart';
import 'package:grocery_app/service_locator.dart';

class NotificationHelper {
  static late final NotificationService _notificationService =
      getIt<NotificationService>();

  /// Initialize notification helper
  static Future<void> initialize() async {
    // This can be used for any initialization if needed
  }

  /// Get FCM token and print it to console
  static Future<String?> getFCMToken() async {
    return await _notificationService.getFreshFCMToken();
  }

  /// Get stored FCM token (without fetching fresh one)
  static Future<String?> getStoredFCMToken() async {
    return await _notificationService.getFCMToken();
  }

  /// Print FCM token to console (useful for debugging)
  static Future<void> printFCMToken() async {
    String? token = await getFCMToken();
    if (token != null) {
      AppLogger.instance.log('=== FCM TOKEN ===');
      AppLogger.instance.log(token);
      AppLogger.instance.log('=================');
    } else {
      AppLogger.instance.log('Failed to get FCM token');
    }
  }

  /// Show local notification
  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    await _notificationService.showLocalNotification(
      title: title,
      body: body,
      id: id,
      payload: payload,
    );
  }

  /// Save notification to local storage
  static Future<void> saveNotification(
    Map<String, dynamic> notification,
  ) async {
    try {
      // Keep promotional notifications saved separately in SharedPreferences as required by UI
      if (notification['type'] == 'promotional') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> promotionalNotifications = [];
        String? promoJson = prefs.getString('promotional_notifications');

        if (promoJson != null) {
          try {
            List<dynamic> list = json.decode(promoJson);
            promotionalNotifications = list.cast<Map<String, dynamic>>();
          } catch (_) {}
        }

        promotionalNotifications.insert(0, notification);
        await prefs.setString(
          'promotional_notifications',
          json.encode(promotionalNotifications),
        );
        debugPrint('Promotional notification saved successfully');
        return;
      }

      await getIt<NotificationsLocalDataSource>().saveServerPushNotification(notification);
      debugPrint('Notification saved successfully via NotificationsLocalDataSource');
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }
}
