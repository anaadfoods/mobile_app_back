/// Failure types for the Notifications feature. Pure Dart.
class NotificationFailure implements Exception {
  final String message;
  final String? code;

  const NotificationFailure(this.message, {this.code});

  factory NotificationFailure.server([String message = 'Server error occurred.']) {
    return NotificationFailure(message, code: 'SERVER_ERROR');
  }

  factory NotificationFailure.network([String message = 'Network connection failed.']) {
    return NotificationFailure(message, code: 'NETWORK_ERROR');
  }

  factory NotificationFailure.device([String message = 'Device registration failed.']) {
    return NotificationFailure(message, code: 'DEVICE_ERROR');
  }

  @override
  String toString() => message;
}
