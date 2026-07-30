import 'package:grocery_app/features/misc/domain/entities/user_summary_entity.dart';

/// Abstract repository interface for Account-related operations.
///
/// Consumers: AccountCubit
/// Dependencies: AuthCubit (reads auth state), ThemeCubit (reads theme preferences)
///
/// Implementation lives in data layer. Domain layer stays pure Dart.
abstract class AccountRepository {
  /// Fetches the user summary stats (total orders, total spent, etc.)
  Future<UserSummaryEntity?> getUserSummary();

  /// Syncs the user profile from the backend, returning updated user data as a Map.
  /// Returns null on failure.
  Future<Map<String, dynamic>?> syncUserProfile();
}
