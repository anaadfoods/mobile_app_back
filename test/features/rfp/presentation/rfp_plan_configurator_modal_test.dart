import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_vegetable.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan_pricing.dart';
import 'package:grocery_app/features/rfp/domain/usecases/calculate_pricing_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_batches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_patches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_plans_use_case.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_plan_configurator_modal.dart';

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
    const RfpVegetable(
      id: 'veg_01',
      name: 'Carrot',
      description: 'Crunchy farm carrots',
      season: 'winter',
      isDefaultSelected: true,
    ),
    const RfpVegetable(
      id: 'veg_02',
      name: 'Spinach',
      description: 'Iron-rich organic greens',
      season: 'winter',
      isDefaultSelected: true,
    ),
    const RfpVegetable(
      id: 'veg_03',
      name: 'Radish',
      description: 'Pungent white radish',
      season: 'winter',
      isDefaultSelected: false,
    ),
    const RfpVegetable(
      id: 'veg_04',
      name: 'Methi',
      description: 'Fragrant fenugreek leaves',
      season: 'winter',
      isDefaultSelected: false,
    ),
  ];

  final testPricings = [
    const RfpPlanPricing(
      id: 101,
      variantName: 'MINI',
      weightKg: 2.5,
      frequencyPerWeek: 1,
      pricePerDelivery: 850,
    ),
    const RfpPlanPricing(
      id: 102,
      variantName: 'STANDARD',
      weightKg: 5.0,
      frequencyPerWeek: 1,
      pricePerDelivery: 1600,
    ),
    const RfpPlanPricing(
      id: 103,
      variantName: 'FAMILY',
      weightKg: 7.5,
      frequencyPerWeek: 2,
      pricePerDelivery: 2400,
    ),
  ];

  final testPlan = RfpPlan(
    id: 'plan_curated_01',
    name: 'Season Greens Thali',
    tier: 'premium',
    description: 'Curated box of fresh organic harvest',
    totalPrice: 20400,
    bookingAmount: 2000,
    remainingAmount: 18400,
    features: const ['12 deliveries', 'Farm fresh'],
    selectionLimit: 2,
    maxDeselectableCount: 1,
    availableVegetables: testVegetables,
    pricings: testPricings,
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

  Future<void> pumpConfigurator(WidgetTester tester, RfpPlan plan) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: RfpPlanConfiguratorModal(plan: plan),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('RfpPlanConfiguratorModal Widget Tests', () {
    testWidgets('renders plan title, available vegetables, variants, and frequency options', (tester) async {
      cubit.initializeVegetablesForPlan(testPlan);
      await pumpConfigurator(tester, testPlan);

      // Header
      expect(find.text('CUSTOM HARVEST BOX'), findsOneWidget);
      expect(find.text('CONFIGURE YOUR ${testPlan.name.toUpperCase()}'), findsOneWidget);

      // Vegetable section
      expect(find.text('SELECT VEGETABLES'), findsOneWidget);
      expect(find.text('Carrot'), findsOneWidget);
      expect(find.text('Spinach'), findsOneWidget);
      expect(find.text('Radish'), findsOneWidget);
      expect(find.text('Methi'), findsOneWidget);

      // Swaps and selection counters
      expect(find.text('Swaps: 1/1'), findsOneWidget);
      expect(find.text('Selected: 2 / 2'), findsOneWidget);

      // Default badges for default vegetables
      expect(find.text('DEFAULT'), findsNWidgets(2));

      // Variant selection
      expect(find.text('CHOOSE YOUR VARIANT'), findsOneWidget);
      expect(find.textContaining('2.5 KG • MINI'), findsOneWidget);
      expect(find.textContaining('5.0 KG • STANDARD'), findsOneWidget);
      expect(find.textContaining('7.5 KG • FAMILY'), findsOneWidget);

      // Frequency options from backend
      expect(find.text('DELIVERY FREQUENCY'), findsOneWidget);
      expect(find.text('1 Day / Week'), findsOneWidget);
      expect(find.text('2 Days / Week'), findsOneWidget);

      // Confirm button
      expect(find.text('CONFIRM CONFIGURATION'), findsOneWidget);
    });

    testWidgets('handles vegetable swap respecting maxDeselectableCount and selectionLimit', (tester) async {
      cubit.initializeVegetablesForPlan(testPlan);
      await pumpConfigurator(tester, testPlan);

      // Currently Carrot (veg_01) and Spinach (veg_02) are selected (count = 2)
      expect(cubit.state.selectedVegetableIds, {'veg_01', 'veg_02'});

      // Deselect 1st default item: Carrot
      await tester.tap(find.text('Carrot'));
      await tester.pumpAndSettle();

      expect(cubit.state.selectedVegetableIds, {'veg_02'});
      expect(find.text('Swaps: 0/1'), findsOneWidget);
      expect(find.text('Selected: 1 / 2'), findsOneWidget);

      // Select alternative item: Radish (veg_03)
      await tester.tap(find.text('Radish'));
      await tester.pumpAndSettle();

      expect(cubit.state.selectedVegetableIds, {'veg_02', 'veg_03'});
      expect(find.text('Selected: 2 / 2'), findsOneWidget);

      // Attempt to deselect Spinach (second default item). Should be blocked because maxDeselectableCount is 1.
      await tester.tap(find.text('Spinach'));
      await tester.pumpAndSettle();

      expect(cubit.state.selectedVegetableIds.contains('veg_02'), isTrue);
      expect(find.text('Swap Limit Reached'), findsOneWidget);
      expect(find.textContaining('You have used all 1 allowed swaps'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();

      // Attempt to select 3rd item when limit is 2. Should show clear selection limit popup
      await tester.tap(find.text('Methi'));
      await tester.pumpAndSettle();

      expect(find.text('Box is Full (2 / 2)'), findsOneWidget);
      expect(find.textContaining('reached the maximum box capacity of 2 vegetables'), findsOneWidget);

      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
    });

    testWidgets('validates selection before saving: blocks save when selection count is insufficient', (tester) async {
      cubit.initializeVegetablesForPlan(testPlan);
      await pumpConfigurator(tester, testPlan);

      // Deselect Carrot to leave only 1 vegetable selected (2 required)
      await tester.tap(find.text('Carrot'));
      await tester.pumpAndSettle();
      expect(cubit.state.selectedVegetableIds.length, 1);

      // Tap Confirm/Save button
      await tester.tap(find.text('CONFIRM CONFIGURATION'));
      await tester.pumpAndSettle();

      // Validation error banner and snackbar should be displayed
      expect(find.text('Please select 1 more vegetable to complete your box (2 required).'), findsWidgets);
      // Cubit state should NOT be configured yet
      expect(cubit.state.isPlanConfigured, isFalse);
    });

    testWidgets('successfully saves and updates Cubit state when valid', (tester) async {
      cubit.initializeVegetablesForPlan(testPlan);
      await pumpConfigurator(tester, testPlan);

      // Both default vegetables are selected (2/2) and default pricing is set
      expect(cubit.state.selectedVegetableIds.length, 2);
      expect(cubit.state.selectedPricingVariant, isNotNull);

      // Tap Confirm/Save button
      await tester.tap(find.text('CONFIRM CONFIGURATION'));
      await tester.pumpAndSettle();

      // Cubit state is successfully updated
      expect(cubit.state.isPlanConfigured, isTrue);
      expect(cubit.state.selectedPlanIds.contains(testPlan.id), isTrue);
      expect(cubit.state.planConfigurations[testPlan.id]?.isConfigured, isTrue);
      expect(cubit.state.planConfigurations[testPlan.id]?.selectedVegetableIds, {'veg_01', 'veg_02'});
    });

    testWidgets('allows selecting variant and frequency dynamically', (tester) async {
      cubit.initializeVegetablesForPlan(testPlan);
      await pumpConfigurator(tester, testPlan);

      // Switch to 5.0 KG variant
      await tester.tap(find.textContaining('5.0 KG • STANDARD'));
      await tester.pumpAndSettle();

      expect(cubit.state.selectedPricingVariant?.weightKg, 5.0);

      // Switch to 2 Days / Week frequency
      await tester.tap(find.text('2 Days / Week'));
      await tester.pumpAndSettle();

      expect(cubit.state.selectedFrequency, 2);
    });
  });
}
