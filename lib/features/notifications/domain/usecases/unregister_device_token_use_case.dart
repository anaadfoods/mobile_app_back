import '../repositories/notifications_repository.dart';

class UnregisterDeviceTokenUseCase {
  final NotificationsRepository _repository;
  UnregisterDeviceTokenUseCase(this._repository);

  Future<void> call() => _repository.unregisterDeviceToken();
}
