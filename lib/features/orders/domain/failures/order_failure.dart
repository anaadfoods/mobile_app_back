enum OrderFailureType {
  network,
  unauthorized,
  notFound,
  cancellationRejected,
  unknown,
}

class OrderFailure implements Exception {
  final OrderFailureType type;
  final String message;

  const OrderFailure({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}
