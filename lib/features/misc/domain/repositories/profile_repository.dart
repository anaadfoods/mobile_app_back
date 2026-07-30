import 'dart:io';
import 'package:grocery_app/models/user_model.dart';

/// Abstract repository interface for User Profile management.
/// Consumers: AuthCubit
abstract class ProfileRepository {
  Future<Map<String, dynamic>> updateProfile(UserModel user);
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile);
}
