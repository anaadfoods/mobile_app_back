import 'package:grocery_app/features/misc/domain/entities/address_entity.dart';
import 'package:grocery_app/services/profile_service.dart';

abstract class AddressRemoteDataSource {
  Future<bool> updateAddress(AddressEntity address);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final ProfileService _profileService;

  AddressRemoteDataSourceImpl({required ProfileService profileService})
      : _profileService = profileService;

  @override
  Future<bool> updateAddress(AddressEntity address) {
    return _profileService.updateUserAddress({
      'name': address.name,
      'address': address.address,
      'city': address.city,
      'state': address.state,
      'pincode': address.pincode,
      'phone': address.phone,
    });
  }
}
