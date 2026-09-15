import 'package:grocery_app/features/misc/domain/repositories/help_repository.dart';

class VerifyOtpUseCase {
  final HelpRepository _repository;

  VerifyOtpUseCase(this._repository);

  Future<Map<String, dynamic>> call({
    required String identifier,
    required String otp,
    required String type,
  }) {
    return _repository.verifyOtp(identifier: identifier, otp: otp, type: type);
  }
}
