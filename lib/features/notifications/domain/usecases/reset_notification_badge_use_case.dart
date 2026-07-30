import '../repositories/notifications_repository.dart';

class ResetNotificationBadgeUseCase {
  final NotificationsRepository _repository;
  ResetNotificationBadgeUseCase(this._repository);

  Future<void> call() => _repository.resetNotificationBadgeCount();
}
