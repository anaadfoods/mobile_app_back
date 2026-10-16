import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_batch.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_vegetable.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan_pricing.dart';
import 'package:grocery_app/features/rfp/domain/usecases/calculate_pricing_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_batches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_patches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_plans_use_case.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';

class MockGetBatchesUseCase extends Mock implements GetBatchesUseCase {}
class MockGetPlansUseCase extends Mock implements GetPlansUseCase {}
class MockGetPatchesUseCase extends Mock implements GetPatchesUseCase {}
class MockCalculatePricingUseCase extends Mock implements CalculatePricingUseCase {}

void main() {
  late MockGetBatchesUseCase mockGetBatches;
  late MockGetPlansUseCase mockGetPlans;
  late MockGetPatchesUseCase mockGetPatches;
  late MockCalculatePricingUseCase mockCalculatePricing;
  late RfpBatchCubit cubit;

  final testVegetables = [
    const RfpVegetable(id: 'v1', name: 'Carrot', description: 'Fresh carrot', season: 'winter'),
    const RfpVegetable(id: 'v2', name: 'Spinach', description: 'Organic spinach', season: 'winter'),
    const RfpVegetable(id: 'v3', name: 'Radish', description: 'White radish', season: 'winter'),
    const RfpVegetable(id: 'v4', name: 'Methi', description: 'Green methi', season: 'winter'),
  ];

  final testPricings = [
    const RfpPlanPricing(id: 1, variantName: 'SMALL', weightKg: 2.5, frequencyPerWeek: 1, pricePerDelivery: 900),
    const RfpPlanPricing(id: 2, variantName: 'MEDIUM', weightKg: 5.0, frequencyPerWeek: 1, pricePerDelivery: 1800),
    const RfpPlanPricing(id: 3, variantName: 'LARGE', weightKg: 7.5, frequencyPerWeek: 2, pricePerDelivery: 2700),
  ];

  final testPlan = RfpPlan(
    id: 'plan_01',
    name: 'Ritu Thali',
    tier: 'premium',
    description: 'Curated staple seasonal greens',
    totalPrice: 21600,
    bookingAmount: 2000,
    remainingAmount: 19600,
    features: const ['Weekly harvest'],
    selectionLimit: 3,
    maxDeselectableCount: 2,
    availableVegetables: testVegetables,
    pricings: testPricings,
  );

  final testBatch = RfpBatch(
    id: 'batch_01',
    batchNumber: 1,
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2026, 11, 24),
    totalWeeks: 12,
    currentWeek: 1,
    status: 'active',
    progressPercent: 0.1,
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
  });

  tearDown(() {
    cubit.close();
  });

  group('RfpBatchCubit Plan Configurator', () {
    test('initializeVegetablesForPlan preselects vegetables up to limit and sets default pricing', () {
      cubit.initializeVegetablesForPlan(testPlan);

      expect(cubit.state.selectedVegetableIds.length, 3);
      expect(cubit.state.selectedVegetableIds, containsAll(['v1', 'v2', 'v3']));
      expect(cubit.state.selectedPricingVariant, testPricings.first);
      expect(cubit.state.selectedFrequency, 1);
    });

    test('toggleVegetable respects selectionLimit and allows deselection', () {
      cubit.selectPlan(testPlan);
      cubit.initializeVegetablesForPlan(testPlan);

      // Deselect 'v1'
      cubit.toggleVegetable('v1');
      expect(cubit.state.selectedVegetableIds.contains('v1'), isFalse);
      expect(cubit.state.selectedVegetableIds.length, 2);

      // Select 'v4' (now at limit of 3: v2, v3, v4)
      cubit.toggleVegetable('v4');
      expect(cubit.state.selectedVegetableIds.contains('v4'), isTrue);
      expect(cubit.state.selectedVegetableIds.length, 3);

      // Attempting to select 'v1' again should do nothing because limit is 3
      cubit.toggleVegetable('v1');
      expect(cubit.state.selectedVegetableIds.contains('v1'), isFalse);
      expect(cubit.state.selectedVegetableIds.length, 3);
    });

    test('toggleVegetable blocks deselection when maxDeselectableCount is reached', () {
      cubit.selectPlan(testPlan);
      cubit.initializeVegetablesForPlan(testPlan);

      // Deselect 1st allowed default: v1
      cubit.toggleVegetable('v1');
      expect(cubit.state.selectedVegetableIds.contains('v1'), isFalse);
      expect(testPlan.getRemainingDeselects(cubit.state.selectedVegetableIds), 1);

      // Deselect 2nd allowed default: v2
      cubit.toggleVegetable('v2');
      expect(cubit.state.selectedVegetableIds.contains('v2'), isFalse);
      expect(testPlan.getRemainingDeselects(cubit.state.selectedVegetableIds), 0);

      // Attempting to deselect 3rd default (v3) should be blocked because maxDeselectableCount is 2
      cubit.toggleVegetable('v3');
      expect(cubit.state.selectedVegetableIds.contains('v3'), isTrue);
      expect(cubit.state.deselectionWarning, contains('Maximum swap limit'));

      // Re-selecting v1 restores 1 deselection slot
      cubit.toggleVegetable('v1');
      expect(cubit.state.selectedVegetableIds.contains('v1'), isTrue);
      expect(testPlan.getRemainingDeselects(cubit.state.selectedVegetableIds), 1);
    });

    test('toggleVegetable blocks all default deselections when maxDeselectableCount is 0', () {
      final fixedPlan = RfpPlan(
        id: 'plan_fixed',
        name: 'Fixed Thali',
        tier: 'standard',
        description: 'Fixed harvest curation',
        totalPrice: 15000,
        bookingAmount: 1500,
        remainingAmount: 13500,
        features: const ['Fixed harvest'],
        selectionLimit: 3,
        maxDeselectableCount: 0,
        availableVegetables: testVegetables,
        pricings: testPricings,
      );

      cubit.selectPlan(fixedPlan);
      cubit.initializeVegetablesForPlan(fixedPlan);

      // Deselecting any default item should be immediately blocked
      cubit.toggleVegetable('v1');
      expect(cubit.state.selectedVegetableIds.contains('v1'), isTrue);
      expect(cubit.state.deselectionWarning, contains('fixed curated harvest'));
    });

    test('selectPricingVariant updates variant and frequency', () {
      cubit.selectPricingVariant(testPricings[1]);

      expect(cubit.state.selectedPricingVariant, testPricings[1]);
      expect(cubit.state.selectedFrequency, 1);
    });

    test('setDeliveryFrequency updates frequency and matching variant', () {
      cubit.selectPlan(testPlan);
      cubit.initializeVegetablesForPlan(testPlan);

      expect(cubit.state.selectedFrequency, 1);

      cubit.setDeliveryFrequency(2);
      expect(cubit.state.selectedFrequency, 2);

      cubit.setDeliveryFrequency(1);
      expect(cubit.state.selectedFrequency, 1);
    });

    test('toggleDeliveryDay updates selected days up to frequency', () {
      cubit.setDeliveryFrequency(2);

      // Select Mon (0)
      cubit.toggleDeliveryDay(0);
      expect(cubit.state.selectedDeliveryDays, {0});

      // Select Thu (3)
      cubit.toggleDeliveryDay(3);
      expect(cubit.state.selectedDeliveryDays, {0, 3});

      // Toggle Mon off
      cubit.toggleDeliveryDay(0);
      expect(cubit.state.selectedDeliveryDays, {3});
    });

    test('confirmPlanConfiguration sets isPlanConfigured to true', () {
      cubit.confirmPlanConfiguration();

      expect(cubit.state.isPlanConfigured, isTrue);
    });

    test('canContinueToCheckout requires batch, plan, isPlanConfigured, and selected vegetables', () {
      const initial = RfpBatchState();
      expect(initial.canContinueToCheckout, isFalse);

      final unconfiguredState = RfpBatchState(
        selectedBatch: testBatch,
        selectedPlan: testPlan,
        isPlanConfigured: false,
        selectedVegetableIds: const {'v1', 'v2'},
      );
      expect(unconfiguredState.canContinueToCheckout, isFalse);

      final configuredState = unconfiguredState.copyWith(isPlanConfigured: true);
      expect(configuredState.canContinueToCheckout, isTrue);
    });
  });
}
