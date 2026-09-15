import '../entities/subscription_entity.dart';
import '../repositories/subscriptions_repository.dart';

/// Initiates repayment for an unpaid subscription.
/// Returns a RepaymentResponseEntity which may contain payment links
/// for online payment flow.
class RepaymentSubscriptionUseCase {
  final SubscriptionsRepository _repository;
  RepaymentSubscriptionUseCase(this._repository);

  Future<RepaymentResponseEntity> call(int subscriptionId) =>
      _repository.repaymentSubscription(subscriptionId);
}
