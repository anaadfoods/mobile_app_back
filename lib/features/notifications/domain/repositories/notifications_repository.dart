import '../entities/notification_entity.dart';

/// Abstract repository interface for Notifications.
/// Pure Dart — no Flutter or Dio dependencies.
abstract class NotificationsRepository {
  /// Fetch all cached local notifications.
  Future<List<NotificationEntity>> getLocalNotifications();

  /// Fetch total unread notifications count.
  Future<int> getUnreadCount();

  /// Perform incremental backend synchronization.
  Future<List<NotificationEntity>> syncWithBackend(int sinceVersion);

  /// Mark specific notification IDs as read.
  Future<void> markAsRead(List<String> ids);

  /// Dismiss/remove specific notification IDs.
  Future<void> dismiss(List<String> ids);

  /// Register FCM device token with backend.
  Future<void> registerDeviceToken(String fcmToken);

  /// Unregister FCM device token on logout.
  Future<void> unregisterDeviceToken();

  /// Reset notification badge count to 0.
  Future<void> resetNotificationBadgeCount();
}
