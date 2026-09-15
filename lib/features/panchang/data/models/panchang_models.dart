// lib/features/panchang/data/models/panchang_models.dart
import '../../domain/entities/panchang_entities.dart';

class PanchangDayModel {
  static PanchangDayEntity fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final sunMoon = json['sun_moon_timings'] as Map<String, dynamic>? ?? {};
    final core = json['core_panchang'] as Map<String, dynamic>? ?? {};
    final lunar = json['lunar'] as Map<String, dynamic>? ?? {};
    final auspicious = json['auspicious_muhurats'] as Map<String, dynamic>? ?? {};
    final inauspicious = json['inauspicious_timings'] as Map<String, dynamic>? ?? {};

    // Note: User requested to map nakshatra_pada and nakshatra_lord, but PanchangCoreItemEntity
    // does not have these fields, so they are extracted here but not passed into the entity.
    final nakshatraPada = (core['nakshatra_pada'] as num?)?.toInt();
    final nakshatraLord = core['nakshatra_lord']?.toString();

    return PanchangDayEntity(
      date: json['date']?.toString() ?? '',
      location: PanchangLocationEntity(
        latitude: (loc['latitude'] as num?)?.toDouble() ?? 28.6139,
        longitude: (loc['longitude'] as num?)?.toDouble() ?? 77.2090,
        timezone: loc['timezone']?.toString() ?? 'Asia/Kolkata',
        label: loc['label']?.toString() ?? 'New Delhi',
      ),
      sunMoon: PanchangSunMoonTimingsEntity(
        sunrise: sunMoon['sunrise']?.toString() ?? '--:--',
        sunset: sunMoon['sunset']?.toString() ?? '--:--',
        moonrise: sunMoon['moonrise']?.toString(),
        moonset: sunMoon['moonset']?.toString(),
        solarNoon: sunMoon['solar_noon']?.toString(),
      ),
      tithi: PanchangCoreItemEntity(
        name: core['tithi']?.toString() ?? '',
        index: (core['tithi_index'] as num?)?.toInt(),
        endTime: core['tithi_end']?.toString(),
      ),
      nakshatra: PanchangCoreItemEntity(
        name: core['nakshatra']?.toString() ?? '',
        index: (core['nakshatra_index'] as num?)?.toInt(),
        endTime: core['nakshatra_end']?.toString(),
      ),
      yoga: PanchangCoreItemEntity(
        name: core['yoga']?.toString() ?? '',
        endTime: core['yoga_end']?.toString(),
      ),
      karana: PanchangCoreItemEntity(
        name: core['karana']?.toString() ?? '',
        endTime: core['karana_end']?.toString(),
      ),
      vara: core['vara']?.toString() ?? '',
      masaAmanta: lunar['masa']?.toString() ?? '',
      masaPurnimanta: '',
      paksha: lunar['paksha']?.toString() ?? '',
      ritu: '',
      moonRashi: core['moon_rashi']?.toString() ?? '',
      auspiciousMuhurats: [
        if (auspicious['abhijit'] != null)
          PanchangMuhuratWindowEntity(
            name: 'Abhijit Muhurat',
            startTime: auspicious['abhijit']['start']?.toString() ?? '',
            endTime: auspicious['abhijit']['end']?.toString() ?? '',
            isAuspicious: true,
          ),
        if (auspicious['brahma'] != null)
          PanchangMuhuratWindowEntity(
            name: 'Brahma Muhurat',
            startTime: auspicious['brahma']['start']?.toString() ?? '',
            endTime: auspicious['brahma']['end']?.toString() ?? '',
            isAuspicious: true,
          ),
      ],
      inauspiciousMuhurats: [
        if (inauspicious['rahu_kaal'] != null)
          PanchangMuhuratWindowEntity(
            name: 'Rahu Kaal',
            startTime: inauspicious['rahu_kaal']['start']?.toString() ?? '',
            endTime: inauspicious['rahu_kaal']['end']?.toString() ?? '',
            isAuspicious: false,
          ),
        if (inauspicious['yamaganda'] != null)
          PanchangMuhuratWindowEntity(
            name: 'Yamaganda',
            startTime: inauspicious['yamaganda']['start']?.toString() ?? '',
            endTime: inauspicious['yamaganda']['end']?.toString() ?? '',
            isAuspicious: false,
          ),
        if (inauspicious['gulika'] != null)
          PanchangMuhuratWindowEntity(
            name: 'Gulika',
            startTime: inauspicious['gulika']['start']?.toString() ?? '',
            endTime: inauspicious['gulika']['end']?.toString() ?? '',
            isAuspicious: false,
          ),
      ],
      festivals: (json['festivals'] as List<dynamic>?)
              ?.map((f) => (f is Map) ? (f['name']?.toString() ?? '') : f.toString())
              .toList() ??
          [],
    );
  }
}

class PanchangFestivalModel {
  static PanchangFestivalEntity fromJson(Map<String, dynamic> json) {
    return PanchangFestivalEntity(
      code: json['code']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? json['name']?.toString() ?? '',
      nameHi: json['name_hi']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      festivalType: json['festival_type']?.toString() ?? 'festival',
      description: json['description_en']?.toString() ?? json['description']?.toString(),
      paranRules: json['paran_rules']?.toString(),
      isMajor: json['is_major'] == true,
    );
  }
}

class PanchangVratModel {
  static PanchangVratEntity fromJson(Map<String, dynamic> json) {
    return PanchangVratEntity(
      date: json['date']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? json['name']?.toString() ?? '',
      nameHi: json['name_hi']?.toString() ?? '',
      type: json['type']?.toString() ?? 'vrat',
      significance: json['significance']?.toString() ?? '',
      paranTime: json['paran_time']?.toString(),
      recommendedFoods: (json['recommended_foods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      restrictedFoods: (json['restricted_foods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
