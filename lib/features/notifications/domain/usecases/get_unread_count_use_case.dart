import '../repositories/notifications_repository.dart';

class GetUnreadCountUseCase {
  final NotificationsRepository _repository;
  GetUnreadCountUseCase(this._repository);

  Future<int> call() => _repository.getUnreadCount();
}
