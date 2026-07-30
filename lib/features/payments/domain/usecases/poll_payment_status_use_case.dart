import '../entities/payment_status.dart';
import '../repositories/payments_repository.dart';

class PollPaymentStatusUseCase {
  final PaymentsRepository _repository;

  PollPaymentStatusUseCase(this._repository);

  Future<PaymentStatus> call(String reference) {
    return _repository.pollStatus(reference);
  }
}
