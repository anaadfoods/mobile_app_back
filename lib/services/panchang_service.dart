import 'package:dio/dio.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/api_exception.dart';
import 'package:grocery_app/services/api_client.dart';

import '../models/panchang/panchang_day_models.dart';
import '../models/panchang/panchang_month_models.dart';
import '../models/panchang/panchang_festival_models.dart';
import '../models/panchang/panchang_highlights_models.dart';
import '../models/panchang/panchang_muhurats_models.dart';
import '../models/panchang/panchang_vrat_models.dart';
import '../models/panchang/panchang_guidance_models.dart';



import 'package:grocery_app/service_locator.dart';
void logApi(String message) {
  // Logging removed
}
class PanchangService {
  static final PanchangService _instance = PanchangService._internal();
  factory PanchangService() => getIt<PanchangService>();
  PanchangService._internal();
  static PanchangService create() => PanchangService._internal();

  Future<PanchangDayResponse> getDay({
    required String token,
    String? date,
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final Map<String, dynamic> queryParams = {
      if (date != null) 'date': date,
      'tz': tz,
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
    };

    final response = await ApiClient.instance.get(
      ApiConfig.panchangDayEndpoint,
      queryParameters: queryParams,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return PanchangDayResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  Future<PanchangMonthResponse> getMonth({
    required String token,
    required int year,
    required int month,
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final Map<String, dynamic> queryParams = {
      'year': year.toString(),
      'month': month.toString(),
      'tz': tz,
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
    };

    final response = await ApiClient.instance.get(
      ApiConfig.panchangMonthEndpoint,
      queryParameters: queryParams,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return PanchangMonthResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  /// Fetch festivals in a date range
  Future<PanchangFestivalsResponse> getFestivals({
    required String token,
    required String startDate,
    required String endDate,
    String? type,
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final Map<String, dynamic> queryParams = {
      'start': startDate,
      'end': endDate,
      if (type != null && type.isNotEmpty) 'type': type,
      'tz': tz,
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
    };

    final response = await ApiClient.instance.get(
      ApiConfig.panchangFestivalsEndpoint,
      queryParameters: queryParams,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return PanchangFestivalsResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  /// Search festivals by query
  Future<FestivalSearchResponse> searchFestivals({
    required String token,
    required String query,
    String? type,
    int? year,
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final Map<String, dynamic> queryParams = {
      'q': query,
      if (type != null && type.isNotEmpty) 'type': type,
      if (year != null) 'year': year.toString(),
      'tz': tz,
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
    };

    final response = await ApiClient.instance.get(
      ApiConfig.panchangFestivalSearchEndpoint,
      queryParameters: queryParams,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return FestivalSearchResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  /// Fetch highlights (main festival per day) for a month
  Future<PanchangHighlightsResponse> getHighlights({
    required String token,
    required int year,
    required int month,
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final Map<String, dynamic> queryParams = {
      'year': year.toString(),
      'month': month.toString(),
      'tz': tz,
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
    };

    final response = await ApiClient.instance.get(
      ApiConfig.panchangHighlightsEndpoint,
      queryParameters: queryParams,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return PanchangHighlightsResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  /// Get muhurats and timings for a specific date
  /// Supports filtering by types parameter: hora, choghadiya, inauspicious, abhijit, brahma
  Future<PanchangMuhuratsResponse> getMuhurats({
    required String token,
    String? date,
    List<String>? types,
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final Map<String, dynamic> queryParams = {
      if (date != null) 'date': date,
      if (types != null && types.isNotEmpty) 'types': types.join(','),
      'tz': tz,
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
    };

    final response = await ApiClient.instance.get(
      ApiConfig.panchangMuhuratsEndpoint,
      queryParameters: queryParams,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return PanchangMuhuratsResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  /// Get Vrat Calendar (fasting days)
  Future<VratCalendarResponse> getVratCalendar({
    required String token,
    int? days,
    String? start,
    String? end,
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final Map<String, dynamic> queryParams = {
      if (days != null) 'days': days.toString(),
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      'tz': tz,
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
    };

    final response = await ApiClient.instance.get(
      ApiConfig.panchangVratCalendarEndpoint,
      queryParameters: queryParams,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return VratCalendarResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  /// Get today's guidance recommendations
  Future<GuidanceTodayResponse> getTodayGuidance({
    required String token,
    String? date,
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final Map<String, dynamic> queryParams = {
      if (date != null) 'date': date,
      'tz': tz,
      'locale': locale,
      'calendar_system': calendarSystem,
      'profile': profile,
      if (lat != null) 'lat': lat.toString(),
      if (lon != null) 'lon': lon.toString(),
    };

    final response = await ApiClient.instance.get(
      ApiConfig.panchangGuidanceTodayEndpoint,
      queryParameters: queryParams,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return GuidanceTodayResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  /// Get user's guidance profile/preferences
  Future<GuidanceProfileResponse> getGuidanceProfile({
    required String token,
  }) async {
    final response = await ApiClient.instance.get(
      ApiConfig.panchangGuidanceProfileEndpoint,
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return GuidanceProfileResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    throw ApiException.fromStatusCode(response.statusCode ?? 500, response.data?.toString() ?? '');
  }

  /// Save user's guidance profile/preferences
  Future<GuidanceProfileResponse> saveGuidanceProfile({
    required String token,
    required GuidanceProfileRequest request,
  }) async {
    final response = await ApiClient.instance.post(
      ApiConfig.panchangGuidanceProfileEndpoint,
      data: request.toJson(),
      options: Options(
        headers: ApiConfig.getAuthHeaders(token),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return GuidanceProfileResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode ?? 500);
    }

    // Try to extract error message
    String errorMessage = 'Failed to save preferences';
    try {
      final errorBody = response.data;
      if (errorBody is Map<String, dynamic>) {
        if (errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'].toString();
        } else if (errorBody.isNotEmpty) {
          errorMessage = errorBody.values.map((e) => e.toString()).join(', ');
        }
      }
    } catch (_) {}

    throw ApiException(errorMessage, response.statusCode ?? 500);
  }
}
