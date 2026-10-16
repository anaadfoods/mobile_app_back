import '../entities/user_address.dart';
import '../repositories/rfp_repository.dart';

/// Pure Dart use case to save a new delivery address for the user.
class SaveUserAddressUseCase {
  final RfpRepository _repository;

  SaveUserAddressUseCase(this._repository);

  Future<UserAddress> call(UserAddress address) =>
      _repository.saveUserAddress(address);
}
