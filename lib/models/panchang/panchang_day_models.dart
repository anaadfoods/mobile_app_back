import 'panchang_common_models.dart';

class PanchangLunarInfo {
  final String masa;
  final String paksha;
  final int masaIndex;
  final String masaSystem;
  final DateTime? masaBoundary;

  const PanchangLunarInfo({
    required this.masa,
    required this.paksha,
    required this.masaIndex,
    required this.masaSystem,
    required this.masaBoundary,
  });

  factory PanchangLunarInfo.fromJson(Map<String, dynamic> json) {
    return PanchangLunarInfo(
      masa: (json['masa'] ?? '').toString(),
      paksha: (json['paksha'] ?? '').toString(),
      masaIndex: (json['masa_index'] as num?)?.toInt() ?? 0,
      masaSystem: (json['masa_system'] ?? '').toString(),
      masaBoundary: _tryParseDateTime(json['masa_boundary']),
    );
  }
}

class PanchangCorePanchang {
  final String vara;
  final String tithi;
  final DateTime? tithiEnd;
  final String nakshatra;
  final DateTime? nakshatraEnd;
  final String yoga;
  final DateTime? yogaEnd;
  final String karana;
  final DateTime? karanaEnd;
  final String sunRashi;
  final String moonRashi;

  const PanchangCorePanchang({
    required this.vara,
    required this.tithi,
    required this.tithiEnd,
    required this.nakshatra,
    required this.nakshatraEnd,
    required this.yoga,
    required this.yogaEnd,
    required this.karana,
    required this.karanaEnd,
    required this.sunRashi,
    required this.moonRashi,
  });

  factory PanchangCorePanchang.fromJson(Map<String, dynamic> json) {
    return PanchangCorePanchang(
      vara: (json['vara'] ?? '').toString(),
      tithi: (json['tithi'] ?? '').toString(),
      tithiEnd: _tryParseDateTime(json['tithi_end']),
      nakshatra: (json['nakshatra'] ?? '').toString(),
      nakshatraEnd: _tryParseDateTime(json['nakshatra_end']),
      yoga: (json['yoga'] ?? '').toString(),
      yogaEnd: _tryParseDateTime(json['yoga_end']),
      karana: (json['karana'] ?? '').toString(),
      karanaEnd: _tryParseDateTime(json['karana_end']),
      sunRashi: (json['sun_rashi'] ?? '').toString(),
      moonRashi: (json['moon_rashi'] ?? '').toString(),
    );
  }
}

class PanchangSunMoonTimings {
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? solarNoon;
  final DateTime? moonrise;
  final DateTime? moonset;

  const PanchangSunMoonTimings({
    required this.sunrise,
    required this.sunset,
    required this.solarNoon,
    required this.moonrise,
    required this.moonset,
  });

  factory PanchangSunMoonTimings.fromJson(Map<String, dynamic> json) {
    return PanchangSunMoonTimings(
      sunrise: _tryParseDateTime(json['sunrise']),
      sunset: _tryParseDateTime(json['sunset']),
      solarNoon: _tryParseDateTime(json['solar_noon']),
      moonrise: _tryParseDateTime(json['moonrise']),
      moonset: _tryParseDateTime(json['moonset']),
    );
  }
}

class PanchangTransitionItem {
  final int index;
  final String name;
  final DateTime? start;
  final DateTime? end;

  const PanchangTransitionItem({
    required this.index,
    required this.name,
    required this.start,
    required this.end,
  });

  factory PanchangTransitionItem.fromJson(Map<String, dynamic> json) {
    return PanchangTransitionItem(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      start: _tryParseDateTime(json['start']),
      end: _tryParseDateTime(json['end']),
    );
  }
}

class PanchangTransitions {
  final List<PanchangTransitionItem> tithi;
  final List<PanchangTransitionItem> nakshatra;
  final List<PanchangTransitionItem> yoga;
  final List<PanchangTransitionItem> karana;

  const PanchangTransitions({
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
  });

  factory PanchangTransitions.fromJson(Map<String, dynamic> json) {
    List<PanchangTransitionItem> parseList(String key) {
      final raw = json[key];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(PanchangTransitionItem.fromJson)
            .toList();
      }
      return const [];
    }

    return PanchangTransitions(
      tithi: parseList('tithi'),
      nakshatra: parseList('nakshatra'),
      yoga: parseList('yoga'),
      karana: parseList('karana'),
    );
  }
}

