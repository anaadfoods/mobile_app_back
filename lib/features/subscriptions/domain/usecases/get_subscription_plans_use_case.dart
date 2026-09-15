import '../entities/subscription_plan_entity.dart';
import '../repositories/subscriptions_repository.dart';

/// Fetches all available subscription plans.
class GetSubscriptionPlansUseCase {
  final SubscriptionsRepository _repository;
  GetSubscriptionPlansUseCase(this._repository);

  Future<List<SubscriptionPlanEntity>> call() =>
      _repository.getSubscriptionPlans();
}
