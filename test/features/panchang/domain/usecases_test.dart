// test/features/panchang/domain/usecases_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/panchang/domain/entities/kundli_entities.dart';
import 'package:grocery_app/features/panchang/domain/entities/panchang_entities.dart';
import 'package:grocery_app/features/panchang/domain/repositories/kundli_repository.dart';
import 'package:grocery_app/features/panchang/domain/repositories/panchang_repository.dart';
import 'package:grocery_app/features/panchang/domain/usecases/get_user_kundli_use_case.dart';
import 'package:grocery_app/features/panchang/domain/usecases/generate_kundli_use_case.dart';
import 'package:grocery_app/features/panchang/domain/usecases/get_birth_details_use_case.dart';
import 'package:grocery_app/features/panchang/domain/usecases/save_birth_details_use_case.dart';
import 'package:grocery_app/features/panchang/domain/usecases/get_panchang_day_use_case.dart';
import 'package:grocery_app/features/panchang/domain/usecases/get_today_guidance_use_case.dart';

class MockKundliRepository extends Mock implements KundliRepository {}
class MockPanchangRepository extends Mock implements PanchangRepository {}

void main() {
  late MockKundliRepository mockKundliRepo;
  late MockPanchangRepository mockPanchangRepo;

  setUp(() {
    mockKundliRepo = MockKundliRepository();
    mockPanchangRepo = MockPanchangRepository();
  });

  group('Kundli Use Cases', () {
    const dummyKundli = KundliEntity(
      birthDetails: KundliBirthDetails(
        date: '1995-08-15',
        time: '14:30:00',
        latitude: 28.6139,
        longitude: 77.2090,
        timezone: 'Asia/Kolkata',
      ),
      lagna: LagnaInfo(
        sign: 'Simha',
        signEn: 'Leo',
        degree: 12.5,
        totalLongitude: 132.5,
        nakshatra: 'Magha',
        lord: 'Sun',
        element: 'Fire',
        dosha: 'PITTA',
      ),
      janmaRashi: 'Mesha',
      janmaRashiEn: 'Aries',
      janmaNakshatra: 'Ashwini',
      janmaNakshatraPada: 1,
      sunSign: 'Simha',
      sunSignEn: 'Leo',
      planets: [],
      houses: [],
      dashaTimeline: [],
      bodyType: AstrologicalBodyType(
        astrologicalPrakriti: 'PITTA',
        primaryDosha: 'PITTA',
        secondaryDosha: 'VATA',
        vataScore: 30.0,
        pittaScore: 55.0,
        kaphaScore: 15.0,
        lagnaElement: 'Fire',
        lagnaLord: 'Sun',
      ),
      mangalDosha: MangalDoshaReport(
        isManglik: false,
        house: 0,
        isCancelled: false,
        severity: 'NONE',
        description: 'No Mangal Dosha',
      ),
      sadeSati: SadeSatiReport(
        isActive: false,
        phase: 'INACTIVE',
        description: 'No Sade Sati',
      ),
    );

    test('GetUserKundliUseCase calls getUserKundli on repository', () async {
      when(() => mockKundliRepo.getUserKundli()).thenAnswer((_) async => dummyKundli);
      final useCase = GetUserKundliUseCase(mockKundliRepo);

      final result = await useCase();

      expect(result, dummyKundli);
      verify(() => mockKundliRepo.getUserKundli()).called(1);
    });

    test('GenerateKundliUseCase calls generateKundli on repository', () async {
      when(() => mockKundliRepo.generateKundli(
            dateOfBirth: '1995-08-15',
            timeOfBirth: '14:30:00',
            latitude: 28.6139,
            longitude: 77.2090,
            timezone: 'Asia/Kolkata',
            birthCity: 'Delhi',
            birthState: 'Delhi',
            saveToProfile: true,
          )).thenAnswer((_) async => dummyKundli);

      final useCase = GenerateKundliUseCase(mockKundliRepo);
      final result = await useCase(
        dateOfBirth: '1995-08-15',
        timeOfBirth: '14:30:00',
        latitude: 28.6139,
        longitude: 77.2090,
        birthCity: 'Delhi',
        birthState: 'Delhi',
        saveToProfile: true,
      );

      expect(result, dummyKundli);
      verify(() => mockKundliRepo.generateKundli(
            dateOfBirth: '1995-08-15',
            timeOfBirth: '14:30:00',
            latitude: 28.6139,
            longitude: 77.2090,
            timezone: 'Asia/Kolkata',
            birthCity: 'Delhi',
            birthState: 'Delhi',
            saveToProfile: true,
          )).called(1);
    });

    test('SaveBirthDetailsUseCase calls saveBirthDetails on repository', () async {
      when(() => mockKundliRepo.saveBirthDetails(
            dateOfBirth: '1995-08-15',
            timeOfBirth: '14:30:00',
            birthCity: 'Delhi',
            birthState: 'Delhi',
            birthCountry: 'India',
            latitude: 28.6139,
            longitude: 77.2090,
            timezone: 'Asia/Kolkata',
          )).thenAnswer((_) async => true);

      final useCase = SaveBirthDetailsUseCase(mockKundliRepo);
      final result = await useCase(
        dateOfBirth: '1995-08-15',
        timeOfBirth: '14:30:00',
        birthCity: 'Delhi',
        birthState: 'Delhi',
        latitude: 28.6139,
        longitude: 77.2090,
      );

      expect(result, true);
      verify(() => mockKundliRepo.saveBirthDetails(
            dateOfBirth: '1995-08-15',
            timeOfBirth: '14:30:00',
            birthCity: 'Delhi',
            birthState: 'Delhi',
            birthCountry: 'India',
            latitude: 28.6139,
            longitude: 77.2090,
            timezone: 'Asia/Kolkata',
          )).called(1);
    });
  });

  group('Panchang Use Cases', () {
    const dummyDay = PanchangDayEntity(
      date: '2026-08-18',
      location: PanchangLocationEntity(latitude: 28.6139, longitude: 77.2090, timezone: 'Asia/Kolkata'),
      sunMoon: PanchangSunMoonTimingsEntity(sunrise: '05:52 AM', sunset: '06:58 PM'),
      tithi: PanchangCoreItemEntity(name: 'Shukla Panchami'),
      nakshatra: PanchangCoreItemEntity(name: 'Chitra'),
      yoga: PanchangCoreItemEntity(name: 'Shubha'),
      karana: PanchangCoreItemEntity(name: 'Bava'),
      vara: 'Tuesday',
      masaAmanta: 'Shravana',
      masaPurnimanta: 'Bhadrapada',
      paksha: 'Shukla',
      ritu: 'Varsha',
      moonRashi: 'Kanya',
    );

    test('GetPanchangDayUseCase calls getPanchangDay on repository', () async {
      when(() => mockPanchangRepo.getPanchangDay()).thenAnswer((_) async => dummyDay);
      final useCase = GetPanchangDayUseCase(mockPanchangRepo);

      final result = await useCase();

      expect(result.date, '2026-08-18');
      expect(result.tithi.name, 'Shukla Panchami');
      verify(() => mockPanchangRepo.getPanchangDay()).called(1);
    });
  });
}
