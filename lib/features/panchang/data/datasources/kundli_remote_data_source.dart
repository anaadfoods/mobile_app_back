// lib/features/panchang/data/datasources/kundli_remote_data_source.dart
import '../../../../services/api_client.dart';
import '../../../../services/api_config.dart';
import '../../domain/entities/kundli_entities.dart';
import '../models/kundli_models.dart';

abstract class KundliRemoteDataSource {
  Future<KundliEntity?> getUserKundli();

  Future<KundliEntity> generateKundli({
    required String dateOfBirth,
    required String timeOfBirth,
    String name = '',
    required double latitude,
    required double longitude,
    String timezone = 'Asia/Kolkata',
    String birthCity = '',
    String birthState = '',
    bool saveToProfile = false,
  });

  Future<KundliBirthDetails?> getSavedBirthDetails();

  Future<bool> saveBirthDetails({
    required String dateOfBirth,
    required String timeOfBirth,
    String name = '',
    required String birthCity,
    String birthState = '',
    String birthCountry = 'India',
    double? latitude,
    double? longitude,
    String timezone = 'Asia/Kolkata',
  });
}

class KundliRemoteDataSourceImpl implements KundliRemoteDataSource {
  final ApiClient _apiClient;

  KundliRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  @override
  Future<KundliEntity?> getUserKundli() async {
    final res = await _apiClient.get('/api/panchang-calender/kundli/');
    if (res.statusCode == 200 && res.data != null) {
      final map = res.data as Map<String, dynamic>;
      if (map['has_birth_details'] == true && map['data'] != null) {
        return KundliModel.fromJson(map['data'] as Map<String, dynamic>);
      }
    }
    return null;
  }

  @override
  Future<KundliEntity> generateKundli({
    required String dateOfBirth,
    required String timeOfBirth,
    String name = '',
    required double latitude,
    required double longitude,
    String timezone = 'Asia/Kolkata',
    String birthCity = '',
    String birthState = '',
    bool saveToProfile = false,
  }) async {
    final res = await _apiClient.post(
      '/api/panchang-calender/kundli/generate/',
      data: {
        'date_of_birth': dateOfBirth,
        'time_of_birth': timeOfBirth,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'birth_city': birthCity,
        'birth_state': birthState,
        'save_to_profile': saveToProfile,
      },
    );
    if (res.statusCode == 200 && res.data != null) {
      final map = res.data as Map<String, dynamic>;
      if (map['data'] != null) {
        return KundliModel.fromJson(map['data'] as Map<String, dynamic>);
      }
    }
    throw Exception(res.data?['message'] ?? 'Failed to generate Kundli.');
  }

  @override
  Future<KundliBirthDetails?> getSavedBirthDetails() async {
    final res = await _apiClient.get(ApiConfig.healthProfileBirthDetailsEndpoint);
    if (res.statusCode == 200 && res.data != null) {
      final map = res.data as Map<String, dynamic>;
      if (map['has_birth_details'] == true && map['data'] != null) {
        final d = map['data'] as Map<String, dynamic>;
        return KundliBirthDetails(
          date: d['date_of_birth']?.toString() ?? '',
          time: d['time_of_birth']?.toString() ?? '',
          latitude: (d['birth_latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (d['birth_longitude'] as num?)?.toDouble() ?? 0.0,
          timezone: d['birth_timezone']?.toString() ?? 'Asia/Kolkata',
          city: d['birth_city']?.toString() ?? '',
          state: d['birth_state']?.toString() ?? '',
        );
      }
    }
    return null;
  }

  @override
  Future<bool> saveBirthDetails({
    required String dateOfBirth,
    required String timeOfBirth,
    String name = '',
    required String birthCity,
    String birthState = '',
    String birthCountry = 'India',
    double? latitude,
    double? longitude,
    String timezone = 'Asia/Kolkata',
  }) async {
    final res = await _apiClient.put(
      ApiConfig.healthProfileBirthDetailsEndpoint,
      data: {
        'date_of_birth': dateOfBirth,
        'time_of_birth': timeOfBirth,
        'name': name,
        'birth_city': birthCity,
        'birth_state': birthState,
        'birth_country': birthCountry,
        'birth_latitude': latitude,
        'birth_longitude': longitude,
        'birth_timezone': timezone,
      },
    );
    return res.statusCode == 200;
  }
}
