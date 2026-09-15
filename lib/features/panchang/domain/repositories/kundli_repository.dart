// lib/features/panchang/domain/repositories/kundli_repository.dart
// Pure Dart repository interface for Kundli calculations and birth details.

import '../entities/kundli_entities.dart';

abstract class KundliRepository {
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
