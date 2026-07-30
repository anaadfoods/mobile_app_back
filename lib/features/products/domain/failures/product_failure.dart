enum ProductFailureType {
  network,
  notFound,
  unknown,
}

class ProductFailure {
  final ProductFailureType type;
  final String message;

  const ProductFailure({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}
