// services/location_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/service_locator.dart';
import '../models/location_models.dart';

/// Modular Service for handling Location State/City APIs and
/// Location Autocomplete search (Google Places API & OpenStreetMap Nominatim).
class LocationService {
  final http.Client _httpClient;

  LocationService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  factory LocationService.instance() => getIt<LocationService>();
  LocationService.create({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  // ---------------------------------------------------------------------------
  // 1. Existing App Backend State & City APIs
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // 2. Location Search & Autocomplete (Google Places & OpenStreetMap)
  // ---------------------------------------------------------------------------

  /// Dynamically searches for locations:
  /// - If Google Places API key is present in `.env`, uses Google Places Autocomplete.
  /// - Otherwise, falls back to OpenStreetMap Nominatim API (open-source & free).
  Future<List<LocationSuggestion>> searchLocations(
    String query, {
    String? sessionToken,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final googleApiKey = _getGoogleApiKey();
    if (googleApiKey != null && googleApiKey.isNotEmpty) {
      try {
        final googleResults = await searchGooglePlaces(
          trimmed,
          apiKey: googleApiKey,
          sessionToken: sessionToken,
        );
        if (googleResults.isNotEmpty) {
          return googleResults;
        }
      } catch (e) {
        debugPrint('[LocationService] Google Places failed, falling back to OSM: $e');
      }
    }

    // Fallback to OpenStreetMap Nominatim
    return await searchOpenStreetMap(trimmed);
  }

  /// Option A: Google Places Autocomplete API
  Future<List<LocationSuggestion>> searchGooglePlaces(
    String query, {
    required String apiKey,
    String? sessionToken,
  }) async {
    try {
      final queryParams = <String, String>{
        'input': query,
        'key': apiKey,
        'components': 'country:in',
        if (sessionToken != null && sessionToken.isNotEmpty)
          'sessiontoken': sessionToken,
      };

      final url = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        queryParams,
      );

      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final status = data['status'] as String? ?? '';

        if (status == 'OK' || status == 'ZERO_RESULTS') {
          final predictions = data['predictions'] as List<dynamic>? ?? [];
          return predictions
              .map((e) => LocationSuggestion.fromGooglePlaces(e as Map<String, dynamic>))
              .toList();
        } else {
          debugPrint('[LocationService] Google Places Status: $status - ${data['error_message']}');
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Error searching Google Places: $e');
    }
    return [];
  }

  /// Fetches full latitude, longitude and address details for a Google Place ID
  Future<LocationSuggestion> getGooglePlaceDetails(
    String placeId, {
    required String apiKey,
    String? sessionToken,
  }) async {
    try {
      final queryParams = <String, String>{
        'place_id': placeId,
        'fields': 'geometry,address_components,formatted_address',
        'key': apiKey,
        if (sessionToken != null && sessionToken.isNotEmpty)
          'sessiontoken': sessionToken,
      };

      final url = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        queryParams,
      );

      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          final lat = (location?['lat'] as num?)?.toDouble();
          final lon = (location?['lng'] as num?)?.toDouble();

          final components =
              result['address_components'] as List<dynamic>? ?? [];
          String city = '';
          String state = '';
          String country = 'India';
          String pincode = '';

          for (final c in components) {
            final types = (c['types'] as List<dynamic>?)?.cast<String>() ?? [];
            final longName = c['long_name'] as String? ?? '';
            if (types.contains('locality') || types.contains('sublocality') || types.contains('administrative_area_level_2')) {
              if (city.isEmpty) city = longName;
            } else if (types.contains('administrative_area_level_1')) {
              state = longName;
            } else if (types.contains('country')) {
              country = longName;
            } else if (types.contains('postal_code')) {
              pincode = longName;
            }
          }

          final formatted = result['formatted_address'] as String? ?? '';

          return LocationSuggestion(
            placeId: placeId,
            displayName: formatted.isNotEmpty ? formatted : city,
            mainText: city.isNotEmpty ? city : formatted.split(',').first,
            secondaryText: '$state, $country',
            city: city,
            state: state,
            country: country,
            pincode: pincode,
            latitude: lat,
            longitude: lon,
            raw: result,
          );
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Error fetching Google Place Details: $e');
    }
    return LocationSuggestion(
      placeId: placeId,
      displayName: placeId,
      mainText: placeId,
      secondaryText: '',
    );
  }

  /// Option B: OpenStreetMap Nominatim Search API
  Future<List<LocationSuggestion>> searchOpenStreetMap(String query) async {
    try {
      final url = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '6',
          'countrycodes': 'in',
        },
      );

      final response = await _httpClient.get(
        url,
        headers: {
          'User-Agent': 'AnaadFoodsFlutterApp/1.0 (contact@anaadfoods.com)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list
            .map((e) => LocationSuggestion.fromOpenStreetMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[LocationService] OpenStreetMap search error: $e');
    }
    return [];
  }

  /// Resolves complete lat/lon & address details if needed
  Future<LocationSuggestion> resolveFullLocationDetails(
    LocationSuggestion suggestion, {
    String? sessionToken,
  }) async {
    if (suggestion.latitude != null && suggestion.longitude != null && suggestion.city.isNotEmpty) {
      return suggestion;
    }

    final googleApiKey = _getGoogleApiKey();
    if (googleApiKey != null && googleApiKey.isNotEmpty && suggestion.placeId.isNotEmpty) {
      final details = await getGooglePlaceDetails(
        suggestion.placeId,
        apiKey: googleApiKey,
        sessionToken: sessionToken,
      );
      if (details.latitude != null && details.longitude != null) {
        return details;
      }
    }

    return suggestion;
  }

  String? _getGoogleApiKey() {
    try {
      final key = dotenv.env['GOOGLE_PLACES_API_KEY'] ??
          dotenv.env['GOOGLE_MAPS_API_KEY'] ??
          dotenv.env['GOOGLE_API_KEY'];
      if (key != null && key.isNotEmpty && !key.contains('YOUR_API_KEY')) {
        return key;
      }
    } catch (_) {}
    return null;
  }
}
