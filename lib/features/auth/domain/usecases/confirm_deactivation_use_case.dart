import '../repositories/auth_repository.dart';

class ConfirmDeactivationUseCase {
  final AuthRepository _repository;

  ConfirmDeactivationUseCase(this._repository);

  Future<void> call(String otp) {
    return _repository.confirmDeactivateAccount(otp);
  }
}
