import '../repositories/subscriptions_repository.dart';

/// Cancels a subscription, optionally with a reason.
class CancelSubscriptionUseCase {
  final SubscriptionsRepository _repository;
  CancelSubscriptionUseCase(this._repository);

  Future<Map<String, dynamic>> call(int subscriptionId, {String? reason}) =>
      _repository.cancelSubscription(subscriptionId, reason: reason);
}
