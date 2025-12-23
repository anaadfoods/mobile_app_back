import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:http/http.dart' as http;

class CommunityService {
  static const String communitiesEndpoint = '/api/core/communities/';
  static Future<List<Community>> fetchCommunities() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}$communitiesEndpoint'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => Community.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load communities');
    }
  }
}
