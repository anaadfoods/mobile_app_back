import 'package:grocery_app/services/profile_service.dart';

abstract class HelpRemoteDataSource {
  Future<Map<String, dynamic>> sendOtp({
    required String identifier,
    required String type,
  });

  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otp,
    required String type,
  });

  Future<Map<String, dynamic>> deactivateAccount(String password);

  Future<Map<String, dynamic>> confirmDeactivateAccount(String otp);
}

class HelpRemoteDataSourceImpl implements HelpRemoteDataSource {
  final ProfileService _profileService;

  HelpRemoteDataSourceImpl({required ProfileService profileService})
      : _profileService = profileService;

  @override
  Future<Map<String, dynamic>> sendOtp({
    required String identifier,
    required String type,
  }) {
    return _profileService.sendOtp(identifier: identifier, type: type);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String otp,
    required String type,
  }) {
    return _profileService.verifyOtp(
      identifier: identifier,
      otp: otp,
      type: type,
    );
  }

  @override
  Future<Map<String, dynamic>> deactivateAccount(String password) {
    return _profileService.deactivateAccount(password);
  }

  @override
  Future<Map<String, dynamic>> confirmDeactivateAccount(String otp) {
    return _profileService.confirmDeactivateAccount(otp);
  }
}
