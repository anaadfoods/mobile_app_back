// test/features/panchang/presentation/kundli_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:grocery_app/features/panchang/domain/entities/kundli_entities.dart';
import 'package:grocery_app/features/panchang/domain/usecases/get_user_kundli_use_case.dart';
import 'package:grocery_app/features/panchang/domain/usecases/generate_kundli_use_case.dart';
import 'package:grocery_app/features/panchang/domain/usecases/get_birth_details_use_case.dart';
import 'package:grocery_app/features/panchang/domain/usecases/save_birth_details_use_case.dart';
import 'package:grocery_app/features/panchang/presentation/cubit/kundli_cubit.dart';
import 'package:grocery_app/features/panchang/presentation/cubit/kundli_state.dart';

class MockGetUserKundliUseCase extends Mock implements GetUserKundliUseCase {}
class MockGenerateKundliUseCase extends Mock implements GenerateKundliUseCase {}
class MockGetBirthDetailsUseCase extends Mock implements GetBirthDetailsUseCase {}
class MockSaveBirthDetailsUseCase extends Mock implements SaveBirthDetailsUseCase {}

void main() {
  late MockGetUserKundliUseCase mockGetUserKundliUseCase;
  late MockGenerateKundliUseCase mockGenerateKundliUseCase;
  late MockGetBirthDetailsUseCase mockGetBirthDetailsUseCase;
  late MockSaveBirthDetailsUseCase mockSaveBirthDetailsUseCase;
  late KundliCubit cubit;

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

  setUp(() {
    mockGetUserKundliUseCase = MockGetUserKundliUseCase();
    mockGenerateKundliUseCase = MockGenerateKundliUseCase();
    mockGetBirthDetailsUseCase = MockGetBirthDetailsUseCase();
    mockSaveBirthDetailsUseCase = MockSaveBirthDetailsUseCase();

    cubit = KundliCubit(
      getUserKundliUseCase: mockGetUserKundliUseCase,
      generateKundliUseCase: mockGenerateKundliUseCase,
      getBirthDetailsUseCase: mockGetBirthDetailsUseCase,
      saveBirthDetailsUseCase: mockSaveBirthDetailsUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('KundliCubit', () {
    test('initial state is KundliInitial', () {
      expect(cubit.state, const KundliInitial());
    });

    blocTest<KundliCubit, KundliState>(
      'loadUserKundli emits [KundliLoading, KundliLoaded(isTemporary: false)] when user has saved Kundli',
      build: () {
        when(() => mockGetUserKundliUseCase()).thenAnswer((_) async => dummyKundli);
        return cubit;
      },
      act: (c) => c.loadUserKundli(),
      expect: () => [
        const KundliLoading(),
        const KundliLoaded(kundli: dummyKundli, isTemporary: false),
      ],
    );

    blocTest<KundliCubit, KundliState>(
      'loadUserKundli emits [KundliLoading, KundliPendingDetails] when no saved Kundli',
      build: () {
        when(() => mockGetUserKundliUseCase()).thenAnswer((_) async => null);
        when(() => mockGetBirthDetailsUseCase()).thenAnswer((_) async => null);
        return cubit;
      },
      act: (c) => c.loadUserKundli(),
      expect: () => [
        const KundliLoading(),
        const KundliPendingDetails(savedDetails: null),
      ],
    );

    blocTest<KundliCubit, KundliState>(
      'showKundli emits KundliLoaded with isTemporary flag',
      build: () => cubit,
      act: (c) => c.showKundli(dummyKundli, isTemporary: true),
      expect: () => [
        const KundliLoaded(kundli: dummyKundli, isTemporary: true),
      ],
    );

    blocTest<KundliCubit, KundliState>(
      'generateAndSaveKundli with saveToProfile: false generates temporary Kundli without saving details',
      build: () {
        when(() => mockGenerateKundliUseCase(
              dateOfBirth: '1995-08-15',
              timeOfBirth: '14:30:00',
              latitude: 28.6139,
              longitude: 77.2090,
              timezone: 'Asia/Kolkata',
              birthCity: 'Delhi',
              birthState: 'Delhi',
              saveToProfile: false,
            )).thenAnswer((_) async => dummyKundli);
        return cubit;
      },
      act: (c) => c.generateAndSaveKundli(
        dateOfBirth: '1995-08-15',
        timeOfBirth: '14:30:00',
        latitude: 28.6139,
        longitude: 77.2090,
        birthCity: 'Delhi',
        birthState: 'Delhi',
        saveToProfile: false,
      ),
      expect: () => [
        const KundliLoading(),
        const KundliLoaded(kundli: dummyKundli, isTemporary: true),
      ],
      verify: (_) {
        verifyNever(() => mockSaveBirthDetailsUseCase(
              dateOfBirth: any(named: 'dateOfBirth'),
              timeOfBirth: any(named: 'timeOfBirth'),
              birthCity: any(named: 'birthCity'),
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
            ));
      },
    );

    blocTest<KundliCubit, KundliState>(
      'generateAndSaveKundli with saveToProfile: true saves birth details and generates permanent Kundli',
      build: () {
        when(() => mockSaveBirthDetailsUseCase(
              dateOfBirth: '1995-08-15',
              timeOfBirth: '14:30:00',
              birthCity: 'Delhi',
              birthState: 'Delhi',
              birthCountry: 'India',
              latitude: 28.6139,
              longitude: 77.2090,
              timezone: 'Asia/Kolkata',
            )).thenAnswer((_) async => true);
        when(() => mockGenerateKundliUseCase(
              dateOfBirth: '1995-08-15',
              timeOfBirth: '14:30:00',
              latitude: 28.6139,
              longitude: 77.2090,
              timezone: 'Asia/Kolkata',
              birthCity: 'Delhi',
              birthState: 'Delhi',
              saveToProfile: true,
            )).thenAnswer((_) async => dummyKundli);
        return cubit;
      },
      act: (c) => c.generateAndSaveKundli(
        dateOfBirth: '1995-08-15',
        timeOfBirth: '14:30:00',
        latitude: 28.6139,
        longitude: 77.2090,
        birthCity: 'Delhi',
        birthState: 'Delhi',
        saveToProfile: true,
      ),
      expect: () => [
        const KundliLoading(),
        const KundliLoaded(kundli: dummyKundli, isTemporary: false),
      ],
      verify: (_) {
        verify(() => mockSaveBirthDetailsUseCase(
              dateOfBirth: '1995-08-15',
              timeOfBirth: '14:30:00',
              birthCity: 'Delhi',
              birthState: 'Delhi',
              birthCountry: 'India',
              latitude: 28.6139,
              longitude: 77.2090,
              timezone: 'Asia/Kolkata',
            )).called(1);
      },
    );
  });
}
