import 'package:grocery_app/features/misc/domain/entities/address_entity.dart';

abstract class AddressRepository {
  Future<bool> updateAddress(AddressEntity address);
}
