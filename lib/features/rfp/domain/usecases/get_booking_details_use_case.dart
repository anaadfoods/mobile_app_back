import '../entities/rfp_booking.dart';
import '../repositories/rfp_repository.dart';

class GetBookingDetailsUseCase {
  final RfpRepository _repository;
  GetBookingDetailsUseCase(this._repository);

  Future<RfpBooking> call(String bookingId) =>
      _repository.getBookingDetails(bookingId);
}

class GetActiveBookingUseCase {
  final RfpRepository _repository;
  GetActiveBookingUseCase(this._repository);

  Future<RfpBooking?> call() => _repository.getActiveBooking();
}
