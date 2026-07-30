import 'dart:io';
import 'package:grocery_app/features/misc/domain/repositories/profile_repository.dart';

class UploadProfileImageUseCase {
  final ProfileRepository _repository;

  UploadProfileImageUseCase(this._repository);

  Future<Map<String, dynamic>> call(File imageFile) {
    return _repository.uploadProfileImage(imageFile);
  }
}
