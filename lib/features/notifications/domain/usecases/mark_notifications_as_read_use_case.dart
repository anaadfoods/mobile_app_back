import '../repositories/notifications_repository.dart';

class MarkNotificationsAsReadUseCase {
  final NotificationsRepository _repository;
  MarkNotificationsAsReadUseCase(this._repository);

  Future<void> call(List<String> ids) => _repository.markAsRead(ids);
}
