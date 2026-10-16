import '../repositories/rfp_repository.dart';

/// Pure Dart use case to pay the remaining balance for an RFP subscription.
class PayRemainingUseCase {
  final RfpRepository _repository;

  PayRemainingUseCase(this._repository);

  Future<Map<String, dynamic>> call(int subscriptionId) {
    return _repository.payRemaining(subscriptionId);
  }
}
