import '../entities/payment_status.dart';
import '../repositories/payments_repository.dart';

class GetPaymentStatusUseCase {
  final PaymentsRepository _repository;

  GetPaymentStatusUseCase(this._repository);

  Future<PaymentStatus> call(String reference) {
    return _repository.fetchStatus(reference);
  }
}
