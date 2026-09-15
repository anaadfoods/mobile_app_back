// lib/features/panchang/data/datasources/panchang_remote_data_source.dart
import '../../../../services/api_client.dart';
import '../../../../services/api_config.dart';
import '../../domain/entities/panchang_entities.dart';
import '../models/panchang_models.dart';

abstract class PanchangRemoteDataSource {
  Future<PanchangDayEntity> getDay({
    DateTime? date,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  });

  Future<Map<String, dynamic>> getMonth({
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

class PanchangRemoteDataSourceImpl implements PanchangRemoteDataSource {
  final ApiClient _apiClient;

  PanchangRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<PanchangDayEntity> getDay({
    DateTime? date,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  }) async {
    final queryParams = <String, dynamic>{
      if (date != null) 'date': _formatDate(date),
      'tz': location?.timezone ?? 'Asia/Kolkata',
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (location != null) 'lat': location.latitude.toString(),
      if (location != null) 'lon': location.longitude.toString(),
    };

    final res = await _apiClient.get(
      ApiConfig.panchangDayEndpoint,
      queryParameters: queryParams,
    );

    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      return PanchangDayModel.fromJson(res.data as Map<String, dynamic>);
    }
    throw Exception('Failed to load Panchang for date.');
  }

  @override
  Future<Map<String, dynamic>> getMonth({
    required int year,
    required int month,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  }) async {
    final queryParams = <String, dynamic>{
      'year': year.toString(),
      'month': month.toString(),
      'tz': location?.timezone ?? 'Asia/Kolkata',
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (location != null) 'lat': location.latitude.toString(),
      if (location != null) 'lon': location.longitude.toString(),
    };

    final res = await _apiClient.get(
      ApiConfig.panchangMonthEndpoint,
      queryParameters: queryParams,
    );

    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Failed to load Panchang month.');
  }

  @override
  Future<List<PanchangFestivalEntity>> getFestivals({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String locale = 'en',
  }) async {
    final queryParams = <String, dynamic>{
      if (startDate != null) 'start': _formatDate(startDate),
      if (endDate != null) 'end': _formatDate(endDate),
      if (days != null) 'days': days.toString(),
      'locale': locale,
    };

    final res = await _apiClient.get(
      ApiConfig.panchangFestivalsEndpoint,
      queryParameters: queryParams,
    );

    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      final items = res.data['items'] as List<dynamic>? ?? [];
      return items.map((i) => PanchangFestivalModel.fromJson(i as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<List<PanchangFestivalEntity>> searchFestivals({
    required String query,
    int? year,
    int? month,
    String locale = 'en',
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      if (year != null) 'year': year.toString(),
      if (month != null) 'month': month.toString(),
      'locale': locale,
    };

    final res = await _apiClient.get(
      ApiConfig.panchangFestivalSearchEndpoint,
      queryParameters: queryParams,
    );

    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      final items = res.data['items'] as List<dynamic>? ?? [];
      return items.map((i) => PanchangFestivalModel.fromJson(i as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<List<PanchangVratEntity>> getVratCalendar({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String locale = 'en',
  }) async {
    final queryParams = <String, dynamic>{
      if (startDate != null) 'start': _formatDate(startDate),
      if (endDate != null) 'end': _formatDate(endDate),
      if (days != null) 'days': days.toString(),
      'locale': locale,
    };

    final res = await _apiClient.get(
      ApiConfig.panchangVratCalendarEndpoint,
      queryParameters: queryParams,
    );

    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      final items = res.data['items'] as List<dynamic>? ?? [];
      return items.map((i) => PanchangVratModel.fromJson(i as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<PanchangGuidanceEntity> getTodayGuidance({
    DateTime? date,
    PanchangLocationEntity? location,
  }) async {
    final queryParams = <String, dynamic>{
      if (date != null) 'date': _formatDate(date),
      'tz': location?.timezone ?? 'Asia/Kolkata',
      if (location != null) 'lat': location.latitude.toString(),
      if (location != null) 'lon': location.longitude.toString(),
    };

    final res = await _apiClient.get(
      '/api/panchang-calender/diet-guidance/',
      queryParameters: queryParams,
    );

    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      final map = res.data as Map<String, dynamic>;
      return PanchangGuidanceEntity(
        date: map['date']?.toString() ?? '',
        fastingType: map['fasting_type']?.toString() ?? 'Regular Satvik',
        recommendedFoods: (map['recommended_foods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        restrictedFoods: (map['restricted_foods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        ayurvedicRationale: map['ayurvedic_rationale']?.toString() ?? '',
        userDoshaSynergy: map['user_dosha_synergy'] as Map<String, dynamic>? ?? {},
      );
    }
    throw Exception('Failed to load daily guidance.');
  }

  @override
  Future<PanchangGuidanceProfileEntity> getGuidanceProfile() async {
    final res = await _apiClient.get('/api/panchang-calender/guidance/profile/');
    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      final m = res.data as Map<String, dynamic>;
      return PanchangGuidanceProfileEntity(
        dietStyle: m['diet_style']?.toString() ?? 'normal',
        fastingPreference: m['fasting_preference']?.toString() ?? 'none',
        devata: m['devata']?.toString() ?? 'other',
        profile: m['profile']?.toString() ?? 'default',
        locale: m['locale']?.toString() ?? 'en',
        workSchedule: m['work_schedule'] as Map<String, dynamic>? ?? {},
      );
    }
    return const PanchangGuidanceProfileEntity();
  }

  @override
  Future<PanchangGuidanceProfileEntity> saveGuidanceProfile(
    PanchangGuidanceProfileEntity profile,
  ) async {
    final res = await _apiClient.post(
      '/api/panchang-calender/guidance/profile/',
      data: {
        'diet_style': profile.dietStyle,
        'fasting_preference': profile.fastingPreference,
        'devata': profile.devata,
        'profile': profile.profile,
        'locale': profile.locale,
        'work_schedule': profile.workSchedule,
      },
    );
    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      final m = res.data as Map<String, dynamic>;
      return PanchangGuidanceProfileEntity(
        dietStyle: m['diet_style']?.toString() ?? profile.dietStyle,
        fastingPreference: m['fasting_preference']?.toString() ?? profile.fastingPreference,
        devata: m['devata']?.toString() ?? profile.devata,
        profile: m['profile']?.toString() ?? profile.profile,
        locale: m['locale']?.toString() ?? profile.locale,
        workSchedule: m['work_schedule'] as Map<String, dynamic>? ?? profile.workSchedule,
      );
    }
    return profile;
  }

  @override
  Future<Map<String, dynamic>> getUserPanchang() async {
    final res = await _apiClient.get('/api/panchang-calender/user-panchang/');
    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Failed to load user-specific Panchang.');
  }
}
