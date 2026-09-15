import '../entities/payment_status.dart';

abstract class PaymentsRepository {
  Future<PaymentStatus> fetchStatus(String reference);
  Future<PaymentStatus> pollStatus(String reference);
  Future<void> verifyPaymentResponse(String orderId);
}
