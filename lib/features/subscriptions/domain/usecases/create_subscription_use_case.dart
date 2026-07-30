import '../entities/subscription_entity.dart';
import '../repositories/subscriptions_repository.dart';

/// Creates a new subscription. The result may contain payment links
/// for online payment (Easebuzz) or the subscription object for COD.
class CreateSubscriptionUseCase {
  final SubscriptionsRepository _repository;
  CreateSubscriptionUseCase(this._repository);

  Future<SubscriptionCreateResponseEntity> call(
    Map<String, dynamic> requestData,
  ) =>
      _repository.createSubscription(requestData);
}
