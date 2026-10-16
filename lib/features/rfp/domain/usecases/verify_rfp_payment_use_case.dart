import '../repositories/rfp_repository.dart';

/// Pure Dart use case to verify an RFP payment transaction.
class VerifyRfpPaymentUseCase {
  final RfpRepository _repository;

  VerifyRfpPaymentUseCase(this._repository);

  Future<Map<String, dynamic>> call(String merchantTransactionId) {
    return _repository.verifyPayment(merchantTransactionId);
  }
}
