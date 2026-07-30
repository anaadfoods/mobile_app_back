enum PaymentFailureType {
  gatewayError,
  networkError,
  sslPinningError,
  paymentCancelled,
  unknown,
}

class PaymentFailure implements Exception {
  final PaymentFailureType type;
  final String message;

  const PaymentFailure({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'PaymentFailure(type: $type, message: $message)';
}
