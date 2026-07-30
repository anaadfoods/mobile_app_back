import 'package:grocery_app/features/misc/data/datasources/help_remote_data_source.dart';
import 'package:grocery_app/features/misc/domain/repositories/help_repository.dart';

class HelpRepositoryImpl implements HelpRepository {
  final HelpRemoteDataSource _remoteDataSource;

  HelpRepositoryImpl({required HelpRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Map<String, dynamic>> sendOtp({
    required String identifier,
    required String type,
  }) {
    return _remoteDataSource.sendOtp(identifier: identifier, type: type);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otp,
    required String type,
  }) {
    return _remoteDataSource.verifyOtp(
      identifier: identifier,
      otp: otp,
      type: type,
    );
  }

  @override
  Future<Map<String, dynamic>> deactivateAccount(String password) {
    return _remoteDataSource.deactivateAccount(password);
  }

  @override
  Future<Map<String, dynamic>> confirmDeactivateAccount(String otp) {
    return _remoteDataSource.confirmDeactivateAccount(otp);
  }
}
