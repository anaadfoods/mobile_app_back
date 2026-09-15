// lib/features/panchang/data/repositories/panchang_repository_impl.dart
import '../../domain/entities/panchang_entities.dart';
import '../../domain/repositories/panchang_repository.dart';
import '../datasources/panchang_remote_data_source.dart';

class PanchangRepositoryImpl implements PanchangRepository {
  final PanchangRemoteDataSource _remoteDataSource;

  PanchangRepositoryImpl({required PanchangRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<PanchangDayEntity> getPanchangDay({
    DateTime? date,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  }) {
    return _remoteDataSource.getDay(
      date: date,
      location: location,
      locale: locale,
      calendarSystem: calendarSystem,
      profile: profile,
    );
  }

  @override
  Future<Map<String, dynamic>> getPanchangMonth({
    required int year,
    required int month,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  }) {
    return _remoteDataSource.getMonth(
      year: year,
      month: month,
      location: location,
      locale: locale,
      calendarSystem: calendarSystem,
      profile: profile,
    );
  }

  @override
  Future<List<PanchangFestivalEntity>> getFestivals({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String locale = 'en',
  }) {
    return _remoteDataSource.getFestivals(
      startDate: startDate,
      endDate: endDate,
      days: days,
      locale: locale,
    );
  }

  @override
  Future<List<PanchangFestivalEntity>> searchFestivals({
    required String query,
    int? year,
    int? month,
    String locale = 'en',
  }) {
    return _remoteDataSource.searchFestivals(
      query: query,
      year: year,
      month: month,
      locale: locale,
    );
  }

  @override
  Future<List<PanchangVratEntity>> getVratCalendar({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String locale = 'en',
  }) {
    return _remoteDataSource.getVratCalendar(
      startDate: startDate,
      endDate: endDate,
      days: days,
      locale: locale,
    );
  }

  @override
  Future<PanchangGuidanceEntity> getTodayGuidance({
    DateTime? date,
    PanchangLocationEntity? location,
  }) {
    return _remoteDataSource.getTodayGuidance(
      date: date,
      location: location,
    );
  }

  @override
  Future<PanchangGuidanceProfileEntity> getGuidanceProfile() {
    return _remoteDataSource.getGuidanceProfile();
  }

  @override
  Future<PanchangGuidanceProfileEntity> saveGuidanceProfile(
    PanchangGuidanceProfileEntity profile,
  ) {
    return _remoteDataSource.saveGuidanceProfile(profile);
  }

  @override
  Future<Map<String, dynamic>> getUserPanchang() {
    return _remoteDataSource.getUserPanchang();
  }
}
