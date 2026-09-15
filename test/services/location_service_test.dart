// test/services/location_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:grocery_app/services/location_service.dart';

void main() {
  group('LocationService Tests', () {
    test('searchOpenStreetMap parses Nominatim JSON response correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'nominatim.openstreetmap.org') {
          final sampleResponse = [
            {
              'place_id': 123456,
              'lat': '26.9124',
              'lon': '75.7873',
              'display_name': 'Jaipur, Jaipur District, Rajasthan, India',
              'name': 'Jaipur',
              'address': {
                'city': 'Jaipur',
                'state': 'Rajasthan',
                'country': 'India',
                'postcode': '302001',
              }
            }
          ];
          return http.Response(jsonEncode(sampleResponse), 200, headers: {
            'content-type': 'application/json',
          });
        }
        return http.Response('Not Found', 404);
      });

      final service = LocationService(httpClient: mockClient);
      final results = await service.searchOpenStreetMap('Jaipur');

      expect(results.length, 1);
      final item = results.first;
      expect(item.placeId, '123456');
      expect(item.mainText, 'Jaipur');
      expect(item.city, 'Jaipur');
      expect(item.state, 'Rajasthan');
      expect(item.latitude, 26.9124);
      expect(item.longitude, 75.7873);
      expect(item.pincode, '302001');
    });

    test('searchGooglePlaces parses Google Places Autocomplete response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'maps.googleapis.com' &&
            request.url.path == '/maps/api/place/autocomplete/json') {
          final sampleResponse = {
            'status': 'OK',
            'predictions': [
              {
                'place_id': 'ChIJF03U9w9abTkR3B2kE_4_N-M',
                'description': 'Jaipur, Rajasthan, India',
                'structured_formatting': {
                  'main_text': 'Jaipur',
                  'secondary_text': 'Rajasthan, India',
                }
              }
            ]
          };
          return http.Response(jsonEncode(sampleResponse), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = LocationService(httpClient: mockClient);
      final results = await service.searchGooglePlaces(
        'Jaipur',
        apiKey: 'test_api_key',
      );

      expect(results.length, 1);
      final item = results.first;
      expect(item.placeId, 'ChIJF03U9w9abTkR3B2kE_4_N-M');
      expect(item.mainText, 'Jaipur');
      expect(item.secondaryText, 'Rajasthan, India');
      expect(item.displayName, 'Jaipur, Rajasthan, India');
    });

    test('getGooglePlaceDetails extracts coordinates and address components', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'maps.googleapis.com' &&
            request.url.path == '/maps/api/place/details/json') {
          final sampleResponse = {
            'status': 'OK',
            'result': {
              'formatted_address': 'Jaipur, Rajasthan, India',
              'geometry': {
                'location': {'lat': 26.9124, 'lng': 75.7873}
              },
              'address_components': [
                {'long_name': 'Jaipur', 'types': ['locality']},
                {'long_name': 'Rajasthan', 'types': ['administrative_area_level_1']},
                {'long_name': 'India', 'types': ['country']},
                {'long_name': '302001', 'types': ['postal_code']},
              ]
            }
          };
          return http.Response(jsonEncode(sampleResponse), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = LocationService(httpClient: mockClient);
      final result = await service.getGooglePlaceDetails(
        'ChIJF03U9w9abTkR3B2kE_4_N-M',
        apiKey: 'test_api_key',
      );

      expect(result.placeId, 'ChIJF03U9w9abTkR3B2kE_4_N-M');
      expect(result.city, 'Jaipur');
      expect(result.state, 'Rajasthan');
      expect(result.pincode, '302001');
      expect(result.latitude, 26.9124);
      expect(result.longitude, 75.7873);
    });

    test('searchLocations returns empty list for short queries (<2 chars)', () async {
      final service = LocationService();
      final results = await service.searchLocations('a');
      expect(results, isEmpty);
    });
  });
}
