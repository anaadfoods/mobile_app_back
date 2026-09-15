import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> register(User user);
  Future<User> googleLogin();
  Future<User> appleLogin();
  Future<void> logout();
  Future<User?> checkAuthStatus();
  Future<bool> verifyAndRefreshToken();
  Future<User> updateProfile(User user);
  Future<bool> updateAddress(Map<String, String> addressDetails);
  Future<User> uploadProfileImage(String imagePath);
  Future<void> sendOtp(String identifier, String type);
  Future<void> verifyOtp(String identifier, String otp, String type);
  Future<void> deactivateAccount(String password);
  Future<void> confirmDeactivateAccount(String otp);
  Stream<bool> get authStateChanges;
}
