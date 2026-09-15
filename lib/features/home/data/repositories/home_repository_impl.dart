import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/community_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  const HomeRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<BannerEntity>> getBanners() async {
    return await _remoteDataSource.fetchBanners();
  }

  @override
  Future<List<CommunityEntity>> getCommunities() async {
    return await _remoteDataSource.fetchCommunities();
  }
}
