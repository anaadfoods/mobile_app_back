import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/community_entity.dart';

abstract class HomeRemoteDataSource {
  Future<List<BannerEntity>> fetchBanners();
  Future<List<CommunityEntity>> fetchCommunities();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient _apiClient;

  static const String bannersEndpoint = '/api/core/banners/';
  static const String communitiesEndpoint = '/api/core/communities/';

  HomeRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<List<BannerEntity>> fetchBanners() async {
    final response = await _apiClient.get(bannersEndpoint);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) {
        return BannerEntity(
          id: json['id'],
          title: json['title'] ?? '',
          subtitle: json['subtitle'] ?? '',
          image: json['image'] ?? '',
          link: json['link'],
          isActive: json['is_active'] ?? false,
          startDate: json['start_date'] ?? '',
          endDate: json['end_date'] ?? '',
          priority: json['priority'] ?? 0,
        );
      }).toList();
    } else {
      throw Exception('Failed to load banners');
    }
  }

  @override
  Future<List<CommunityEntity>> fetchCommunities() async {
    final response = await _apiClient.get(communitiesEndpoint);
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> list = data['data'];
      return list.map((json) {
        final image = json['image'] ?? '';
        String fullUrl = '';
        if (image.isNotEmpty) {
          if (image.startsWith('http://') || image.startsWith('https://')) {
            fullUrl = image;
          } else {
            final cleanPath = image.startsWith('/') ? image : '/$image';
            fullUrl = '${ApiConfig.baseUrl}$cleanPath';
          }
        }

        return CommunityEntity(
          id: json['id'],
          name: json['name'] ?? '',
          description: json['description'] ?? '',
          image: image,
          benefits: json['benefits'] ?? '',
          comingSoon: json['coming_soon'] ?? false,
          launchDate: json['launch_date'],
          fullImageUrl: fullUrl,
        );
      }).toList();
    } else {
      throw Exception('Failed to load communities');
    }
  }
}
