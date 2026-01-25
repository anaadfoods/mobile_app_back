/// Response model for highlights API
class PanchangHighlightsResponse {
  final int year;
  final int month;
  final String startDate;
  final String endDate;
  final String timezone;
  final String locale;
  final String calendarSystem;
  final String profile;
  final List<HighlightItem> items;

  const PanchangHighlightsResponse({
    required this.year,
    required this.month,
    required this.startDate,
    required this.endDate,
    required this.timezone,
    required this.locale,
    required this.calendarSystem,
    required this.profile,
    required this.items,
  });

  factory PanchangHighlightsResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    
    return PanchangHighlightsResponse(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      startDate: (json['start'] ?? '').toString(),
      endDate: (json['end'] ?? '').toString(),
      timezone: (json['tz'] ?? 'Asia/Kolkata').toString(),
      locale: (json['locale'] ?? 'en').toString(),
      calendarSystem: (json['calendar_system'] ?? 'amanta').toString(),
      profile: (json['profile'] ?? 'default').toString(),
      items: itemsJson
          .map((e) => HighlightItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Individual highlight item (one main festival per day)
class HighlightItem {
  final String date;
  final String name;
  final String type;
  final String source;
  final String? code;

  const HighlightItem({
    required this.date,
    required this.name,
    required this.type,
    required this.source,
    this.code,
  });

  factory HighlightItem.fromJson(Map<String, dynamic> json) {
    return HighlightItem(
      date: (json['date'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'festival').toString(),
      source: (json['source'] ?? '').toString(),
      code: json['code']?.toString(),
    );
  }

  /// Parse date string to DateTime
  DateTime? get dateTime {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Format date for display (e.g., "Jan 14")
  String get formattedDate {
    final dt = dateTime;
    if (dt == null) return date;
    
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month]} ${dt.day}';
  }

  /// Check if this highlight is upcoming (today or future)
  bool get isUpcoming {
    final dt = dateTime;
    if (dt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dt.isAtSameMomentAs(today) || dt.isAfter(today);
  }
}
