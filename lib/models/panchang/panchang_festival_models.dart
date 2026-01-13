import 'panchang_common_models.dart';

/// Response model for festivals list API
class PanchangFestivalsResponse {
  final List<FestivalDateGroup> festivals;
  final FestivalsMetadata metadata;

  const PanchangFestivalsResponse({
    required this.festivals,
    required this.metadata,
  });

  factory PanchangFestivalsResponse.fromJson(Map<String, dynamic> json) {
    // API returns flat list of items, we need to group by date
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    
    // Group festivals by date
    final Map<String, List<FestivalEntry>> groupedByDate = {};
    for (var item in itemsJson) {
      if (item is Map<String, dynamic>) {
        final date = (item['date'] ?? '').toString();
        // Preserve optional fields like name_hi/name_en/description/etc.
        final entry = FestivalEntry.fromJson(item);
        
        if (!groupedByDate.containsKey(date)) {
          groupedByDate[date] = [];
        }
        groupedByDate[date]!.add(entry);
      }
    }
    
    // Convert grouped map to list of FestivalDateGroup
    final festivals = groupedByDate.entries.map((entry) {
      return FestivalDateGroup(
        date: entry.key,
        dayOfWeek: '', // Not provided by API
        tithi: '', // Not provided by API
        festivals: entry.value,
      );
    }).toList();
    
    // Sort by date
    festivals.sort((a, b) => a.date.compareTo(b.date));
    
    return PanchangFestivalsResponse(
      festivals: festivals,
      metadata: FestivalsMetadata(
        startDate: json['start']?.toString(),
        endDate: json['end']?.toString(),
        totalFestivals: itemsJson.length,
        totalDays: groupedByDate.length,
      ),
    );
  }
}

/// Groups festivals by date
class FestivalDateGroup {
  final String date;
  final String dayOfWeek;
  final String tithi;
  final String? masa;
  final String? paksha;
  final List<FestivalEntry> festivals;

  const FestivalDateGroup({
    required this.date,
    required this.dayOfWeek,
    required this.tithi,
    this.masa,
    this.paksha,
    required this.festivals,
  });

