import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class AppleLoginUseCase {
  final AuthRepository _repository;

  AppleLoginUseCase(this._repository);

  Future<User> call() {
    return _repository.appleLogin();
  }
}
