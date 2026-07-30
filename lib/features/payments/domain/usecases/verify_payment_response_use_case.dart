import '../repositories/payments_repository.dart';

class VerifyPaymentResponseUseCase {
  final PaymentsRepository _repository;

  VerifyPaymentResponseUseCase(this._repository);

  Future<void> call(String orderId) {
    return _repository.verifyPaymentResponse(orderId);
  }
}
