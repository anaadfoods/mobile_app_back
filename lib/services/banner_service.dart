import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;
import 'package:grocery_app/models/banner_model.dart';

class BannerService {
  static const String bannersEndpoint = '/api/core/banners';

  Future<List<BannerModel>> fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$bannersEndpoint'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => BannerModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load banners');
      }
    } catch (e) {
      throw Exception('Error loading banners: $e');
    }
  }
}
