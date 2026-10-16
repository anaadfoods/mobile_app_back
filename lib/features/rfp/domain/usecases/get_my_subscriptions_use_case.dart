import '../entities/rfp_booking.dart';
import '../repositories/rfp_repository.dart';

/// Use case to fetch all of the current user's RFP subscriptions.
class GetMySubscriptionsUseCase {
  final RfpRepository _repository;
  GetMySubscriptionsUseCase(this._repository);

  Future<List<RfpBooking>> call() => _repository.getMySubscriptions();
}
