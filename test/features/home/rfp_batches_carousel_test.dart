import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/home/presentation/widgets/rfp_batch_carousel_card.dart';
import 'package:grocery_app/features/home/presentation/widgets/rfp_batches_carousel.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_batch.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/domain/usecases/calculate_pricing_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_batches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_patches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_plans_use_case.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';

class MockGetBatchesUseCase extends Mock implements GetBatchesUseCase {}

class MockGetPlansUseCase extends Mock implements GetPlansUseCase {}

class MockGetPatchesUseCase extends Mock implements GetPatchesUseCase {}

class MockCalculatePricingUseCase extends Mock
    implements CalculatePricingUseCase {}

void main() {
  late MockGetBatchesUseCase mockGetBatches;
  late MockGetPlansUseCase mockGetPlans;
  late MockGetPatchesUseCase mockGetPatches;
  late MockCalculatePricingUseCase mockCalculatePricing;
  late RfpBatchCubit cubit;

  final testBatch = RfpBatch(
    id: 'batch_01',
    batchNumber: 8842,
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 12, 24),
    totalWeeks: 12,
    currentWeek: 1,
    status: 'active',
    seasonLabel: 'Winter Solstice Harvest',
    progressPercent: 0.1,
    slotsRemaining: 5,
    plans: const [
      RfpPlan(
        id: 'plan_01',
        name: 'Curated Ritu Thali',
        tier: 'premium',
        description: 'Seasonal veggies',
        totalPrice: 12000,
        bookingAmount: 1200,
        remainingAmount: 10800,
        features: ['Fresh Drop'],
        availableVegetables: [],
        pricings: [],
      ),
    ],
  );

  setUp(() {
    mockGetBatches = MockGetBatchesUseCase();
    mockGetPlans = MockGetPlansUseCase();
    mockGetPatches = MockGetPatchesUseCase();
    mockCalculatePricing = MockCalculatePricingUseCase();

    cubit = RfpBatchCubit(
      getBatches: mockGetBatches,
      getPlans: mockGetPlans,
      getPatches: mockGetPatches,
      calculatePricing: mockCalculatePricing,
    );

    when(() => mockGetPatches(any())).thenAnswer((_) async => []);
  });

  group('RfpBatchesCarousel & RfpBatchCarouselCard', () {
    testWidgets('renders nothing when batches list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<RfpBatchCubit>.value(
              value: cubit,
              child: const RfpBatchesCarousel(),
            ),
          ),
        ),
      );

      expect(find.text('Remote Farming Program'), findsNothing);
    });

    testWidgets('renders carousel cards with name, availability, and plans',
        (tester) async {
      when(() => mockGetBatches(any())).thenAnswer((_) async => [testBatch]);
      when(() => mockGetPlans(any())).thenAnswer((_) async => testBatch.plans);

      await cubit.loadBatchData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<RfpBatchCubit>.value(
              value: cubit,
              child: const RfpBatchesCarousel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remote Farming Program'), findsOneWidget);
      expect(find.text('BATCH #8842 • 12 WEEKS'), findsWidgets);
      expect(find.text('• 5 SLOTS LEFT'), findsWidgets);
      expect(find.text('WINTER SOLSTICE HARVEST'), findsWidgets);
      expect(find.text('Explore Batch & Plans'), findsWidgets);
      expect(find.text('Curated Ritu Thali'), findsWidgets);
    });

    testWidgets('RfpBatchCarouselCard displays BATCH FULL when full',
        (tester) async {
      final fullBatch = RfpBatch(
        id: testBatch.id,
        batchNumber: testBatch.batchNumber,
        startDate: testBatch.startDate,
        endDate: testBatch.endDate,
        totalWeeks: testBatch.totalWeeks,
        currentWeek: testBatch.currentWeek,
        status: testBatch.status,
        seasonLabel: testBatch.seasonLabel,
        progressPercent: testBatch.progressPercent,
        isFull: true,
        slotsRemaining: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<RfpBatchCubit>.value(
              value: cubit,
              child: RfpBatchCarouselCard(
                batch: fullBatch,
                isActive: true,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('BATCH FULL'), findsOneWidget);
    });
  });
}
