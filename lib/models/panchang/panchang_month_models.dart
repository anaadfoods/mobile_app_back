import 'panchang_common_models.dart';

class PanchangDaySummary {
  final String date;
  final int weekday;
  final int dayNumber;
  final bool isToday;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? moonrise;
  final DateTime? moonset;
  final String tithi;
  final List<PanchangFestivalItem> festivals;
  final int majorFestivalsCount;
  final int vratsCount;
  final String primaryLabel;
  final String masa;
  final int masaIndex;

  const PanchangDaySummary({
    required this.date,
    required this.weekday,
    required this.dayNumber,
    required this.isToday,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.tithi,
    required this.festivals,
    required this.majorFestivalsCount,
    required this.vratsCount,
    required this.primaryLabel,
    required this.masa,
    required this.masaIndex,
  });

  factory PanchangDaySummary.fromJson(Map<String, dynamic> json) {
    final festivalsRaw = json['festivals'];
    final festivals = festivalsRaw is List
        ? festivalsRaw
            .whereType<Map<String, dynamic>>()
            .map(PanchangFestivalItem.fromJson)
            .toList()
        : <PanchangFestivalItem>[];

    return PanchangDaySummary(
      date: (json['date'] ?? '').toString(),
      weekday: (json['weekday'] as num?)?.toInt() ?? 0,
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 0,
      isToday: json['is_today'] == true,
      sunrise: _tryParseDateTime(json['sunrise']),
      sunset: _tryParseDateTime(json['sunset']),
      moonrise: _tryParseDateTime(json['moonrise']),
      moonset: _tryParseDateTime(json['moonset']),
      tithi: (json['tithi'] ?? '').toString(),
      festivals: festivals,
      majorFestivalsCount: (json['major_festivals_count'] as num?)?.toInt() ?? 0,
      vratsCount: (json['vrats_count'] as num?)?.toInt() ?? 0,
      primaryLabel: (json['primary_label'] ?? '').toString(),
      masa: (json['masa'] ?? '').toString(),
      masaIndex: (json['masa_index'] as num?)?.toInt() ?? 0,
    );
  }
}

class PanchangMonthResponse {
  final int year;
  final int month;
  final int startWeekday;
  final int totalDays;
  final String start;
  final String end;
  final String timezone;
  final String locale;
  final String calendarSystem;
  final String profile;
  final List<PanchangDaySummary> days;
  final List<List<PanchangDaySummary?>> grid;

  const PanchangMonthResponse({
    required this.year,
    required this.month,
    required this.startWeekday,
    required this.totalDays,
    required this.start,
    required this.end,
    required this.timezone,
    required this.locale,
    required this.calendarSystem,
    required this.profile,
    required this.days,
    required this.grid,
  });

  factory PanchangMonthResponse.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'];
    final days = daysRaw is List
        ? daysRaw
            .whereType<Map<String, dynamic>>()
            .map(PanchangDaySummary.fromJson)
            .toList()
        : <PanchangDaySummary>[];

    final gridRaw = json['grid'];
    final grid = <List<PanchangDaySummary?>>[];
    if (gridRaw is List) {
      for (final row in gridRaw) {
        if (row is List) {
          final parsedRow = <PanchangDaySummary?>[];
          for (final cell in row) {
            if (cell == null) {
              parsedRow.add(null);
            } else if (cell is Map<String, dynamic>) {
              parsedRow.add(PanchangDaySummary.fromJson(cell));
            } else {
              parsedRow.add(null);
            }
          }
          grid.add(parsedRow);
        }
      }
    }

    return PanchangMonthResponse(
      year: (json['year'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      startWeekday: (json['start_weekday'] as num?)?.toInt() ?? 0,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
      start: (json['start'] ?? '').toString(),
      end: (json['end'] ?? '').toString(),
      timezone: (json['tz'] ?? json['timezone'] ?? '').toString(),
      locale: (json['locale'] ?? '').toString(),
      calendarSystem: (json['calendar_system'] ?? '').toString(),
      profile: (json['profile'] ?? '').toString(),
      days: days,
      grid: grid,
    );
  }
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  return null;
}
