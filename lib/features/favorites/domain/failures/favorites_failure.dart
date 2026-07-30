enum FavoritesFailureType {
  network,
  unauthorized,
  unknown,
}

class FavoritesFailure {
  final FavoritesFailureType type;
  final String message;

  const FavoritesFailure({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}
