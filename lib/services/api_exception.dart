// You can place this in a file like 'lib/services/api_exception.dart'
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $statusCode - $message';
    }
    return 'ApiException: $message';
  }
}