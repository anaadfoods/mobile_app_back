import '../entities/subscription_entity.dart';
import '../repositories/subscriptions_repository.dart';

/// Fetches all subscriptions for the logged-in user, filtering out
/// unpaid/pending UPI subscriptions (matching Orders pattern).
class GetUserSubscriptionsUseCase {
  final SubscriptionsRepository _repository;
  GetUserSubscriptionsUseCase(this._repository);

  Future<List<SubscriptionEntity>> call() async {
    final subscriptions = await _repository.getUserSubscriptions();
    // Filter out UPI subscriptions that have failed or are still pending payment
    return subscriptions.where((sub) {
      if (sub.paymentMethod.toUpperCase() == 'UPI') {
        final status = sub.paymentStatus.toUpperCase();
        if (status == 'PAYMENT_PENDING' || status == 'PENDING' || status == 'FAILED') {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
