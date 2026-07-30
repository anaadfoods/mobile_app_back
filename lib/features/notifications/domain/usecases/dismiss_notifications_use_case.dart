import '../repositories/notifications_repository.dart';

class DismissNotificationsUseCase {
  final NotificationsRepository _repository;
  DismissNotificationsUseCase(this._repository);

  Future<void> call(List<String> ids) => _repository.dismiss(ids);
}
