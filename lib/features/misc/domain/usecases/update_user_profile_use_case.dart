import 'package:grocery_app/features/misc/domain/repositories/profile_repository.dart';
import 'package:grocery_app/models/user_model.dart';

class UpdateUserProfileUseCase {
  final ProfileRepository _repository;

  UpdateUserProfileUseCase(this._repository);

  Future<Map<String, dynamic>> call(UserModel user) {
    return _repository.updateProfile(user);
  }
}
