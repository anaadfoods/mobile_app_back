import 'package:grocery_app/features/misc/domain/repositories/help_repository.dart';

class HelpDeactivateAccountUseCase {
  final HelpRepository _repository;

  HelpDeactivateAccountUseCase(this._repository);

  Future<Map<String, dynamic>> call(String password) {
    return _repository.deactivateAccount(password);
  }
}
