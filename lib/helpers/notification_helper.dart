import 'package:flutter/material.dart';
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
}
