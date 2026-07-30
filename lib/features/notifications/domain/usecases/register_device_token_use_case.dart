import '../repositories/notifications_repository.dart';

class RegisterDeviceTokenUseCase {
  final NotificationsRepository _repository;
  RegisterDeviceTokenUseCase(this._repository);

  Future<void> call(String fcmToken) => _repository.registerDeviceToken(fcmToken);
}
