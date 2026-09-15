// lib/features/panchang/domain/entities/kundli_entities.dart
// Pure Dart entities for Vedic Kundli (Natal Horoscope) & Astrological Body Type.

class KundliBirthDetails {
  final String name;
  final String date;
  final String time;
  final double latitude;
  final double longitude;
  final String timezone;
  final String city;
  final String state;
  final double ayanamshaDeg;

  const KundliBirthDetails({
    this.name = '',
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.city = '',
    this.state = '',
    this.ayanamshaDeg = 0.0,
  });
}

class LagnaInfo {
  final String sign;
  final String signEn;
  final double degree;
  final double totalLongitude;
  final String nakshatra;
  final String lord;
  final String element;
  final String dosha;

  const LagnaInfo({
    required this.sign,
    required this.signEn,
    required this.degree,
    required this.totalLongitude,
    required this.nakshatra,
    required this.lord,
    required this.element,
    required this.dosha,
  });
}

class KundliPlanet {
  final String name;
  final double longitude;
  final double degree;
  final String rashi;
  final String rashiEn;
  final int rashiIndex;
  final int house;
  final String nakshatra;
  final int nakshatraPada;
  final String element;
  final String dosha;
  final String guna;

  const KundliPlanet({
    required this.name,
    required this.longitude,
    required this.degree,
    required this.rashi,
    required this.rashiEn,
    required this.rashiIndex,
    required this.house,
    required this.nakshatra,
    required this.nakshatraPada,
    required this.element,
    required this.dosha,
    required this.guna,
  });
}

class KundliBhavaHouse {
  final int house;
  final String rashi;
  final String rashiEn;
  final String lord;
  final String element;
  final List<String> planets;

  const KundliBhavaHouse({
    required this.house,
    required this.rashi,
    required this.rashiEn,
    required this.lord,
    required this.element,
    required this.planets,
  });
}

class DashaPeriod {
  final String lord;
  final String startDate;
  final String endDate;
  final double durationYears;
  final bool isActive;

  const DashaPeriod({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.durationYears,
    required this.isActive,
  });
}

class AstrologicalBodyType {
  final String astrologicalPrakriti;
  final String primaryDosha;
  final String secondaryDosha;
  final double vataScore;
  final double pittaScore;
  final double kaphaScore;
  final String lagnaElement;
  final String lagnaLord;
  final List<String> favorableTastes;
  final List<String> foodsToFavor;
  final List<String> foodsToAvoid;
  final List<String> lifestyle;

  const AstrologicalBodyType({
    required this.astrologicalPrakriti,
    required this.primaryDosha,
    required this.secondaryDosha,
    required this.vataScore,
    required this.pittaScore,
    required this.kaphaScore,
    required this.lagnaElement,
    required this.lagnaLord,
    this.favorableTastes = const [],
    this.foodsToFavor = const [],
    this.foodsToAvoid = const [],
    this.lifestyle = const [],
  });
}

class MangalDoshaReport {
  final bool isManglik;
  final int house;
  final bool isCancelled;
  final String severity;
  final String description;

  const MangalDoshaReport({
    required this.isManglik,
    required this.house,
    required this.isCancelled,
    required this.severity,
    required this.description,
  });
}

class SadeSatiReport {
  final bool isActive;
  final String phase;
  final String description;

  const SadeSatiReport({
    required this.isActive,
    required this.phase,
    required this.description,
  });
}

class KundliEntity {
  final KundliBirthDetails birthDetails;
  final LagnaInfo lagna;
  final String janmaRashi;
  final String janmaRashiEn;
  final String janmaNakshatra;
  final int janmaNakshatraPada;
  final String sunSign;
  final String sunSignEn;
  final List<KundliPlanet> planets;
  final List<KundliBhavaHouse> houses;
  final List<DashaPeriod> dashaTimeline;
  final DashaPeriod? activeDasha;
  final AstrologicalBodyType bodyType;
  final MangalDoshaReport mangalDosha;
  final SadeSatiReport sadeSati;

  const KundliEntity({
    required this.birthDetails,
    required this.lagna,
    required this.janmaRashi,
    required this.janmaRashiEn,
    required this.janmaNakshatra,
    required this.janmaNakshatraPada,
    required this.sunSign,
    required this.sunSignEn,
    required this.planets,
    required this.houses,
    required this.dashaTimeline,
    this.activeDasha,
    required this.bodyType,
    required this.mangalDosha,
    required this.sadeSati,
  });
}
