import 'dart:convert';
import 'package:grocery_app/models/plan_Search_model.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class PlanSearchService {
  static Future<List<PlanSearchResult>> fetchPlansForVariant(
    int variantId,
  ) async {
    final url =
        '${ApiConfig.baseUrl}/api/subscriptions/plans/search/?variant_id=$variantId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PlanSearchResult.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load plans');
    }
  }
}
