import 'dart:io';
import 'package:grocery_app/features/misc/data/datasources/profile_remote_data_source.dart';
import 'package:grocery_app/features/misc/domain/repositories/profile_repository.dart';
import 'package:grocery_app/models/user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Map<String, dynamic>> updateProfile(UserModel user) {
    return _remoteDataSource.updateProfile(user);
  }

  @override
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) {
    return _remoteDataSource.uploadProfileImage(imageFile);
  }
}
