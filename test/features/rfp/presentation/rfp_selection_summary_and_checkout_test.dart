import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_batch.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan_pricing.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_pricing.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_vegetable.dart';
import 'package:grocery_app/features/rfp/domain/entities/user_address.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_booking.dart';
import 'package:grocery_app/features/rfp/domain/usecases/calculate_pricing_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/create_booking_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_batches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_patches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_plans_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_user_addresses_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/save_user_address_use_case.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_checkout_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/screens/rfp_checkout_screen.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_selection_summary_bar.dart';

class MockGetBatchesUseCase extends Mock implements GetBatchesUseCase {}
class MockGetPlansUseCase extends Mock implements GetPlansUseCase {}
class MockGetPatchesUseCase extends Mock implements GetPatchesUseCase {}
class MockCalculatePricingUseCase extends Mock implements CalculatePricingUseCase {}
class MockCreateBookingUseCase extends Mock implements CreateBookingUseCase {}
class MockGetUserAddressesUseCase extends Mock implements GetUserAddressesUseCase {}
class MockSaveUserAddressUseCase extends Mock implements SaveUserAddressUseCase {}

void main() {
  late MockGetBatchesUseCase mockGetBatches;
  late MockGetPlansUseCase mockGetPlans;
  late MockGetPatchesUseCase mockGetPatches;
  late MockCalculatePricingUseCase mockCalculatePricing;
  late MockCreateBookingUseCase mockCreateBooking;
  late MockGetUserAddressesUseCase mockGetUserAddresses;
  late MockSaveUserAddressUseCase mockSaveUserAddress;

  late RfpBatchCubit batchCubit;
  late RfpCheckoutCubit checkoutCubit;

  final testBatch = RfpBatch(
    id: '1',
    batchNumber: 1,
    seasonLabel: 'Oct-Jan 2026 Batch',
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 12, 24),
    currentWeek: 1,
    status: 'UPCOMING',
    progressPercent: 0.1,
    totalWeeks: 12,
    bookingStartDate: DateTime(2026, 9, 15),
    bookingEndDate: DateTime(2026, 10, 14),
    remainingPaymentDueDate: DateTime(2026, 11, 15),
  );

  final testPlan = RfpPlan(
    id: '3',
    code: 'A',
    name: 'Ritu Thali',
    tier: 'standard',
    description: 'The Seasonal Plan',
    totalPrice: 10120.0,
    bookingAmount: 920.0,
    remainingAmount: 9200.0,
    features: const ['12 Deliveries'],
    selectionLimit: 5,
    maxDeselectableCount: 2,
    availableVegetables: const [
      RfpVegetable(
        id: '1',
        name: 'Aloo',
        description: 'Fresh potatoes',
        season: 'winter',
        isDefaultSelected: true,
      ),
      RfpVegetable(
        id: '4',
        name: 'Pyaz',
        description: 'Fresh onions',
        season: 'winter',
        isDefaultSelected: false,
      ),
    ],
    pricings: const [
      RfpPlanPricing(
        id: 12,
        variantName: 'SMALL',
        weightKg: 2.5,
        frequencyPerWeek: 1,
        pricePerDelivery: 319.0,
      ),
      RfpPlanPricing(
        id: 13,
        variantName: 'SMALL',
        weightKg: 2.5,
        frequencyPerWeek: 2,
        pricePerDelivery: 300.0,
      ),
    ],
  );

  const testQuote = RfpPricing(
    basePrice: 10652.63,
    discountAmount: 532.63,
    finalPrice: 10120.0,
    bookingAmount: 920.0,
    remainingAmount: 9200.0,
    perDelivery: 920.0,
    deliveriesCount: 12,
    bookingDeliveries: 2,
    remainingDeliveries: 10,
    discountPercentage: 5.0,
    planCount: 1,
  );

  const testSavedAddress = UserAddress(
    id: 101,
    label: 'HOME',
    fullName: 'Ramesh Kumar',
    phoneNumber: '9876543210',
    addressLine1: 'Flat 402, Green Valley Apts',
    city: 'Gurugram',
    state: 'Haryana',
    pincode: '122018',
    isDefault: true,
  );

  setUp(() {
    mockGetBatches = MockGetBatchesUseCase();
    mockGetPlans = MockGetPlansUseCase();
    mockGetPatches = MockGetPatchesUseCase();
    mockCalculatePricing = MockCalculatePricingUseCase();
    mockCreateBooking = MockCreateBookingUseCase();
    mockGetUserAddresses = MockGetUserAddressesUseCase();
    mockSaveUserAddress = MockSaveUserAddressUseCase();

    when(() => mockCalculatePricing(
          planId: any(named: 'planId'),
          patchConfigs: any(named: 'patchConfigs'),
          batchId: any(named: 'batchId'),
        )).thenAnswer((_) async => testQuote);

    when(() => mockGetUserAddresses())
        .thenAnswer((_) async => [testSavedAddress]);

    batchCubit = RfpBatchCubit(
      getBatches: mockGetBatches,
      getPlans: mockGetPlans,
      getPatches: mockGetPatches,
      calculatePricing: mockCalculatePricing,
    );

    checkoutCubit = RfpCheckoutCubit(
      createBooking: mockCreateBooking,
      calculatePricing: mockCalculatePricing,
      getUserAddresses: mockGetUserAddresses,
      saveUserAddress: mockSaveUserAddress,
    );
  });

  tearDown(() {
    batchCubit.close();
    checkoutCubit.close();
  });

  Widget buildTestApp(Widget child) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Stack(
              children: [
                child,
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/rfp/checkout',
          builder: (context, state) =>
              const Scaffold(body: Text('Checkout Screen')),
        ),
        GoRoute(
          path: '/rfp/payment-success',
          builder: (context, state) =>
              const Scaffold(body: Text('Payment Success Screen')),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<RfpBatchCubit>.value(value: batchCubit),
        BlocProvider<RfpCheckoutCubit>.value(value: checkoutCubit),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('RfpSelectionSummaryBar Widget Tests', () {
    testWidgets('renders nothing when no plans are selected', (tester) async {
      await tester.pumpWidget(buildTestApp(const RfpSelectionSummaryBar()));
      expect(find.text('Proceed to Checkout'), findsNothing);
    });

    testWidgets('renders loading state while calculating pricing', (tester) async {
      batchCubit.emit(batchCubit.state.copyWith(
        selectedPlanIds: {'3'},
        isPricingLoading: true,
      ));

      await tester.pumpWidget(buildTestApp(const RfpSelectionSummaryBar()));
      expect(find.text('Calculating quote from farm...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state and retry button when calculation fails', (tester) async {
      batchCubit.emit(batchCubit.state.copyWith(
        selectedPlanIds: {'3'},
        pricingError: 'Failed to calculate RFP pricing',
      ));

      await tester.pumpWidget(buildTestApp(const RfpSelectionSummaryBar()));
      expect(find.text('Failed to calculate RFP pricing'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      verify(() => mockCalculatePricing(
            planId: any(named: 'planId'),
            patchConfigs: any(named: 'patchConfigs'),
            batchId: any(named: 'batchId'),
          )).called(1);
    });

    testWidgets('renders calculated quote values accurately from backend source of truth', (tester) async {
      batchCubit.emit(batchCubit.state.copyWith(
        selectedPlanIds: {'3'},
        pricing: testQuote,
      ));

      await tester.pumpWidget(buildTestApp(const RfpSelectionSummaryBar()));
      expect(find.text('12 Deliveries'), findsOneWidget);
      expect(find.text('5% OFF'), findsOneWidget);
      expect(find.text('Total: ₹10,120'), findsOneWidget);
      expect(find.text('Pay Now: ₹920 • Pay Later: ₹9,200'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsOneWidget);
    });
  });

  group('RfpCheckoutScreen Widget Tests', () {
    testWidgets('loads saved addresses on mount and displays selection', (tester) async {
      batchCubit.emit(batchCubit.state.copyWith(
        selectedBatch: testBatch,
        plans: [testPlan],
        selectedPlan: testPlan,
        selectedPlanIds: {'3'},
        pricing: testQuote,
      ));

      await tester.pumpWidget(buildTestApp(const RfpCheckoutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Secure SSL'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Flat 402, Green Valley Apts'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('displays selected plan configuration and delivery days', (tester) async {
      batchCubit.emit(batchCubit.state.copyWith(
        selectedBatch: testBatch,
        plans: [testPlan],
        selectedPlan: testPlan,
        selectedPlanIds: {'3'},
        selectedPricingVariant: testPlan.pricings.first,
        selectedDeliveryDays: {0}, // Monday
        selectedFrequency: 1,
        pricing: testQuote,
      ));

      await tester.pumpWidget(buildTestApp(const RfpCheckoutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Ritu Thali'), findsOneWidget);
      expect(find.text('2.5 KG / box'), findsOneWidget);
      expect(find.text('1 Delivery each week • Mon'), findsOneWidget);
    });

    testWidgets('displays pay_now and pay_later without hardcoded percentages', (tester) async {
      batchCubit.emit(batchCubit.state.copyWith(
        selectedBatch: testBatch,
        plans: [testPlan],
        selectedPlan: testPlan,
        selectedPlanIds: {'3'},
        pricing: testQuote,
      ));

      await tester.pumpWidget(buildTestApp(const RfpCheckoutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Due Today'), findsOneWidget);
      expect(find.text('₹920'), findsWidgets);
      expect(find.text('Due by Wk 3'), findsOneWidget);
      expect(find.text('₹9,200'), findsWidgets);
      expect(find.text('PAY BOOKING AMOUNT: ₹920'), findsOneWidget);
    });

    testWidgets('validates required address and submits booking with payload', (tester) async {
      when(() => mockCreateBooking(
            batchId: any(named: 'batchId'),
            planId: any(named: 'planId'),
            locationId: any(named: 'locationId'),
            patchConfigs: any(named: 'patchConfigs'),
            paymentMethod: any(named: 'paymentMethod'),
            fullName: any(named: 'fullName'),
            addressLine: any(named: 'addressLine'),
            city: any(named: 'city'),
            pincode: any(named: 'pincode'),
            phone: any(named: 'phone'),
            addressId: any(named: 'addressId'),
          )).thenAnswer((_) async => RfpBooking(
            id: 'bk_001',
            batchId: '1',
            batchNumber: 1,
            planId: '3',
            planName: 'Ritu Thali',
            status: 'confirmed',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 12, 24),
            patchConfigs: const [],
            totalAmount: 10120.0,
            bookingAmountPaid: 920.0,
            remainingAmount: 9200.0,
            bookedAt: DateTime.now(),
            address: const RfpBookingAddress(
              fullName: 'Ramesh Kumar',
              addressLine: 'Flat 402, Green Valley Apts',
              city: 'Gurugram',
              pincode: '122018',
              phone: '9876543210',
            ),
            checkoutUrl: 'https://checkout.anaadfoods.com/session_123',
          ));

      batchCubit.emit(batchCubit.state.copyWith(
        selectedBatch: testBatch,
        plans: [testPlan],
        selectedPlan: testPlan,
        selectedPlanIds: {'3'},
        pricing: testQuote,
      ));

      await tester.pumpWidget(buildTestApp(const RfpCheckoutScreen()));
      await tester.pumpAndSettle();

      final payBtn = find.text('PAY BOOKING AMOUNT: ₹920');
      expect(payBtn, findsOneWidget);

      await tester.tap(payBtn);
      await tester.pump();

      verify(() => mockCreateBooking(
            batchId: '1',
            planId: '3',
            locationId: any(named: 'locationId'),
            patchConfigs: any(named: 'patchConfigs'),
            paymentMethod: any(named: 'paymentMethod'),
            fullName: 'Ramesh Kumar',
            addressLine: 'Flat 402, Green Valley Apts',
            city: 'Gurugram',
            pincode: '122018',
            phone: '9876543210',
            addressId: 101,
          )).called(1);
    });
  });
}
