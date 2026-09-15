import 'package:grocery_app/features/misc/domain/repositories/help_repository.dart';

class HelpConfirmDeactivationUseCase {
  final HelpRepository _repository;

  HelpConfirmDeactivationUseCase(this._repository);

  Future<Map<String, dynamic>> call(String otp) {
    return _repository.confirmDeactivateAccount(otp);
  }
}
