import 'package:grocery_app/features/misc/domain/repositories/account_repository.dart';

/// Syncs user profile from the backend.
class SyncUserProfileUseCase {
  final AccountRepository _repository;

  SyncUserProfileUseCase(this._repository);

  Future<Map<String, dynamic>?> call() {
    return _repository.syncUserProfile();
  }
}
