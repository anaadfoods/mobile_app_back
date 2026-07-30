import '../entities/banner_entity.dart';
import '../entities/community_entity.dart';

abstract class HomeRepository {
  Future<List<BannerEntity>> getBanners();
  Future<List<CommunityEntity>> getCommunities();
}
