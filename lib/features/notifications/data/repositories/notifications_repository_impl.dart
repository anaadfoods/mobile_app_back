import 'package:grocery_app/models/notification_model.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/failures/notification_failure.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_local_data_source.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;
  final NotificationsLocalDataSource _localDataSource;

  NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remoteDataSource,
    required NotificationsLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<List<NotificationEntity>> getLocalNotifications() async {
    final models = await _localDataSource.getLocalNotifications();
    return models
        .where((m) => !m.isDismissed)
        .map((m) => _toEntity(m))
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final models = await _localDataSource.getLocalNotifications();
    return models.where((m) => !m.isRead && !m.isDismissed).length;
  }

  @override
  Future<List<NotificationEntity>> syncWithBackend(int sinceVersion) async {
    try {
      final currentVersion = await _localDataSource.getSyncVersion();
      final syncResult = await _remoteDataSource.syncNotifications(currentVersion);
      final List<NotificationModel> serverNotifs = syncResult['notifications'] ?? [];
      final int latestVersion = syncResult['latest_version'] ?? currentVersion;

      final localNotifs = await _localDataSource.getLocalNotifications();
      final localMap = {for (var n in localNotifs) n.id: n};

      for (var serverNotif in serverNotifs) {
        localMap[serverNotif.id] = serverNotif;
      }

      final updatedList = localMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      await _localDataSource.saveLocalNotifications(updatedList);
      await _localDataSource.saveSyncVersion(latestVersion);

      return updatedList
          .where((m) => !m.isDismissed)
          .map((m) => _toEntity(m))
          .toList();
    } on NotificationFailure {
      return getLocalNotifications();
    } catch (_) {
      return getLocalNotifications();
    }
  }

  @override
  Future<void> markAsRead(List<String> ids) async {
    final local = await _localDataSource.getLocalNotifications();
    final updated = local.map((n) {
      if (ids.contains(n.id)) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    await _localDataSource.saveLocalNotifications(updated);
    await _remoteDataSource.markNotificationsAsRead(ids);
  }

  @override
  Future<void> dismiss(List<String> ids) async {
    final local = await _localDataSource.getLocalNotifications();
    final updated = local.map((n) {
      if (ids.contains(n.id)) {
        return n.copyWith(isDismissed: true, isRead: true);
      }
      return n;
    }).toList();

    await _localDataSource.saveLocalNotifications(updated);
    await _remoteDataSource.markNotificationsAsDismissed(ids);
  }

  @override
  Future<void> registerDeviceToken(String fcmToken) async {
    await _localDataSource.saveFCMToken(fcmToken);
    await _remoteDataSource.registerDeviceToken(fcmToken);
  }

  @override
  Future<void> unregisterDeviceToken() async {
    final token = await _localDataSource.getStoredFCMToken();
    if (token != null) {
      await _remoteDataSource.unregisterDeviceToken(token);
    }
    await _localDataSource.clearStoredFCMToken();
  }

  @override
  Future<void> resetNotificationBadgeCount() async {
    await _localDataSource.resetNotificationBadgeCount();
  }

  NotificationEntity _toEntity(NotificationModel model) {
    return NotificationEntity(
      id: model.id,
      title: model.title,
      body: model.body,
      type: model.type,
      action: model.action,
      source: model.source,
      originDeviceId: model.originDeviceId,
      isRead: model.isRead,
      isDismissed: model.isDismissed,
      syncVersion: model.syncVersion,
      timestamp: model.timestamp,
      image: model.image,
      priority: model.priority,
      metadata: model.metadata,
    );
  }
}
