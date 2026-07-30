import '../repositories/auth_repository.dart';

class VerifyTokenUseCase {
  final AuthRepository _repository;

  VerifyTokenUseCase(this._repository);

  Future<bool> call() {
    return _repository.verifyAndRefreshToken();
  }
}
