// services/location_service.dart
import 'package:grocery_app/common_widgets/global_import.dart';
import '../models/location_models.dart';

import 'package:grocery_app/service_locator.dart';

class LocationService {
  factory LocationService() => getIt<LocationService>();
  LocationService.create();
  Future<List<StateModel>> fetchStates() async {
    final resp = await ApiClient.instance.get('/api/core/states/');
    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = resp.data;
      return jsonList.map((e) => StateModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load states: ${resp.statusCode}');
    }
  }

  Future<List<CityModel>> fetchCities({required int stateId}) async {
    final resp = await ApiClient.instance.get(
      '/api/core/cities/',
      queryParameters: {'state_id': stateId},
    );
    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = resp.data;
      return jsonList.map((e) => CityModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load cities: ${resp.statusCode}');
    }
  }
}
