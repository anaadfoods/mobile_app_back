// services/location_service.dart
import 'dart:convert';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:http/http.dart' as http;
import '../models/location_models.dart';

class LocationService {
  // Change baseUrl if needed (mobile emulator note: use 10.0.2.2 for Android emulator to reach host machine)

  Future<List<StateModel>> fetchStates() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/core/states/');
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(resp.body);
      return jsonList.map((e) => StateModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load states: ${resp.statusCode}');
    }
  }

  Future<List<CityModel>> fetchCities({required int stateId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/core/cities/?state_id=$stateId');
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(resp.body);
      return jsonList.map((e) => CityModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load cities: ${resp.statusCode}');
    }
  }
}
