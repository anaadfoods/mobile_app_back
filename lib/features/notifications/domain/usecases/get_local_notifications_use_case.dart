import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class GetLocalNotificationsUseCase {
  final NotificationsRepository _repository;
  GetLocalNotificationsUseCase(this._repository);

  Future<List<NotificationEntity>> call() => _repository.getLocalNotifications();
}
