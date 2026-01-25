/// Types of API errors for categorization
enum ApiErrorType {
  network,
  server,
  auth,
  validation,
  notFound,
  timeout,
  unknown,
}

/// Enhanced API exception class with user-friendly message support.
///
/// Usage:
/// ```dart
/// throw ApiException('Invalid credentials', 401);
/// // or
/// throw ApiException.fromStatusCode(response.statusCode, response.body);
/// ```
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorType errorType;
  final Map<String, dynamic>? errors;

  ApiException(
    this.message, [
    this.statusCode,
    this.errorType = ApiErrorType.unknown,
    this.errors,
  ]);

  /// Factory constructor to create ApiException from HTTP status code
  factory ApiException.fromStatusCode(int statusCode, [String? serverMessage]) {
    final type = _getErrorType(statusCode);
    final message = serverMessage ?? _getDefaultMessage(statusCode);
    return ApiException(message, statusCode, type);
  }

  /// Factory constructor for network errors
  factory ApiException.network([String? message]) {
    return ApiException(
      message ?? 'Unable to connect to the server',
      null,
      ApiErrorType.network,
    );
  }

  /// Factory constructor for timeout errors
  factory ApiException.timeout([String? message]) {
    return ApiException(
      message ?? 'Request timed out',
      408,
      ApiErrorType.timeout,
    );
  }

  /// Get user-friendly message based on status code
  String get userFriendlyMessage {
    if (statusCode == null) {
      if (errorType == ApiErrorType.network) {
        return 'Unable to connect. Please check your internet connection.';
      }
      if (errorType == ApiErrorType.timeout) {
        return 'Request timed out. Please try again.';
      }
      return 'Something went wrong. Please try again.';
    }
    return _getDefaultMessage(statusCode!);
  }

  /// Check if this is a recoverable error (can retry)
  bool get isRecoverable {
    if (errorType == ApiErrorType.network ||
        errorType == ApiErrorType.timeout) {
      return true;
    }
    if (statusCode != null && statusCode! >= 500) {
      return true;
    }
    return false;
  }

  /// Check if this requires re-authentication
  bool get requiresAuth => statusCode == 401 || statusCode == 403;

  static ApiErrorType _getErrorType(int statusCode) {
    if (statusCode == 401 || statusCode == 403) return ApiErrorType.auth;
    if (statusCode == 404) return ApiErrorType.notFound;
    if (statusCode == 408) return ApiErrorType.timeout;
    if (statusCode >= 400 && statusCode < 500) return ApiErrorType.validation;
    if (statusCode >= 500) return ApiErrorType.server;
    return ApiErrorType.unknown;
  }

  static String _getDefaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your information.';
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'The requested item could not be found.';
      case 408:
        return 'Request timed out. Please try again.';
      case 422:
        return 'The provided data is invalid.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
        return 'We\'re experiencing technical difficulties. Please try again later.';
      case 502:
        return 'Our servers are temporarily unavailable.';
      case 503:
        return 'Service temporarily unavailable. We\'re working on it!';
      case 504:
        return 'Server took too long to respond.';
      default:
        if (statusCode >= 500) return 'Server error. Please try again later.';
        if (statusCode >= 400) return 'Request failed. Please try again.';
        return 'Something went wrong.';
    }
  }

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $statusCode - $message';
    }
    return 'ApiException: $message';
  }
}
