enum CartFailureType {
  network,
  unauthorized,
  validation,
  unknown,
}

class CartFailure implements Exception {
  final CartFailureType type;
  final String message;

  const CartFailure({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'CartFailure(type: $type, message: $message)';
}
