import 'package:grocery_app/features/misc/data/datasources/account_remote_data_source.dart';
import 'package:grocery_app/features/misc/domain/entities/user_summary_entity.dart';
import 'package:grocery_app/features/misc/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource _remoteDataSource;

  AccountRepositoryImpl({required AccountRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<UserSummaryEntity?> getUserSummary() async {
    final model = await _remoteDataSource.getUserSummary();
    if (model == null) return null;

    return UserSummaryEntity(
      totalOrders: model.orders.total,
      totalSpent: 0.0,
      activePlans: model.subscriptions.activeTotal,
      totalSubscriptions: model.subscriptions.activeTotal,
      cancelledOrders: model.orders.byStatus['cancelled'] ?? 0,
      totalProducts: model.favorites.count,
    );
  }

  @override
  Future<Map<String, dynamic>?> syncUserProfile() async {
    return await _remoteDataSource.getUserProfile();
  }
}
