import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();

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
      print('=== FCM TOKEN ===');
      print(token);
      print('=================');
    } else {
      print('Failed to get FCM token');
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
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Check for promotional type
      if (notification['type'] == 'promotional') {
        List<Map<String, dynamic>> promotionalNotifications = [];
        String? promoJson = prefs.getString('promotional_notifications');

        if (promoJson != null) {
          List<dynamic> list = json.decode(promoJson);
          promotionalNotifications = list.cast<Map<String, dynamic>>();
        }

        promotionalNotifications.insert(0, notification);
        await prefs.setString(
          'promotional_notifications',
          json.encode(promotionalNotifications),
        );
        debugPrint('Promotional notification saved successfully');
        return;
      }

      // Handle normal notifications
      List<Map<String, dynamic>> notifications = [];
      String? notificationsJson = prefs.getString('notifications');

      if (notificationsJson != null) {
        List<dynamic> notificationsList = json.decode(notificationsJson);
        notifications = notificationsList.cast<Map<String, dynamic>>();
      }

      // Add new notification to the beginning
      notifications.insert(0, notification);

      // Save updated list
      await prefs.setString('notifications', json.encode(notifications));

      // Update badge count if needed (optional)
      int currentCount = prefs.getInt('notification_count') ?? 0;
      await prefs.setInt('notification_count', currentCount + 1);

      debugPrint('Notification saved successfully');
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }
}
