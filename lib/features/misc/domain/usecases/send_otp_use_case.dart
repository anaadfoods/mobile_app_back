import 'package:grocery_app/features/misc/domain/repositories/help_repository.dart';

class SendOtpUseCase {
  final HelpRepository _repository;

  SendOtpUseCase(this._repository);

  Future<Map<String, dynamic>> call({
    required String identifier,
    required String type,
  }) {
    return _repository.sendOtp(identifier: identifier, type: type);
  }
}
