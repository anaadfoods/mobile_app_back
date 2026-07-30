import '../repositories/subscriptions_repository.dart';

/// Fetches invoices for a specific subscription.
class GetSubscriptionInvoicesUseCase {
  final SubscriptionsRepository _repository;
  GetSubscriptionInvoicesUseCase(this._repository);

  Future<SubscriptionInvoiceResponse> call(int subscriptionId) =>
      _repository.getSubscriptionInvoices(subscriptionId);
}
