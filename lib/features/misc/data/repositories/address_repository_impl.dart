import 'package:grocery_app/features/misc/data/datasources/address_remote_data_source.dart';
import 'package:grocery_app/features/misc/domain/entities/address_entity.dart';
import 'package:grocery_app/features/misc/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource _remoteDataSource;

  AddressRepositoryImpl({required AddressRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<bool> updateAddress(AddressEntity address) {
    return _remoteDataSource.updateAddress(address);
  }
}
