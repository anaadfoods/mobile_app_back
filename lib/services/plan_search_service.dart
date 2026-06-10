import 'package:grocery_app/common_widgets/global_import.dart';

class PlanSearchService {
  static Future<List<PlanSearchResult>> fetchPlansForVariant(
    int variantId,
  ) async {
    final response = await ApiClient.instance.get(
      '/api/subscriptions/plans/search/',
      queryParameters: {'variant_id': variantId},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => PlanSearchResult.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load plans');
    }
  }
}
