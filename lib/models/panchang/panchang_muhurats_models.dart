import 'panchang_common_models.dart';
import 'panchang_day_models.dart';

/// Response for /api/panchang-calender/muhurats/ endpoint
class PanchangMuhuratsResponse {
  final String date;
  final String timezone;
  final String locale;
  final String calendarSystem;
  final String profile;
  final PanchangLocation? location;
  final String calcVersion;
  final DateTime? now;
  final PanchangSunMoonTimings? sunMoonTimings;
  final PanchangTimeWindow? brahma;
  final PanchangTimeWindow? abhijit;
  final PanchangHora? hora;
  final PanchangChoghadiya? choghadiya;
  final PanchangInauspiciousTimings? inauspicious;

  const PanchangMuhuratsResponse({
    required this.date,
    required this.timezone,
    required this.locale,
    required this.calendarSystem,
    required this.profile,
    this.location,
    required this.calcVersion,
    this.now,
    this.sunMoonTimings,
    this.brahma,
    this.abhijit,
    this.hora,
    this.choghadiya,
    this.inauspicious,
  });

  factory PanchangMuhuratsResponse.fromJson(Map<String, dynamic> json) {
    return PanchangMuhuratsResponse(
      date: (json['date'] ?? '').toString(),
      timezone: (json['timezone'] ?? '').toString(),
      locale: (json['locale'] ?? '').toString(),
      calendarSystem: (json['calendar_system'] ?? '').toString(),
      profile: (json['profile'] ?? '').toString(),
      location: json['location'] != null
          ? PanchangLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      calcVersion: (json['calc_version'] ?? '').toString(),
      now: _tryParseDateTime(json['now']),
      sunMoonTimings: json['sun_moon_timings'] != null
          ? PanchangSunMoonTimings.fromJson(
              json['sun_moon_timings'] as Map<String, dynamic>)
          : null,
      brahma: json['brahma'] != null
          ? PanchangTimeWindow.fromJson(json['brahma'] as Map<String, dynamic>)
          : null,
      abhijit: json['abhijit'] != null
          ? PanchangTimeWindow.fromJson(
              json['abhijit'] as Map<String, dynamic>)
          : null,
      hora: json['hora'] != null
          ? PanchangHora.fromJson(json['hora'] as Map<String, dynamic>)
          : null,
      choghadiya: json['choghadiya'] != null
          ? PanchangChoghadiya.fromJson(
              json['choghadiya'] as Map<String, dynamic>)
          : null,
      inauspicious: json['inauspicious'] != null
          ? PanchangInauspiciousTimings.fromJson(
              json['inauspicious'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PanchangInauspiciousTimings {
  final PanchangTimeWindow? rahuKaal;
  final PanchangTimeWindow? yamaganda;
  final PanchangTimeWindow? gulika;

  const PanchangInauspiciousTimings({
    this.rahuKaal,
    this.yamaganda,
    this.gulika,
  });

  factory PanchangInauspiciousTimings.fromJson(Map<String, dynamic> json) {
    return PanchangInauspiciousTimings(
      rahuKaal: json['rahu_kaal'] != null
          ? PanchangTimeWindow.fromJson(
              json['rahu_kaal'] as Map<String, dynamic>)
          : null,
      yamaganda: json['yamaganda'] != null
          ? PanchangTimeWindow.fromJson(
              json['yamaganda'] as Map<String, dynamic>)
          : null,
      gulika: json['gulika'] != null
          ? PanchangTimeWindow.fromJson(json['gulika'] as Map<String, dynamic>)
          : null,
    );
  }
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (e) {
    return null;
  }
}
