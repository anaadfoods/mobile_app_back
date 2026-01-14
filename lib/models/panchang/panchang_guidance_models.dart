/// Panchang Guidance Models
/// Models for the Today Guidance feature

// Helper to parse DateTime from various formats
DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

// Helper to format time in 12-hour format
String _formatTime12(DateTime dt) {
  final hour = dt.hour;
  final minute = dt.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$hour12:${minute.toString().padLeft(2, '0')} $period';
}

/// Main response from /guidance/today/ endpoint
class GuidanceTodayResponse {
  final String date;
  final String tz;
  final String locale;
  final String calendarSystem;
  final String profile;
  final DateTime? now;
  final GuidanceSource source;
  final UserPreferences userPreferences;
  final List<GuidanceRecommendation> recommendations;

  const GuidanceTodayResponse({
    required this.date,
    required this.tz,
    required this.locale,
    required this.calendarSystem,
    required this.profile,
    this.now,
    required this.source,
    required this.userPreferences,
    required this.recommendations,
  });

  factory GuidanceTodayResponse.fromJson(Map<String, dynamic> json) {
    return GuidanceTodayResponse(
      date: (json['date'] ?? '').toString(),
      tz: (json['tz'] ?? 'Asia/Kolkata').toString(),
      locale: (json['locale'] ?? 'en').toString(),
      calendarSystem: (json['calendar_system'] ?? 'amanta').toString(),
      profile: (json['profile'] ?? 'default').toString(),
      now: _tryParseDateTime(json['now']),
      source: GuidanceSource.fromJson(json['source'] ?? {}),
      userPreferences: UserPreferences.fromJson(json['user_preferences'] ?? {}),
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => GuidanceRecommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Source information (basic panchang data for the day)
class GuidanceSource {
  final String tithi;
  final String vara;
  final DateTime? sunrise;
  final DateTime? sunset;

  const GuidanceSource({
    required this.tithi,
    required this.vara,
    this.sunrise,
    this.sunset,
  });

  factory GuidanceSource.fromJson(Map<String, dynamic> json) {
    return GuidanceSource(
      tithi: (json['tithi'] ?? '').toString(),
      vara: (json['vara'] ?? '').toString(),
      sunrise: _tryParseDateTime(json['sunrise']),
      sunset: _tryParseDateTime(json['sunset']),
    );
  }

  String get formattedSunrise =>
      sunrise != null ? _formatTime12(sunrise!.toLocal()) : '--:--';
  String get formattedSunset =>
      sunset != null ? _formatTime12(sunset!.toLocal()) : '--:--';
}

/// User preferences stored in backend
class UserPreferences {
  final String dietStyle;
  final String fastingPreference;
  final String devata;
  final WorkSchedule? workSchedule;

  const UserPreferences({
    required this.dietStyle,
    required this.fastingPreference,
    required this.devata,
    this.workSchedule,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      dietStyle: (json['diet_style'] ?? 'normal').toString(),
      fastingPreference: (json['fasting_preference'] ?? 'none').toString(),
      devata: (json['devata'] ?? 'other').toString(),
      workSchedule: json['work_schedule'] != null
          ? WorkSchedule.fromJson(json['work_schedule'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Work schedule for personalized guidance
class WorkSchedule {
  final String start;
  final String end;

  const WorkSchedule({required this.start, required this.end});

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      start: (json['start'] ?? '09:00').toString(),
      end: (json['end'] ?? '17:00').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

/// Individual recommendation for an activity type
class GuidanceRecommendation {
  final String type;
  final String title;
  final String verdict;
  final List<GuidanceTimeWindow> recommendedWindows;
  final List<GuidanceTimeWindow> avoidWindows;
  final dynamic notes; // Can be String or List<String>
  final GuidanceVratInfo? vrat;
  final String? dietStyle;
  final String? devata;
  final WorkSchedule? workSchedule;
  final Map<String, dynamic>? signals;

  const GuidanceRecommendation({
    required this.type,
    required this.title,
    required this.verdict,
    required this.recommendedWindows,
    required this.avoidWindows,
    this.notes,
    this.vrat,
    this.dietStyle,
    this.devata,
    this.workSchedule,
    this.signals,
  });

  factory GuidanceRecommendation.fromJson(Map<String, dynamic> json) {
    return GuidanceRecommendation(
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      verdict: (json['verdict'] ?? 'none').toString(),
      recommendedWindows: (json['recommended_windows'] as List<dynamic>?)
              ?.map((e) => GuidanceTimeWindow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      avoidWindows: (json['avoid_windows'] as List<dynamic>?)
              ?.map((e) => GuidanceTimeWindow.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'],
      vrat: json['vrat'] != null
          ? GuidanceVratInfo.fromJson(json['vrat'] as Map<String, dynamic>)
          : null,
      dietStyle: json['diet_style']?.toString(),
      devata: json['devata']?.toString(),
      workSchedule: json['work_schedule'] != null
          ? WorkSchedule.fromJson(json['work_schedule'] as Map<String, dynamic>)
          : null,
      signals: json['signals'] as Map<String, dynamic>?,
    );
  }

  /// Get notes as a list of strings (handles both String and List<String>)
  List<String> get notesList {
    if (notes == null) return [];
    if (notes is String) return [notes as String];
    if (notes is List) return (notes as List).map((e) => e.toString()).toList();
    return [];
  }

  /// Check if there's an active recommended window right now
  bool get hasActiveRecommendedWindow =>
      recommendedWindows.any((w) => w.isCurrent);

  /// Check if there's an active avoid window right now
  bool get hasActiveAvoidWindow => avoidWindows.any((w) => w.isCurrent);

  /// Get upcoming recommended windows (not yet started)
  List<GuidanceTimeWindow> get upcomingRecommendedWindows =>
      recommendedWindows.where((w) => w.isFuture).toList();

  /// Get upcoming avoid windows (not yet started)
  List<GuidanceTimeWindow> get upcomingAvoidWindows =>
      avoidWindows.where((w) => w.isFuture).toList();
}

/// Time window for recommended/avoid periods
class GuidanceTimeWindow {
  final String label;
  final String reason;
  final DateTime start;
  final DateTime end;

  const GuidanceTimeWindow({
    required this.label,
    required this.reason,
    required this.start,
    required this.end,
  });

  factory GuidanceTimeWindow.fromJson(Map<String, dynamic> json) {
    return GuidanceTimeWindow(
      label: (json['label'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      start: _tryParseDateTime(json['start'])!,
      end: _tryParseDateTime(json['end'])!,
    );
  }

  /// Dynamically calculate if the window is current
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(start.toLocal()) && now.isBefore(end.toLocal());
  }

  /// Dynamically calculate if the window is in the past
  bool get isPast {
    final now = DateTime.now();
    return now.isAfter(end.toLocal());
  }

  /// Dynamically calculate if the window is in the future
  bool get isFuture {
    final now = DateTime.now();
    return now.isBefore(start.toLocal());
  }

  String get formattedTimeRange {
    final startFormatted = _formatTime12(start.toLocal());
    final endFormatted = _formatTime12(end.toLocal());
    return '$startFormatted - $endFormatted';
  }
}

/// Vrat (fasting) information
class GuidanceVratInfo {
  final String? name;
  final String? code;
  final String? description;
  final String? observance;
  final String? paranRules;

  const GuidanceVratInfo({
    this.name,
    this.code,
    this.description,
    this.observance,
    this.paranRules,
  });

  factory GuidanceVratInfo.fromJson(Map<String, dynamic> json) {
    return GuidanceVratInfo(
      name: json['name']?.toString(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
      observance: json['observance']?.toString(),
      paranRules: json['paran_rules']?.toString(),
    );
  }
}

/// Response from /guidance/profile/ GET endpoint
class GuidanceProfileResponse {
  final String dietStyle;
  final String fastingPreference;
  final String devata;
  final String profile;
  final String locale;
  final WorkSchedule? workSchedule;

  const GuidanceProfileResponse({
    required this.dietStyle,
    required this.fastingPreference,
    required this.devata,
    required this.profile,
    required this.locale,
    this.workSchedule,
  });

  factory GuidanceProfileResponse.fromJson(Map<String, dynamic> json) {
    return GuidanceProfileResponse(
      dietStyle: (json['diet_style'] ?? 'normal').toString(),
      fastingPreference: (json['fasting_preference'] ?? 'none').toString(),
      devata: (json['devata'] ?? 'other').toString(),
      profile: (json['profile'] ?? 'default').toString(),
      locale: (json['locale'] ?? 'en').toString(),
      workSchedule: json['work_schedule'] != null
          ? WorkSchedule.fromJson(json['work_schedule'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Request body for /guidance/profile/ POST endpoint
class GuidanceProfileRequest {
  final String? dietStyle;
  final String? fastingPreference;
  final String? devata;
  final String? profile;
  final String? locale;
  final WorkSchedule? workSchedule;

  const GuidanceProfileRequest({
    this.dietStyle,
    this.fastingPreference,
    this.devata,
    this.profile,
    this.locale,
    this.workSchedule,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (dietStyle != null) map['diet_style'] = dietStyle;
    if (fastingPreference != null) map['fasting_preference'] = fastingPreference;
    if (devata != null) map['devata'] = devata;
    if (profile != null) map['profile'] = profile;
    if (locale != null) map['locale'] = locale;
    if (workSchedule != null) map['work_schedule'] = workSchedule!.toJson();
    return map;
  }
}

