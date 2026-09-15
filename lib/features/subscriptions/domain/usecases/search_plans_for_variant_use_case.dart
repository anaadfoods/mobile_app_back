import '../repositories/subscriptions_repository.dart';

/// Searches for subscription plans that contain a specific product variant.
class SearchPlansForVariantUseCase {
  final SubscriptionsRepository _repository;
  SearchPlansForVariantUseCase(this._repository);

  Future<List<PlanSearchResultEntity>> call(int variantId) =>
      _repository.searchPlansForVariant(variantId);
}
