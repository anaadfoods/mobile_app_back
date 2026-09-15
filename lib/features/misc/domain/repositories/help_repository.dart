/// Abstract repository interface for Help feature operations (e.g. account deactivation, support OTP).
abstract class HelpRepository {
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
