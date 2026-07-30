/// Domain-specific failure types for the Subscriptions feature.
/// Pure Dart — no Flutter or third-party imports.
class SubscriptionFailure implements Exception {
  final String message;
  final Map<String, dynamic>? validationErrors;

  const SubscriptionFailure(this.message, {this.validationErrors});

  factory SubscriptionFailure.server(String message, {Map<String, dynamic>? errors}) =>
      SubscriptionFailure(message, validationErrors: errors);

  factory SubscriptionFailure.network() =>
      const SubscriptionFailure('Network error. Please check your connection.');

  factory SubscriptionFailure.notFound() =>
      const SubscriptionFailure('Subscription not found.');

  factory SubscriptionFailure.unauthorized() =>
      const SubscriptionFailure('You must be logged in to manage subscriptions.');

  factory SubscriptionFailure.cancellationRejected(String reason) =>
      SubscriptionFailure('Cancellation rejected: $reason');

  factory SubscriptionFailure.pauseRejected(String reason) =>
      SubscriptionFailure('Cannot pause subscription: $reason');

  factory SubscriptionFailure.repaymentFailed(String reason) =>
      SubscriptionFailure('Repayment failed: $reason');

  @override
  String toString() => message;
}
