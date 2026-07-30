import '../entities/subscription_entity.dart';
import '../repositories/subscriptions_repository.dart';

/// Fetches details for a single subscription by ID.
class GetSubscriptionDetailsUseCase {
  final SubscriptionsRepository _repository;
  GetSubscriptionDetailsUseCase(this._repository);

  Future<SubscriptionEntity> call(int subscriptionId) =>
      _repository.getSubscriptionDetails(subscriptionId);
}
