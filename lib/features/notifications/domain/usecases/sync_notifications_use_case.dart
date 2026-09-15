import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class SyncNotificationsUseCase {
  final NotificationsRepository _repository;
  SyncNotificationsUseCase(this._repository);

  Future<List<NotificationEntity>> call(int sinceVersion) =>
      _repository.syncWithBackend(sinceVersion);
}