  factory FestivalDateGroup.fromJson(Map<String, dynamic> json) {
    final festivalsJson = json['festivals'] as List<dynamic>? ?? [];
    return FestivalDateGroup(
      date: (json['date'] ?? '').toString(),
      dayOfWeek: (json['day_of_week'] ?? '').toString(),
      tithi: (json['tithi'] ?? '').toString(),
      masa: json['masa']?.toString(),
      paksha: json['paksha']?.toString(),
      festivals: festivalsJson
          .map((e) => FestivalEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
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
}

/// Individual festival entry with full details
class FestivalEntry {
  final String name;
  final String? nameEn;
  final String? nameHi;
  final String type;
  final String source;
  final String? code;
  final String? description;
  final String? significance;
  final List<String>? rituals;
  final String? category;
  final bool isNationalHoliday;
  final bool isRegionalHoliday;
  final String? region;

  const FestivalEntry({
    required this.name,
    this.nameEn,
    this.nameHi,
    required this.type,
    required this.source,
    this.code,
    this.description,
    this.significance,
    this.rituals,
    this.category,
    this.isNationalHoliday = false,
    this.isRegionalHoliday = false,
    this.region,
  });

  factory FestivalEntry.fromJson(Map<String, dynamic> json) {
    List<String>? rituals;
    if (json['rituals'] != null) {
      rituals = (json['rituals'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return FestivalEntry(
      name: (json['name'] ?? '').toString(),
      nameEn: json['name_en']?.toString(),
      nameHi: json['name_hi']?.toString(),
      type: (json['type'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
      significance: json['significance']?.toString(),
      rituals: rituals,
      category: json['category']?.toString(),
      isNationalHoliday: json['is_national_holiday'] == true,
      isRegionalHoliday: json['is_regional_holiday'] == true,
      region: json['region']?.toString(),
    );
  }

  /// Convert to PanchangFestivalItem for compatibility
  PanchangFestivalItem toFestivalItem() {
    return PanchangFestivalItem(
      name: name,
      nameEn: nameEn,
      nameHi: nameHi,
      type: type,
      source: source,
      code: code,
    );
  }
}

/// Metadata for festivals response
class FestivalsMetadata {
  final String? startDate;
  final String? endDate;
  final int totalFestivals;
  final int totalDays;
  final String? locale;
  final String? timezone;

  const FestivalsMetadata({
    this.startDate,
    this.endDate,
    this.totalFestivals = 0,
    this.totalDays = 0,
    this.locale,
    this.timezone,
  });

  factory FestivalsMetadata.fromJson(Map<String, dynamic> json) {
    return FestivalsMetadata(
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      totalFestivals: (json['total_festivals'] as num?)?.toInt() ?? 0,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
      locale: json['locale']?.toString(),
      timezone: json['timezone']?.toString(),
    );
  }
}

/// Response model for festival search API
class FestivalSearchResponse {
  final List<FestivalSearchResult> results;
  final SearchMetadata metadata;

  const FestivalSearchResponse({
    required this.results,
    required this.metadata,
  });

  factory FestivalSearchResponse.fromJson(Map<String, dynamic> json) {
    // API returns 'items' not 'results'
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    
    return FestivalSearchResponse(
      results: itemsJson
          .map((e) => FestivalSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: SearchMetadata(
        query: json['q']?.toString() ?? '',
        year: json['year'] as int?,
        month: json['month'] as int?,
        totalResults: json['count'] as int? ?? itemsJson.length,
      ),
    );
  }
}

/// Search result item
class FestivalSearchResult {
  final String name;
  final String type;
  final String source;
  final String? code;
  final String date;

  const FestivalSearchResult({
    required this.name,
    required this.type,
    required this.source,
    this.code,
    required this.date,
  });

  factory FestivalSearchResult.fromJson(Map<String, dynamic> json) {
    return FestivalSearchResult(
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      code: json['code']?.toString(),
      date: (json['date'] ?? '').toString(),
    );
  }

  // Helper to parse date
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

  // Keep for backward compatibility but not used in actual API
  String? get description => null;
  String? get category => null;
  List<FestivalOccurrence> get occurrences => [];
}

/// Festival occurrence (date when festival happens)
class FestivalOccurrence {
  final String date;
  final String? dayOfWeek;
  final String? tithi;

  const FestivalOccurrence({
    required this.date,
    this.dayOfWeek,
    this.tithi,
  });

  factory FestivalOccurrence.fromJson(Map<String, dynamic> json) {
    return FestivalOccurrence(
      date: (json['date'] ?? '').toString(),
      dayOfWeek: json['day_of_week']?.toString(),
      tithi: json['tithi']?.toString(),
    );
  }

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
}

/// Metadata for search response
class SearchMetadata {
  final String? query;
  final int? year;
  final int? month;
  final int totalResults;

  const SearchMetadata({
    this.query,
    this.year,
    this.month,
    this.totalResults = 0,
  });

  factory SearchMetadata.fromJson(Map<String, dynamic> json) {
    return SearchMetadata(
      query: json['q']?.toString() ?? json['query']?.toString(),
      year: json['year'] as int?,
      month: json['month'] as int?,
      totalResults: (json['count'] as num?)?.toInt() ?? 
                   (json['total_results'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Festival type enum for filtering
enum FestivalType {
  hindu('hindu', 'Hindu', 0xFFFF9933),
  national('national', 'National', 0xFF138808),
  regional('regional', 'Regional', 0xFF6B4EFF),
  vrat('vrat', 'Vrat/Fast', 0xFF66D9FF),
  purnima('purnima', 'Purnima', 0xFFFFD700),
  amavasya('amavasya', 'Amavasya', 0xFF9C27B0),
  ekadashi('ekadashi', 'Ekadashi', 0xFF4CAF50),
  jayanti('jayanti', 'Jayanti', 0xFFE91E63),
  all('all', 'All Festivals', 0xFF607D8B);

  final String value;
  final String label;
  final int colorValue;

  const FestivalType(this.value, this.label, this.colorValue);

  static FestivalType fromString(String value) {
    return FestivalType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => FestivalType.all,
    );
  }
}
