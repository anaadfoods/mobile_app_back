import '../entities/rfp_delivery_otp_status.dart';
import '../repositories/rfp_repository.dart';

class GetDeliveryOtpStatusUseCase {
  final RfpRepository _repository;

  GetDeliveryOtpStatusUseCase(this._repository);

  Future<RfpDeliveryOtpStatus> call(String deliveryId) =>
      _repository.getDeliveryOtpStatus(deliveryId);
}
