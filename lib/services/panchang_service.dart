import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/services/api_exception.dart';
import 'package:http/http.dart' as http;

import '../models/panchang/panchang_day_models.dart';
import '../models/panchang/panchang_month_models.dart';
import '../models/panchang/panchang_festival_models.dart';
import '../models/panchang/panchang_highlights_models.dart';
import '../models/panchang/panchang_muhurats_models.dart';
import '../models/panchang/panchang_vrat_models.dart';

class PanchangService {
  static final PanchangService _instance = PanchangService._internal();
  factory PanchangService() => _instance;
  PanchangService._internal();

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
    final uri = _buildUri(
      ApiConfig.panchangDayEndpoint,
      {
        if (date != null) 'date': date,
        'tz': tz,
        'locale': locale,
        'calendar_system': calendarSystem,
        'profile': profile,
        if (lat != null) 'lat': lat.toString(),
        if (lon != null) 'lon': lon.toString(),
      },
    );

    if (kDebugMode) {
      debugPrint('Panchang requesting: $uri');
    }

    final response = await http
        .get(uri, headers: ApiConfig.getAuthHeaders(token))
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      debugPrint('Panchang GET $uri -> ${response.statusCode}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return PanchangDayResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode);
    }

    throw ApiException.fromStatusCode(response.statusCode, response.body);
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
    final uri = _buildUri(
      ApiConfig.panchangMonthEndpoint,
      {
        'year': year.toString(),
        'month': month.toString(),
        'tz': tz,
        'locale': locale,
        'calendar_system': calendarSystem,
        'profile': profile,
        if (lat != null) 'lat': lat.toString(),
        if (lon != null) 'lon': lon.toString(),
      },
    );

    if (kDebugMode) {
      debugPrint('Panchang requesting: $uri');
    }

    final response = await http
        .get(uri, headers: ApiConfig.getAuthHeaders(token))
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      debugPrint('Panchang GET $uri -> ${response.statusCode}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return PanchangMonthResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode);
    }

    throw ApiException.fromStatusCode(response.statusCode, response.body);
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
    final uri = _buildUri(
      ApiConfig.panchangFestivalsEndpoint,
      {
        'start': startDate,
        'end': endDate,
        if (type != null && type.isNotEmpty) 'type': type,
        'tz': tz,
        'locale': locale,
        'calendar_system': calendarSystem,
        'profile': profile,
        if (lat != null) 'lat': lat.toString(),
        if (lon != null) 'lon': lon.toString(),
      },
    );

    if (kDebugMode) {
      debugPrint('Panchang Festivals requesting: $uri');
    }

    final response = await http
        .get(uri, headers: ApiConfig.getAuthHeaders(token))
        .timeout(const Duration(seconds: 45));

    if (kDebugMode) {
      debugPrint('Panchang Festivals GET $uri -> ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (kDebugMode) {
        debugPrint('Parsed festivals response: $body');
      }
      if (body is Map<String, dynamic>) {
        return PanchangFestivalsResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode);
    }

    throw ApiException.fromStatusCode(response.statusCode, response.body);
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
    final uri = _buildUri(
      ApiConfig.panchangFestivalSearchEndpoint,
      {
        'q': query,
        if (type != null && type.isNotEmpty) 'type': type,
        if (year != null) 'year': year.toString(),
        'tz': tz,
        'locale': locale,
        'calendar_system': calendarSystem,
        'profile': profile,
        if (lat != null) 'lat': lat.toString(),
        if (lon != null) 'lon': lon.toString(),
      },
    );

    if (kDebugMode) {
      debugPrint('Panchang Search requesting: $uri');
    }

    final response = await http
        .get(uri, headers: ApiConfig.getAuthHeaders(token))
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      debugPrint('Panchang Search GET $uri -> ${response.statusCode}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return FestivalSearchResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode);
    }

    throw ApiException.fromStatusCode(response.statusCode, response.body);
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
    final uri = _buildUri(
      ApiConfig.panchangHighlightsEndpoint,
      {
        'year': year.toString(),
        'month': month.toString(),
        'tz': tz,
        'locale': locale,
        'calendar_system': calendarSystem,
        'profile': profile,
        if (lat != null) 'lat': lat.toString(),
        if (lon != null) 'lon': lon.toString(),
      },
    );

    if (kDebugMode) {
      debugPrint('Panchang Highlights requesting: $uri');
    }

    final response = await http
        .get(uri, headers: ApiConfig.getAuthHeaders(token))
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      debugPrint('Panchang Highlights GET $uri -> ${response.statusCode}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return PanchangHighlightsResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode);
    }

    throw ApiException.fromStatusCode(response.statusCode, response.body);
  }

  /// Get muhurats and timings for a specific date
  /// Supports filtering by types parameter: hora, choghadiya, inauspicious, abhijit, brahma
  Future<PanchangMuhuratsResponse> getMuhurats({
    required String token,
    String? date,
    List<String>? types, // e.g., ['hora', 'choghadiya']
    String tz = 'Asia/Kolkata',
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
    double? lat,
    double? lon,
  }) async {
    final uri = _buildUri(
      ApiConfig.panchangMuhuratsEndpoint,
      {
        if (date != null) 'date': date,
        if (types != null && types.isNotEmpty) 'types': types.join(','),
        'tz': tz,
        'locale': locale,
        'calendar_system': calendarSystem,
        'profile': profile,
        if (lat != null) 'lat': lat.toString(),
        if (lon != null) 'lon': lon.toString(),
      },
    );

    if (kDebugMode) {
      debugPrint('Panchang Muhurats requesting: $uri');
    }

    final response = await http
        .get(uri, headers: ApiConfig.getAuthHeaders(token))
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      debugPrint('Panchang Muhurats GET $uri -> ${response.statusCode}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return PanchangMuhuratsResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode);
    }

    throw ApiException.fromStatusCode(response.statusCode, response.body);
  }

  /// Get Vrat Calendar (fasting days)
  /// - Either provide [days] (default behavior on backend is typically 90)
  /// - Or provide [start] and [end] in YYYY-MM-DD format
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
    final uri = _buildUri(
      ApiConfig.panchangVratCalendarEndpoint,
      {
        if (days != null) 'days': days.toString(),
        if (start != null) 'start': start,
        if (end != null) 'end': end,
        'tz': tz,
        'locale': locale,
        'calendar_system': calendarSystem,
        'profile': profile,
        if (lat != null) 'lat': lat.toString(),
        if (lon != null) 'lon': lon.toString(),
      },
    );

    if (kDebugMode) {
      debugPrint('Panchang Vrat Calendar requesting: $uri');
    }

    final response = await http
        .get(uri, headers: ApiConfig.getAuthHeaders(token))
        .timeout(const Duration(seconds: 20));

    if (kDebugMode) {
      debugPrint('Panchang Vrat Calendar GET $uri -> ${response.statusCode}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return VratCalendarResponse.fromJson(body);
      }
      throw ApiException('Unexpected response format', response.statusCode);
    }

    throw ApiException.fromStatusCode(response.statusCode, response.body);
  }

  Uri _buildUri(String endpointPath, Map<String, String> queryParams) {
    final base = Uri.parse('${ApiConfig.panchangBaseUrl}$endpointPath');
    return base.replace(queryParameters: queryParams);
  }
}
