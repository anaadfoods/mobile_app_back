import '../repositories/auth_repository.dart';

class UpdateAddressUseCase {
  final AuthRepository _repository;

  UpdateAddressUseCase(this._repository);

  Future<bool> call(Map<String, String> addressDetails) {
    return _repository.updateAddress(addressDetails);
  }
}
