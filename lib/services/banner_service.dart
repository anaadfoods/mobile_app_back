import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:grocery_app/service_locator.dart';

class BannerService {
  factory BannerService() => getIt<BannerService>();
  BannerService.create();

  static const String bannersEndpoint = '/api/core/banners/';

  Future<List<BannerModel>> fetchBanners() async {
    try {
      final response = await ApiClient.instance.get(bannersEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => BannerModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      throw Exception('Error loading banners: $e');
    }
  }
}
