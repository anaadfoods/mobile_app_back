import 'package:grocery_app/services/auth_service.dart';

import '../models/panchang/panchang_day_models.dart';
import '../models/panchang/panchang_month_models.dart';
import '../models/panchang/panchang_festival_models.dart';
import '../models/panchang/panchang_highlights_models.dart';
import '../models/panchang/panchang_muhurats_models.dart';
import '../models/panchang/panchang_vrat_models.dart';
import '../models/panchang/panchang_guidance_models.dart';
import '../services/panchang_service.dart';

class PanchangRepository {
  final PanchangService _service;
  final AuthService _authService;

  PanchangRepository({PanchangService? service, AuthService? authService})
      : _service = service ?? PanchangService(),
        _authService = authService ?? AuthService();

  /// MVP defaults: IST + English + default profile + amanta + Delhi lat/lon.
  /// Later we will move these to a Panchang settings screen + persisted prefs.
  static const String defaultTz = 'Asia/Kolkata';
  static const String defaultLocale = 'en';
  static const String defaultCalendarSystem = 'amanta';
  static const String defaultProfile = 'default';

  static const double defaultLat = 28.6139;
  static const double defaultLon = 77.2090;

  Future<PanchangDayResponse> getTodayDay() async {
    return getDay(null);
  }

  /// Fetch Panchang for a specific date (or today if null).
  /// Date format expected by API: YYYY-MM-DD
  Future<PanchangDayResponse> getDay(DateTime? date) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      String? dateStr;
      if (date != null) {
        dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      return _service.getDay(
        token: token,
        date: dateStr,
        tz: defaultTz,
        locale: defaultLocale,
        calendarSystem: defaultCalendarSystem,
        profile: defaultProfile,
        lat: defaultLat,
        lon: defaultLon,
      );
    });
  }

  Future<PanchangMonthResponse> getMonth({required int year, required int month}) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      return _service.getMonth(
        token: token,
        year: year,
        month: month,
        tz: defaultTz,
        locale: defaultLocale,
        calendarSystem: defaultCalendarSystem,
        profile: defaultProfile,
        lat: defaultLat,
        lon: defaultLon,
      );
    });
  }

  /// Fetch festivals in a date range
  Future<PanchangFestivalsResponse> getFestivals({
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);
      return _service.getFestivals(
        token: token,
        startDate: startStr,
        endDate: endStr,
        type: type,
        tz: defaultTz,
        locale: defaultLocale,
        calendarSystem: defaultCalendarSystem,
        profile: defaultProfile,
        lat: defaultLat,
        lon: defaultLon,
      );
    });
  }

  /// Search festivals by query
  Future<FestivalSearchResponse> searchFestivals({
    required String query,
    String? type,
    int? year,
  }) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      return _service.searchFestivals(
        token: token,
        query: query,
        type: type,
        year: year,
        tz: defaultTz,
        locale: defaultLocale,
        calendarSystem: defaultCalendarSystem,
        profile: defaultProfile,
        lat: defaultLat,
        lon: defaultLon,
      );
    });
  }

  /// Fetch highlights (main festival per day) for a month
  Future<PanchangHighlightsResponse> getHighlights({
    required int year,
    required int month,
  }) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      return _service.getHighlights(
        token: token,
        year: year,
        month: month,
        tz: defaultTz,
        locale: defaultLocale,
        calendarSystem: defaultCalendarSystem,
        profile: defaultProfile,
        lat: defaultLat,
        lon: defaultLon,
      );
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Fetch Vrat Calendar (fasting days)
  /// - If [days] is provided, backend returns that many days from today.
  /// - Otherwise you can provide [start] and [end].
  Future<VratCalendarResponse> getVratCalendar({
    int? days,
    DateTime? start,
    DateTime? end,
  }) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      return _service.getVratCalendar(
        token: token,
        days: days,
        start: start != null ? _formatDate(start) : null,
        end: end != null ? _formatDate(end) : null,
        tz: defaultTz,
        locale: defaultLocale,
        calendarSystem: defaultCalendarSystem,
        profile: defaultProfile,
        lat: defaultLat,
        lon: defaultLon,
      );
    });
  }

  /// Fetch muhurats and timings for a specific date
  /// Use types parameter to fetch only specific muhurats: ['hora', 'choghadiya', 'inauspicious', 'abhijit', 'brahma']
  Future<PanchangMuhuratsResponse> getMuhurats(DateTime? date, {List<String>? types}) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      String? dateStr;
      if (date != null) {
        dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      return _service.getMuhurats(
        token: token,
        date: dateStr,
        types: types,
        tz: defaultTz,
        locale: defaultLocale,
        calendarSystem: defaultCalendarSystem,
        profile: defaultProfile,
        lat: defaultLat,
        lon: defaultLon,
      );
    });
  }

  /// Fetch today's guidance recommendations
  Future<GuidanceTodayResponse> getTodayGuidance({
    DateTime? date,
    double? lat,
    double? lon,
  }) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      String? dateStr;
      if (date != null) {
        dateStr = _formatDate(date);
      }
      return _service.getTodayGuidance(
        token: token,
        date: dateStr,
        tz: defaultTz,
        locale: defaultLocale,
        calendarSystem: defaultCalendarSystem,
        profile: defaultProfile,
        lat: lat ?? defaultLat,
        lon: lon ?? defaultLon,
      );
    });
  }

  /// Get user's guidance profile/preferences
  Future<GuidanceProfileResponse> getGuidanceProfile() async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      return _service.getGuidanceProfile(token: token);
    });
  }

  /// Save user's guidance profile/preferences
  Future<GuidanceProfileResponse> saveGuidanceProfile(GuidanceProfileRequest request) async {
    return _makeAuthenticatedRequest(() async {
      final token = await _getToken();
      return _service.saveGuidanceProfile(token: token, request: request);
    });
  }

  Future<String> _getToken() async {
    final token = await _authService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('You must be logged in to use Panchang.');
    }
    return token;
  }

  Future<T> _makeAuthenticatedRequest<T>(Future<T> Function() apiCall) async {
    try {
      if (!await _authService.isLoggedIn()) {
        throw Exception('You must be logged in to use Panchang.');
      }
      return await apiCall();
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Session expired')) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return await apiCall();
        }
      }
      rethrow;
    }
  }
}
