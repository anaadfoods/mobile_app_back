// lib/features/panchang/domain/repositories/panchang_repository.dart
// Pure Dart repository interface for Panchang data.

import '../entities/panchang_entities.dart';

abstract class PanchangRepository {
  Future<PanchangDayEntity> getPanchangDay({
    DateTime? date,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  });

  Future<Map<String, dynamic>> getPanchangMonth({
    required int year,
    required int month,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  });

  Future<List<PanchangFestivalEntity>> getFestivals({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String locale = 'en',
  });

  Future<List<PanchangFestivalEntity>> searchFestivals({
    required String query,
    int? year,
    int? month,
    String locale = 'en',
  });

  Future<List<PanchangVratEntity>> getVratCalendar({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String locale = 'en',
  });

  Future<PanchangGuidanceEntity> getTodayGuidance({
    DateTime? date,
    PanchangLocationEntity? location,
  });

  Future<PanchangGuidanceProfileEntity> getGuidanceProfile();

  Future<PanchangGuidanceProfileEntity> saveGuidanceProfile(
    PanchangGuidanceProfileEntity profile,
  );

  Future<Map<String, dynamic>> getUserPanchang();
}
