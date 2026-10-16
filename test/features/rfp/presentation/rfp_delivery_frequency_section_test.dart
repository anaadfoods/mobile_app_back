import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan_pricing.dart';
import 'package:grocery_app/features/rfp/domain/usecases/calculate_pricing_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_batches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_patches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_plans_use_case.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_delivery_frequency_section.dart';

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

  final testPricings = [
    const RfpPlanPricing(
      id: 1,
      variantName: 'SMALL',
      weightKg: 2.5,
      frequencyPerWeek: 1,
      pricePerDelivery: 319,
    ),
    const RfpPlanPricing(
      id: 2,
      variantName: 'SMALL',
      weightKg: 2.5,
      frequencyPerWeek: 2,
      pricePerDelivery: 300,
    ),
  ];

  final testPlan = RfpPlan(
    id: 'plan_01',
    name: 'Ritu Thali',
    tier: 'premium',
    description: 'Fresh seasonal vegetables',
    totalPrice: 15000,
    bookingAmount: 1500,
    remainingAmount: 13500,
    features: const ['12 weeks'],
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

  testWidgets('renders 1 Day / Week and 2 Days / Week tiles with prices and updates cubit on tap', (tester) async {
    cubit.selectPlan(testPlan);
    cubit.initializeVegetablesForPlan(testPlan);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: SingleChildScrollView(
              child: RfpDeliveryFrequencySection(plan: testPlan),
            ),
          ),
        ),
      ),
    );

    // Initial assertions
    expect(find.text('DELIVERY FREQUENCY'), findsOneWidget);
    expect(find.text('Choose how often your fresh harvest is dispatched'), findsOneWidget);
    expect(find.text('1 Day / Week'), findsOneWidget);
    expect(find.text('One harvest delivery every week'), findsOneWidget);
    expect(find.text('2 Days / Week'), findsOneWidget);
    expect(find.text('Two harvest deliveries every week'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(find.text('₹319/del'), findsOneWidget);
    expect(find.text('₹300/del'), findsOneWidget);

    // Default frequency should be 1
    expect(cubit.state.selectedFrequency, 1);

    // Tap 2 Days / Week tile
    await tester.tap(find.text('2 Days / Week'));
    await tester.pump();

    // Frequency should now be 2
    expect(cubit.state.selectedFrequency, 2);

    // Tap 1 Day / Week tile
    await tester.tap(find.text('1 Day / Week'));
    await tester.pump();

    // Frequency should switch back to 1
    expect(cubit.state.selectedFrequency, 1);
  });
}
