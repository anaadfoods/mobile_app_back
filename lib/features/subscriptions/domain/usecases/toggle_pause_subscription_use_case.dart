import '../entities/subscription_entity.dart';
import '../repositories/subscriptions_repository.dart';

/// Toggles pause/resume on a subscription with optional date range.
class TogglePauseSubscriptionUseCase {
  final SubscriptionsRepository _repository;
  TogglePauseSubscriptionUseCase(this._repository);

  Future<PauseResponseEntity> call(
    int subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  ) =>
      _repository.togglePauseSubscription(subscriptionId, startDate, endDate);
}
