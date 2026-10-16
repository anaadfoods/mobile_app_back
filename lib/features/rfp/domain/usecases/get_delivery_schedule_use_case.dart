import '../entities/rfp_delivery.dart';
import '../repositories/rfp_repository.dart';

class GetDeliveryScheduleUseCase {
  final RfpRepository _repository;
  GetDeliveryScheduleUseCase(this._repository);

  Future<List<RfpDelivery>> call(String bookingId) =>
      _repository.getDeliverySchedule(bookingId);
}

class GetUpcomingDeliveriesUseCase {
  final RfpRepository _repository;
  GetUpcomingDeliveriesUseCase(this._repository);

  Future<List<RfpDelivery>> call(String bookingId) =>
      _repository.getUpcomingDeliveries(bookingId);
}
