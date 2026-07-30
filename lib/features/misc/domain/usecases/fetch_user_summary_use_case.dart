import 'package:grocery_app/features/misc/domain/entities/user_summary_entity.dart';
import 'package:grocery_app/features/misc/domain/repositories/account_repository.dart';

/// Fetches user summary statistics from the backend.
class FetchUserSummaryUseCase {
  final AccountRepository _repository;

  FetchUserSummaryUseCase(this._repository);

  Future<UserSummaryEntity?> call() {
    return _repository.getUserSummary();
  }
}
