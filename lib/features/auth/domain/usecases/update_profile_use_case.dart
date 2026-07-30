import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<User> call({required User user, String? imagePath}) async {
    if (imagePath != null) {
      final userWithUploadedImage = await _repository.uploadProfileImage(imagePath);
      // Combine updated fields with uploaded image URL
      final mergedUser = user.copyWith(profilePicture: userWithUploadedImage.profilePicture);
      return _repository.updateProfile(mergedUser);
    }
    return _repository.updateProfile(user);
  }
}