class PanchangHoraSlot {
  final DateTime? start;
  final DateTime? end;
  final String planet;

  const PanchangHoraSlot({
    required this.start,
    required this.end,
    required this.planet,
  });

  factory PanchangHoraSlot.fromJson(Map<String, dynamic> json) {
    return PanchangHoraSlot(
      start: _tryParseDateTime(json['start']),
      end: _tryParseDateTime(json['end']),
      planet: (json['planet'] ?? '').toString(),
    );
  }

  /// Dynamically calculate if this hora slot is currently active
  bool get isCurrent {
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return now.isAfter(start!.toLocal()) && now.isBefore(end!.toLocal());
  }
}

class PanchangHora {
  final List<PanchangHoraSlot> slots;

  const PanchangHora({required this.slots});

  factory PanchangHora.fromJson(Map<String, dynamic> json) {
    final raw = json['slots'];
    final slots = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(PanchangHoraSlot.fromJson)
            .toList()
        : <PanchangHoraSlot>[];
    return PanchangHora(slots: slots);
  }
}

class PanchangTimeWindow {
  final DateTime? start;
  final DateTime? end;

  const PanchangTimeWindow({required this.start, required this.end});

  factory PanchangTimeWindow.fromJson(Map<String, dynamic> json) {
    return PanchangTimeWindow(
      start: _tryParseDateTime(json['start']),
      end: _tryParseDateTime(json['end']),
    );
  }

  /// Dynamically calculate if this time window is currently active
  bool get isCurrent {
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return now.isAfter(start!.toLocal()) && now.isBefore(end!.toLocal());
  }
}

class PanchangChoghadiyaSlot {
  final DateTime? start;
  final DateTime? end;
  final String name;

  const PanchangChoghadiyaSlot({
    required this.start,
    required this.end,
    required this.name,
  });

  factory PanchangChoghadiyaSlot.fromJson(Map<String, dynamic> json) {
    return PanchangChoghadiyaSlot(
      start: _tryParseDateTime(json['start']),
      end: _tryParseDateTime(json['end']),
      name: (json['name'] ?? '').toString(),
    );
  }

  /// Dynamically calculate if this choghadiya slot is currently active
  bool get isCurrent {
    if (start == null || end == null) return false;
    final now = DateTime.now();
    return now.isAfter(start!.toLocal()) && now.isBefore(end!.toLocal());
  }
}

class PanchangChoghadiya {
  final List<PanchangChoghadiyaSlot> day;
  final List<PanchangChoghadiyaSlot> night;

  const PanchangChoghadiya({required this.day, required this.night});

  factory PanchangChoghadiya.fromJson(Map<String, dynamic> json) {
    List<PanchangChoghadiyaSlot> parse(String key) {
      final raw = json[key];
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(PanchangChoghadiyaSlot.fromJson)
            .toList();
      }
      return const [];
    }

    return PanchangChoghadiya(
      day: parse('day'),
      night: parse('night'),
    );
  }
}

class PanchangAuspiciousMuhurats {
  final PanchangHora? hora;
  final PanchangTimeWindow? brahma;
  final PanchangTimeWindow? abhijit;
  final PanchangChoghadiya? choghadiya;

  const PanchangAuspiciousMuhurats({
    required this.hora,
    required this.brahma,
    required this.abhijit,
    required this.choghadiya,
  });

