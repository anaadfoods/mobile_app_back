import 'package:grocery_app/common_widgets/global_import.dart';

class CommunityService {
  static const String communitiesEndpoint = '/api/core/communities/';

  static Future<List<Community>> fetchCommunities() async {
    final response = await ApiClient.instance.get(communitiesEndpoint);
    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> list = data['data'];
      return list.map((json) => Community.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load communities');
    }
  }
}
