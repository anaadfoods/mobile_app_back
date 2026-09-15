// lib/features/panchang/data/models/kundli_models.dart
import '../../domain/entities/kundli_entities.dart';

class KundliModel {
  static KundliEntity fromJson(Map<String, dynamic> json) {
    final birthMap = json['birth_details'] as Map<String, dynamic>? ?? {};
    final lagnaMap = json['lagna'] as Map<String, dynamic>? ?? {};
    final planetsList = json['planets'] as List<dynamic>? ?? [];
    final housesList = json['houses'] as List<dynamic>? ?? [];
    final dashasMap = json['dashas'] as Map<String, dynamic>? ?? {};
    final bodyTypeMap = json['body_type'] as Map<String, dynamic>? ?? {};
    final doshaProfileMap = json['dosha_profile'] as Map<String, dynamic>? ?? {};
    final mangalMap = doshaProfileMap['mangal_dosha'] as Map<String, dynamic>? ?? {};
    final sadeSatiMap = doshaProfileMap['sade_sati'] as Map<String, dynamic>? ?? {};

    return KundliEntity(
      birthDetails: KundliBirthDetails(
        name: json['name'] as String? ?? json['kundli_person_name'] as String? ?? '',
        date: birthMap['date']?.toString() ?? '',
        time: birthMap['time']?.toString() ?? '',
        latitude: (birthMap['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (birthMap['longitude'] as num?)?.toDouble() ?? 0.0,
        timezone: birthMap['timezone']?.toString() ?? 'Asia/Kolkata',
        ayanamshaDeg: (birthMap['ayanamsha_deg'] as num?)?.toDouble() ?? 0.0,
      ),
      lagna: LagnaInfo(
        sign: lagnaMap['sign']?.toString() ?? '',
        signEn: lagnaMap['sign_en']?.toString() ?? '',
        degree: (lagnaMap['degree'] as num?)?.toDouble() ?? 0.0,
        totalLongitude: (lagnaMap['total_longitude'] as num?)?.toDouble() ?? 0.0,
        nakshatra: lagnaMap['nakshatra']?.toString() ?? '',
        lord: lagnaMap['lord']?.toString() ?? '',
        element: lagnaMap['element']?.toString() ?? '',
        dosha: lagnaMap['dosha']?.toString() ?? '',
      ),
      janmaRashi: json['janma_rashi']?.toString() ?? '',
      janmaRashiEn: json['janma_rashi_en']?.toString() ?? '',
      janmaNakshatra: json['janma_nakshatra']?.toString() ?? '',
      janmaNakshatraPada: (json['janma_nakshatra_pada'] as num?)?.toInt() ?? 1,
      sunSign: json['sun_sign']?.toString() ?? '',
      sunSignEn: json['sun_sign_en']?.toString() ?? '',
      planets: planetsList.map((p) {
        final pm = p as Map<String, dynamic>;
        return KundliPlanet(
          name: pm['name']?.toString() ?? '',
          longitude: (pm['longitude'] as num?)?.toDouble() ?? 0.0,
          degree: (pm['degree'] as num?)?.toDouble() ?? 0.0,
          rashi: pm['rashi']?.toString() ?? '',
          rashiEn: pm['rashi_en']?.toString() ?? '',
          rashiIndex: (pm['rashi_index'] as num?)?.toInt() ?? 0,
          house: (pm['house'] as num?)?.toInt() ?? 1,
          nakshatra: pm['nakshatra']?.toString() ?? '',
          nakshatraPada: (pm['nakshatra_pada'] as num?)?.toInt() ?? 1,
          element: pm['element']?.toString() ?? '',
          dosha: pm['dosha']?.toString() ?? '',
          guna: pm['guna']?.toString() ?? '',
        );
      }).toList(),
      houses: housesList.map((h) {
        final hm = h as Map<String, dynamic>;
        return KundliBhavaHouse(
          house: (hm['house'] as num?)?.toInt() ?? 1,
          rashi: hm['rashi']?.toString() ?? '',
          rashiEn: hm['rashi_en']?.toString() ?? '',
          lord: hm['lord']?.toString() ?? '',
          element: hm['element']?.toString() ?? '',
          planets: (hm['planets'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        );
      }).toList(),
      dashaTimeline: (dashasMap['timeline'] as List<dynamic>?)?.map((d) {
        final dm = d as Map<String, dynamic>;
        return DashaPeriod(
          lord: dm['lord']?.toString() ?? '',
          startDate: dm['start_date']?.toString() ?? '',
          endDate: dm['end_date']?.toString() ?? '',
          durationYears: (dm['duration_years'] as num?)?.toDouble() ?? 0.0,
          isActive: dm['is_active'] == true,
        );
      }).toList() ?? [],
      activeDasha: dashasMap['active_dasha'] != null
          ? DashaPeriod(
              lord: (dashasMap['active_dasha'] as Map<String, dynamic>)['lord']?.toString() ?? '',
              startDate: (dashasMap['active_dasha'] as Map<String, dynamic>)['start_date']?.toString() ?? '',
              endDate: (dashasMap['active_dasha'] as Map<String, dynamic>)['end_date']?.toString() ?? '',
              durationYears: ((dashasMap['active_dasha'] as Map<String, dynamic>)['duration_years'] as num?)?.toDouble() ?? 0.0,
              isActive: true,
            )
          : null,
      bodyType: AstrologicalBodyType(
        astrologicalPrakriti: bodyTypeMap['astrological_prakriti']?.toString() ?? '',
        primaryDosha: bodyTypeMap['primary_dosha']?.toString() ?? 'VATA',
        secondaryDosha: bodyTypeMap['secondary_dosha']?.toString() ?? 'PITTA',
        vataScore: (bodyTypeMap['vata_score'] as num?)?.toDouble() ?? 0.0,
        pittaScore: (bodyTypeMap['pitta_score'] as num?)?.toDouble() ?? 0.0,
        kaphaScore: (bodyTypeMap['kapha_score'] as num?)?.toDouble() ?? 0.0,
        lagnaElement: bodyTypeMap['lagna_element']?.toString() ?? '',
        lagnaLord: bodyTypeMap['lagna_lord']?.toString() ?? '',
        favorableTastes: (bodyTypeMap['dietary_guidance']?['favorable_tastes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        foodsToFavor: (bodyTypeMap['dietary_guidance']?['foods_to_favor'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        foodsToAvoid: (bodyTypeMap['dietary_guidance']?['foods_to_avoid'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        lifestyle: (bodyTypeMap['dietary_guidance']?['lifestyle'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      ),
      mangalDosha: MangalDoshaReport(
        isManglik: mangalMap['is_manglik'] == true,
        house: (mangalMap['house'] as num?)?.toInt() ?? 0,
        isCancelled: mangalMap['is_cancelled'] == true,
        severity: mangalMap['severity']?.toString() ?? 'NONE',
        description: mangalMap['description']?.toString() ?? '',
      ),
      sadeSati: SadeSatiReport(
        isActive: sadeSatiMap['is_active'] == true,
        phase: sadeSatiMap['phase']?.toString() ?? 'INACTIVE',
        description: sadeSatiMap['description']?.toString() ?? '',
      ),
    );
  }
}