  factory PanchangAuspiciousMuhurats.fromJson(Map<String, dynamic> json) {
    return PanchangAuspiciousMuhurats(
      hora: json['hora'] is Map<String, dynamic>
          ? PanchangHora.fromJson(json['hora'] as Map<String, dynamic>)
          : null,
      brahma: json['brahma'] is Map<String, dynamic>
          ? PanchangTimeWindow.fromJson(json['brahma'] as Map<String, dynamic>)
          : null,
      abhijit: json['abhijit'] is Map<String, dynamic>
          ? PanchangTimeWindow.fromJson(json['abhijit'] as Map<String, dynamic>)
          : null,
      choghadiya: json['choghadiya'] is Map<String, dynamic>
          ? PanchangChoghadiya.fromJson(
              json['choghadiya'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class PanchangInauspiciousTimings {
  final PanchangTimeWindow? rahuKaal;
  final PanchangTimeWindow? yamaganda;
  final PanchangTimeWindow? gulika;

  const PanchangInauspiciousTimings({
    required this.rahuKaal,
    required this.yamaganda,
    required this.gulika,
  });

  factory PanchangInauspiciousTimings.fromJson(Map<String, dynamic> json) {
    PanchangTimeWindow? maybeWindow(String key) {
      final raw = json[key];
      if (raw is Map<String, dynamic>) {
        return PanchangTimeWindow.fromJson(raw);
      }
      return null;
    }

    return PanchangInauspiciousTimings(
      rahuKaal: maybeWindow('rahu_kaal'),
      yamaganda: maybeWindow('yamaganda'),
      gulika: maybeWindow('gulika'),
    );
  }
}

class PanchangDayResponse {
  final String date;
  final String timezone;
  final String locale;
  final String calendarSystem;
  final String profile;
  final String? calcVersion;
  final String? coreCalcNote;
  final PanchangLocation location;
  final PanchangCorePanchang corePanchang;
  final PanchangLunarInfo lunar;
  final PanchangSunMoonTimings sunMoonTimings;
  final PanchangAuspiciousMuhurats? auspiciousMuhurats;
  final PanchangInauspiciousTimings? inauspiciousTimings;
  final PanchangTransitions? transitions;
  final List<PanchangFestivalItem> festivals;

  const PanchangDayResponse({
    required this.date,
    required this.timezone,
    required this.locale,
    required this.calendarSystem,
    required this.profile,
    required this.calcVersion,
    required this.coreCalcNote,
    required this.location,
    required this.corePanchang,
    required this.lunar,
    required this.sunMoonTimings,
    required this.auspiciousMuhurats,
    required this.inauspiciousTimings,
    required this.transitions,
    required this.festivals,
  });

  factory PanchangDayResponse.fromJson(Map<String, dynamic> json) {
    final festivalsRaw = json['festivals'];
    final festivals = festivalsRaw is List
        ? festivalsRaw
            .whereType<Map<String, dynamic>>()
            .map(PanchangFestivalItem.fromJson)
            .toList()
        : <PanchangFestivalItem>[];

    return PanchangDayResponse(
      date: (json['date'] ?? '').toString(),
      timezone: (json['timezone'] ?? json['tz'] ?? '').toString(),
      locale: (json['locale'] ?? '').toString(),
      calendarSystem: (json['calendar_system'] ?? '').toString(),
      profile: (json['profile'] ?? '').toString(),
      calcVersion: json['calc_version']?.toString(),
      coreCalcNote: json['core_calc_note']?.toString(),
      location: json['location'] is Map<String, dynamic>
          ? PanchangLocation.fromJson(json['location'] as Map<String, dynamic>)
          : const PanchangLocation(label: '', latitude: null, longitude: null),
      corePanchang: json['core_panchang'] is Map<String, dynamic>
          ? PanchangCorePanchang.fromJson(
              json['core_panchang'] as Map<String, dynamic>,
            )
          : const PanchangCorePanchang(
              vara: '',
              tithi: '',
              tithiEnd: null,
              nakshatra: '',
              nakshatraEnd: null,
              yoga: '',
              yogaEnd: null,
              karana: '',
              karanaEnd: null,
              sunRashi: '',
              moonRashi: '',
            ),
      lunar: json['lunar'] is Map<String, dynamic>
          ? PanchangLunarInfo.fromJson(json['lunar'] as Map<String, dynamic>)
          : const PanchangLunarInfo(
              masa: '',
              paksha: '',
              masaIndex: 0,
              masaSystem: '',
              masaBoundary: null,
            ),
      sunMoonTimings: json['sun_moon_timings'] is Map<String, dynamic>
          ? PanchangSunMoonTimings.fromJson(
              json['sun_moon_timings'] as Map<String, dynamic>,
            )
          : const PanchangSunMoonTimings(
              sunrise: null,
              sunset: null,
              solarNoon: null,
              moonrise: null,
              moonset: null,
            ),
      auspiciousMuhurats: json['auspicious_muhurats'] is Map<String, dynamic>
          ? PanchangAuspiciousMuhurats.fromJson(
              json['auspicious_muhurats'] as Map<String, dynamic>,
            )
          : null,
      inauspiciousTimings: json['inauspicious_timings'] is Map<String, dynamic>
          ? PanchangInauspiciousTimings.fromJson(
              json['inauspicious_timings'] as Map<String, dynamic>,
            )
          : null,
      transitions: json['transitions'] is Map<String, dynamic>
          ? PanchangTransitions.fromJson(
              json['transitions'] as Map<String, dynamic>,
            )
          : null,
      festivals: festivals,
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
