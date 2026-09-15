// lib/features/panchang/data/repositories/kundli_repository_impl.dart
import '../../domain/entities/kundli_entities.dart';
import '../../domain/repositories/kundli_repository.dart';
import '../datasources/kundli_remote_data_source.dart';

class KundliRepositoryImpl implements KundliRepository {
  final KundliRemoteDataSource _remoteDataSource;

  KundliRepositoryImpl({required KundliRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<KundliEntity?> getUserKundli() {
    return _remoteDataSource.getUserKundli();
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
  }) {
    return _remoteDataSource.generateKundli(
      dateOfBirth: dateOfBirth,
      timeOfBirth: timeOfBirth,
      name: name,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      birthCity: birthCity,
      birthState: birthState,
      saveToProfile: saveToProfile,
    );
  }

  @override
  Future<KundliBirthDetails?> getSavedBirthDetails() {
    return _remoteDataSource.getSavedBirthDetails();
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
  }) {
    return _remoteDataSource.saveBirthDetails(
      dateOfBirth: dateOfBirth,
      timeOfBirth: timeOfBirth,
      name: name,
      birthCity: birthCity,
      birthState: birthState,
      birthCountry: birthCountry,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
    );
  }
}
