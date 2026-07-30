import 'package:grocery_app/features/misc/domain/entities/address_entity.dart';
import 'package:grocery_app/features/misc/domain/repositories/address_repository.dart';

class SaveAddressUseCase {
  final AddressRepository _repository;

  SaveAddressUseCase(this._repository);

  Future<bool> call(AddressEntity address) {
    return _repository.updateAddress(address);
  }
}
