import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GoogleLoginUseCase {
  final AuthRepository _repository;

  GoogleLoginUseCase(this._repository);

  Future<User> call() {
    return _repository.googleLogin();
  }
}
