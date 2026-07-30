enum AuthFailureType {
  invalidCredentials,   // wrong email/password
  cancelled,            // user cancelled OAuth flow (Google/Apple)
  networkError,         // socket, timeout, failed host lookup
  unauthorized,         // not logged in, token expired
  serverError,          // 500s, unexpected response format
  unknown,              // catch-all
}

class AuthFailure implements Exception {
  final AuthFailureType type;
  final String message;

  const AuthFailure({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'AuthFailure(type: $type, message: $message)';
}
