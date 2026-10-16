import '../entities/rfp_booking.dart';
import '../entities/rfp_patch_config.dart';
import '../repositories/rfp_repository.dart';

class CreateBookingUseCase {
  final RfpRepository _repository;
  CreateBookingUseCase(this._repository);

  Future<RfpBooking> call({
    required String batchId,
    required String planId,
    required String locationId,
    required List<RfpPatchConfig> patchConfigs,
    required String paymentMethod,
    required String fullName,
    required String addressLine,
    required String city,
    required String pincode,
    required String phone,
    String paymentType = 'booking',
    int? addressId,
  }) => _repository.createBooking(
    batchId: batchId,
    planId: planId,
    locationId: locationId,
    patchConfigs: patchConfigs,
    paymentMethod: paymentMethod,
    fullName: fullName,
    addressLine: addressLine,
    city: city,
    pincode: pincode,
    phone: phone,
    paymentType: paymentType,
    addressId: addressId,
  );
}
