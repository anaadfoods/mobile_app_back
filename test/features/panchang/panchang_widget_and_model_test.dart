import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/models/panchang/panchang_day_models.dart';
import 'package:grocery_app/features/panchang/presentation/widgets/planetary_positions_card.dart';
import 'package:grocery_app/features/panchang/presentation/widgets/daily_muhurta_timeline_card.dart';
import 'package:grocery_app/features/panchang/presentation/widgets/panchang_insight_card.dart';
import 'package:grocery_app/features/panchang/presentation/widgets/ayurvedic_guidance_card.dart';
import 'package:grocery_app/features/panchang/presentation/widgets/personalized_recommendations_card.dart';
import 'package:flutter/material.dart';

void main() {
  group('Panchang Day Models & Deserialization Tests', () {
    test('PanchangDayResponse correctly parses sidereal astronomy, planets, and validation', () {
      final json = {
        'date': '2026-08-18',
        'timezone': 'Asia/Kolkata',
        'calc_version': 'v18',
        'location': {
          'label': 'New Delhi, India',
          'latitude': 28.6139,
          'longitude': 77.2090,
        },
        'core_panchang': {
          'vara': 'Tuesday',
          'tithi': 'Shashthi',
          'tithi_index': 5,
          'nakshatra': 'Swati',
          'nakshatra_index': 14,
          'nakshatra_pada': 1,
          'nakshatra_lord': 'Rahu',
          'yoga': 'Shukla',
          'yoga_index': 23,
          'karana': 'Taitila',
          'karana_index': 11,
          'sun_rashi': 'Leo',
          'sun_rashi_index': 4,
          'moon_rashi': 'Libra',
          'moon_rashi_index': 6,
        },
        'lunar': {
          'masa': 'Shravana',
          'paksha': 'Shukla',
          'masa_index': 4,
          'masa_system': 'amanta',
        },
        'sun_moon_timings': {
          'sunrise': '2026-08-18T05:52:07+05:30',
          'sunset': '2026-08-18T18:57:37+05:30',
          'solar_noon': '2026-08-18T12:25:08+05:30',
        },
        'auspicious_muhurats': {
          'brahma': {
            'start': '2026-08-18T04:16:07+05:30',
            'end': '2026-08-18T05:04:07+05:30',
          },
          'abhijit': {
            'start': '2026-08-18T12:00:00+05:30',
            'end': '2026-08-18T12:50:00+05:30',
          },
        },
        'inauspicious_timings': {
          'rahu_kaal': {
            'start': '2026-08-18T15:45:00+05:30',
            'end': '2026-08-18T17:21:00+05:30',
          },
          'yamaganda': {
            'start': '2026-08-18T09:08:00+05:30',
            'end': '2026-08-18T10:45:00+05:30',
          },
          'gulika': {
            'start': '2026-08-18T12:25:00+05:30',
            'end': '2026-08-18T14:05:00+05:30',
          },
        },
        'planets': {
          'Sun': {
            'name': 'Sun',
            'rashi': 'Simha',
            'rashi_en': 'Leo',
            'rashi_index': 4,
            'degree_in_rashi': 0.51,
            'formatted': 'Leo 0°30′',
            'is_retrograde': false,
            'nakshatra': 'Magha',
            'nakshatra_pada': 1,
          },
          'Moon': {
            'name': 'Moon',
            'rashi': 'Tula',
            'rashi_en': 'Libra',
            'rashi_index': 6,
            'degree_in_rashi': 6.76,
            'formatted': 'Libra 6°45′',
            'is_retrograde': false,
            'nakshatra': 'Swati',
            'nakshatra_pada': 1,
          },
        },
        'validation': {
          'status': 'PASS',
          'is_valid': true,
          'checks_run': 7,
          'errors': [],
        },
        'astronomical': {
          'sun_longitude_sidereal': 120.5061,
          'moon_longitude_sidereal': 186.7592,
          'sun_longitude_tropical': 144.7342,
          'moon_longitude_tropical': 210.9873,
          'ayanamsha_deg': 24.2281,
          'julian_day': 2461270.5,
          'coordinate_system': 'Lahiri Sidereal (NASA JPL DE421)',
        },
      };

      final day = PanchangDayResponse.fromJson(json);

      expect(day.date, '2026-08-18');
      expect(day.calcVersion, 'v18');
      expect(day.corePanchang.vara, 'Tuesday');
      expect(day.corePanchang.tithi, 'Shashthi');
      expect(day.corePanchang.nakshatra, 'Swati');
      expect(day.corePanchang.nakshatraPada, 1);
      expect(day.corePanchang.nakshatraLord, 'Rahu');
      expect(day.corePanchang.yoga, 'Shukla');
      expect(day.corePanchang.karana, 'Taitila');
      expect(day.corePanchang.moonRashi, 'Libra');
      expect(day.corePanchang.sunRashi, 'Leo');

      // Planets
      expect(day.planets, isNotNull);
      expect(day.planets!['Moon']!.formatted, 'Libra 6°45′');
      expect(day.planets!['Sun']!.formatted, 'Leo 0°30′');

      // Validation
      expect(day.validation, isNotNull);
      expect(day.validation!.isValid, true);
      expect(day.validation!.status, 'PASS');

      // Astronomical
      expect(day.astronomical, isNotNull);
      expect(day.astronomical!.ayanamshaDeg, 24.2281);
    });
  });

  group('Panchang Widget Smoke Tests', () {
    final sampleDay = PanchangDayResponse.fromJson({
      'date': '2026-08-18',
      'timezone': 'Asia/Kolkata',
      'location': {'label': 'Delhi', 'latitude': 28.6139, 'longitude': 77.2090},
      'core_panchang': {
        'vara': 'Tuesday',
        'tithi': 'Shashthi',
        'nakshatra': 'Swati',
        'yoga': 'Shukla',
        'karana': 'Taitila',
        'sun_rashi': 'Leo',
        'moon_rashi': 'Libra',
      },
      'lunar': {'masa': 'Shravana', 'paksha': 'Shukla'},
      'sun_moon_timings': {
        'sunrise': '2026-08-18T05:52:07+05:30',
        'sunset': '2026-08-18T18:57:37+05:30',
        'solar_noon': '2026-08-18T12:25:08+05:30',
      },
      'auspicious_muhurats': {
        'brahma': {'start': '2026-08-18T04:16:00+05:30', 'end': '2026-08-18T05:04:00+05:30'},
        'abhijit': {'start': '2026-08-18T12:00:00+05:30', 'end': '2026-08-18T12:50:00+05:30'},
      },
      'inauspicious_timings': {
        'rahu_kaal': {'start': '2026-08-18T15:45:00+05:30', 'end': '2026-08-18T17:21:00+05:30'},
      },
      'planets': {
        'Moon': {
          'name': 'Moon',
          'rashi': 'Tula',
          'rashi_en': 'Libra',
          'formatted': 'Libra 6°45′',
          'degree_in_rashi': 6.76,
          'is_retrograde': false,
          'nakshatra': 'Swati',
          'nakshatra_pada': 1,
        },
      },
    });

    testWidgets('PlanetaryPositionsCard renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanetaryPositionsCard(
              planets: sampleDay.planets!,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Planetary Positions (Graha Sthiti)'), findsOneWidget);
      expect(find.text('Moon'), findsOneWidget);
      expect(find.text('Libra 6°45′'), findsOneWidget);
    });

    testWidgets('DailyMuhurtaTimelineCard renders chronological nodes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DailyMuhurtaTimelineCard(
                day: sampleDay,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Daily Muhurta Timeline'), findsOneWidget);
      expect(find.text('Brahma Muhurta'), findsOneWidget);
      expect(find.text('Sunrise (Surya Udaya)'), findsOneWidget);
    });

    testWidgets('PanchangInsightCard renders AI astrological insight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PanchangInsightCard(
                day: sampleDay,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Today\'s Astrological Insight'), findsOneWidget);
      expect(find.textContaining('Swati Nakshatra'), findsOneWidget);
    });

    testWidgets('AyurvedicGuidanceCard renders food favor/avoid lists', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AyurvedicGuidanceCard(
                day: sampleDay,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Today\'s Ayurvedic Guidance'), findsOneWidget);
      expect(find.text('Foods to Favor'), findsOneWidget);
      expect(find.text('Foods to Avoid'), findsOneWidget);
    });

    testWidgets('PersonalizedRecommendationsCard renders Anaad products', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PersonalizedRecommendationsCard(
                day: sampleDay,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Personalized Diet & Product Guidance'), findsOneWidget);
      expect(find.text('Organic A2 Desi Gir Cow Bilona Ghee'), findsOneWidget);
    });
  });
}
