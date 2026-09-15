// lib/features/panchang/domain/entities/panchang_entities.dart
// Pure Dart domain entities for Vedic Panchang, Vrats, Festivals, and Muhurats.

class PanchangLocationEntity {
  final double latitude;
  final double longitude;
  final String timezone;
  final String label;

  const PanchangLocationEntity({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.label = 'New Delhi',
  });
}

class PanchangCoreItemEntity {
  final String name;
  final String? nameHi;
  final int? index;
  final String? paksha;
  final String? endTime;
  final String? remainingTime;

  const PanchangCoreItemEntity({
    required this.name,
    this.nameHi,
    this.index,
    this.paksha,
    this.endTime,
    this.remainingTime,
  });
}

class PanchangSunMoonTimingsEntity {
  final String sunrise;
  final String sunset;
  final String? moonrise;
  final String? moonset;
  final String? solarNoon;

  const PanchangSunMoonTimingsEntity({
    required this.sunrise,
    required this.sunset,
    this.moonrise,
    this.moonset,
    this.solarNoon,
  });
}

class PanchangMuhuratWindowEntity {
  final String name;
  final String? nameHi;
  final String startTime;
  final String endTime;
  final bool isAuspicious;
  final String? planet;
  final String? type;

  const PanchangMuhuratWindowEntity({
    required this.name,
    this.nameHi,
    required this.startTime,
    required this.endTime,
    required this.isAuspicious,
    this.planet,
    this.type,
  });
}

class PanchangDayEntity {
  final String date;
  final PanchangLocationEntity location;
  final PanchangSunMoonTimingsEntity sunMoon;
  final PanchangCoreItemEntity tithi;
  final PanchangCoreItemEntity nakshatra;
  final PanchangCoreItemEntity yoga;
  final PanchangCoreItemEntity karana;
  final String vara;
  final String masaAmanta;
  final String masaPurnimanta;
  final String paksha;
  final String ritu;
  final String moonRashi;
  final List<PanchangMuhuratWindowEntity> auspiciousMuhurats;
  final List<PanchangMuhuratWindowEntity> inauspiciousMuhurats;
  final List<String> festivals;

  const PanchangDayEntity({
    required this.date,
    required this.location,
    required this.sunMoon,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.vara,
    required this.masaAmanta,
    required this.masaPurnimanta,
    required this.paksha,
    required this.ritu,
    required this.moonRashi,
    this.auspiciousMuhurats = const [],
    this.inauspiciousMuhurats = const [],
    this.festivals = const [],
  });
}

class PanchangFestivalEntity {
  final String code;
  final String nameEn;
  final String nameHi;
  final String date;
  final String festivalType;
  final String? description;
  final String? paranRules;
  final bool isMajor;

  const PanchangFestivalEntity({
    required this.code,
    required this.nameEn,
    required this.nameHi,
    required this.date,
    required this.festivalType,
    this.description,
    this.paranRules,
    this.isMajor = false,
  });
}

class PanchangVratEntity {
  final String date;
  final String nameEn;
  final String nameHi;
  final String type;
  final String significance;
  final String? paranTime;
  final List<String> recommendedFoods;
  final List<String> restrictedFoods;

  const PanchangVratEntity({
    required this.date,
    required this.nameEn,
    required this.nameHi,
    required this.type,
    required this.significance,
    this.paranTime,
    this.recommendedFoods = const [],
    this.restrictedFoods = const [],
  });
}

class PanchangGuidanceProfileEntity {
  final String dietStyle;
  final String fastingPreference;
  final String devata;
  final String profile;
  final String locale;
  final Map<String, dynamic> workSchedule;

  const PanchangGuidanceProfileEntity({
    this.dietStyle = 'normal',
    this.fastingPreference = 'none',
    this.devata = 'other',
    this.profile = 'default',
    this.locale = 'en',
    this.workSchedule = const {},
  });
}

class PanchangGuidanceEntity {
  final String date;
  final String fastingType;
  final List<String> recommendedFoods;
  final List<String> restrictedFoods;
  final String ayurvedicRationale;
  final Map<String, dynamic> userDoshaSynergy;
  final List<PanchangMuhuratWindowEntity> timeWindows;

  const PanchangGuidanceEntity({
    required this.date,
    required this.fastingType,
    this.recommendedFoods = const [],
    this.restrictedFoods = const [],
    required this.ayurvedicRationale,
    this.userDoshaSynergy = const {},
    this.timeWindows = const [],
  });
}
