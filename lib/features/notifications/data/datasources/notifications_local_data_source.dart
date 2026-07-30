import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grocery_app/models/notification_model.dart';

abstract class NotificationsLocalDataSource {
  Future<List<NotificationModel>> getLocalNotifications();
  Future<void> saveLocalNotifications(List<NotificationModel> notifications);
  Future<void> saveServerPushNotification(Map<String, dynamic> payload);
  Future<int> getSyncVersion();
  Future<void> saveSyncVersion(int version);
  Future<String?> getStoredFCMToken();
  Future<void> saveFCMToken(String token);
  Future<void> clearStoredFCMToken();
  Future<void> resetNotificationBadgeCount();
}

class NotificationsLocalDataSourceImpl implements NotificationsLocalDataSource {
  static const String _keyLocalNotifications = 'cached_notifications';
  static const String _keySyncVersion = 'notification_sync_version';
  static const String _keyFcmToken = 'fcm_token';
  static const String _keyUnreadCount = 'notification_count';

  @override
  Future<List<NotificationModel>> getLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyLocalNotifications);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> raw = jsonDecode(jsonStr);
      return raw.map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveLocalNotifications(List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_keyLocalNotifications, jsonStr);
  }

  @override
  Future<void> saveServerPushNotification(Map<String, dynamic> payload) async {
    final current = await getLocalNotifications();
    final notif = NotificationModel.fromJson(payload);
    
    // Check duplicate ID
    final existingIndex = current.indexWhere((n) => n.id == notif.id);
    if (existingIndex >= 0) {
      current[existingIndex] = notif;
    } else {
      current.insert(0, notif);
    }
    await saveLocalNotifications(current);
  }

  @override
  Future<int> getSyncVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySyncVersion) ?? 0;
  }

  @override
  Future<void> saveSyncVersion(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySyncVersion, version);
  }

  @override
  Future<String?> getStoredFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken);
  }

  @override
  Future<void> saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, token);
  }

  @override
  Future<void> clearStoredFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFcmToken);
  }

  @override
  Future<void> resetNotificationBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUnreadCount, 0);
  }
}
