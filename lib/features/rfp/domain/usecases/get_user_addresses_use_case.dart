import '../entities/user_address.dart';
import '../repositories/rfp_repository.dart';

/// Pure Dart use case to fetch a user's saved delivery addresses.
class GetUserAddressesUseCase {
  final RfpRepository _repository;

  GetUserAddressesUseCase(this._repository);

  Future<List<UserAddress>> call() => _repository.getUserAddresses();
}
