import '../repositories/subscriptions_repository.dart';

/// Fetches products available for a specific subscription plan.
class GetSubscriptionPlanProductsUseCase {
  final SubscriptionsRepository _repository;
  GetSubscriptionPlanProductsUseCase(this._repository);

  Future<List<SubscriptionPlanProductEntity>> call(int planId) =>
      _repository.getSubscriptionPlanProducts(planId);
}
