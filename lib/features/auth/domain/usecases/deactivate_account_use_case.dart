import '../repositories/auth_repository.dart';

class DeactivateAccountUseCase {
  final AuthRepository _repository;

  DeactivateAccountUseCase(this._repository);

  Future<void> call(String password) {
    return _repository.deactivateAccount(password);
  }
}
