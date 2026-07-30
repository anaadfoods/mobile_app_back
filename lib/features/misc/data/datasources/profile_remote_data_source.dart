import 'dart:io';
import 'package:grocery_app/models/user_model.dart';
import 'package:grocery_app/services/profile_service.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> updateProfile(UserModel user);
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ProfileService _profileService;

  ProfileRemoteDataSourceImpl({required ProfileService profileService})
      : _profileService = profileService;

  @override
  Future<Map<String, dynamic>> updateProfile(UserModel user) {
    return _profileService.updateProfile(user);
  }

  @override
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) {
    return _profileService.uploadProfileImage(imageFile);
  }
}
