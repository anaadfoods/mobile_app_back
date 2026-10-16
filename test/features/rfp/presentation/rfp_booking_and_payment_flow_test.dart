import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_batch.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_booking.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_patch_config.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_plan_pricing.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_pricing.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_vegetable.dart';
import 'package:grocery_app/features/rfp/domain/entities/user_address.dart';
import 'package:grocery_app/features/rfp/domain/usecases/create_booking_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/calculate_pricing_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/verify_rfp_payment_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_user_addresses_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/save_user_address_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_batches_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_plans_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_patches_use_case.dart';
import 'package:grocery_app/features/rfp/data/repositories/rfp_payload_builder.dart';
import 'package:grocery_app/features/rfp/data/models/rfp_batch_model.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_checkout_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_batch_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/screens/rfp_checkout_screen.dart';

class MockCreateBookingUseCase extends Mock implements CreateBookingUseCase {}
class MockCalculatePricingUseCase extends Mock implements CalculatePricingUseCase {}
class MockVerifyRfpPaymentUseCase extends Mock implements VerifyRfpPaymentUseCase {}
class MockGetUserAddressesUseCase extends Mock implements GetUserAddressesUseCase {}
class MockSaveUserAddressUseCase extends Mock implements SaveUserAddressUseCase {}
class MockGetBatchesUseCase extends Mock implements GetBatchesUseCase {}
class MockGetPlansUseCase extends Mock implements GetPlansUseCase {}
class MockGetPatchesUseCase extends Mock implements GetPatchesUseCase {}

void main() {
  late MockCreateBookingUseCase mockCreateBooking;
  late MockCalculatePricingUseCase mockCalculatePricing;
  late MockVerifyRfpPaymentUseCase mockVerifyPayment;
  late MockGetUserAddressesUseCase mockGetUserAddresses;
  late MockSaveUserAddressUseCase mockSaveUserAddress;
  late MockGetBatchesUseCase mockGetBatches;
  late MockGetPlansUseCase mockGetPlans;
  late MockGetPatchesUseCase mockGetPatches;

  late RfpCheckoutCubit checkoutCubit;
  late RfpBatchCubit batchCubit;

  final testVeggies1 = [
    const RfpVegetable(id: '1', name: 'Organic Spinach', description: 'Leafy', season: 'winter', isDefaultSelected: true),
    const RfpVegetable(id: '2', name: 'Cherry Tomatoes', description: 'Vine', season: 'winter', isDefaultSelected: true),
    const RfpVegetable(id: '3', name: 'Bell Peppers', description: 'Fruit', season: 'winter', isDefaultSelected: false),
  ];

  final testVeggies2 = [
    const RfpVegetable(id: '4', name: 'Hydroponic Lettuce', description: 'Leafy', season: 'winter', isDefaultSelected: true),
    const RfpVegetable(id: '5', name: 'Cucumber', description: 'Vine', season: 'winter', isDefaultSelected: true),
  ];

  final testPlan1 = RfpPlan(
    id: 'plan_1',
    name: 'Daily Greens Thali',
    tier: 'premium',
    description: 'Fresh daily greens',
    totalPrice: 10000.0,
    bookingAmount: 1000.0,
    remainingAmount: 9000.0,
    features: const ['12 Deliveries'],
    availableVegetables: testVeggies1,
    selectionLimit: 2,
    maxDeselectableCount: 2,
    pricings: const [
      RfpPlanPricing(id: 11, variantName: 'SMALL', weightKg: 2.5, frequencyPerWeek: 1, pricePerDelivery: 350.0),
      RfpPlanPricing(id: 12, variantName: 'MEDIUM', weightKg: 5.0, frequencyPerWeek: 2, pricePerDelivery: 650.0),
    ],
  );

  final testPlan2 = RfpPlan(
    id: 'plan_2',
    name: 'Salad Harvest Thali',
    tier: 'standard',
    description: 'Crisp fresh salad',
    totalPrice: 8000.0,
    bookingAmount: 800.0,
    remainingAmount: 7200.0,
    features: const ['12 Deliveries'],
    availableVegetables: testVeggies2,
    selectionLimit: 2,
    maxDeselectableCount: 1,
    pricings: const [
      RfpPlanPricing(id: 21, variantName: 'SMALL', weightKg: 3.0, frequencyPerWeek: 1, pricePerDelivery: 400.0),
    ],
  );

  final testBatch = RfpBatch(
    id: '1',
    batchNumber: 1,
    seasonLabel: 'Winter Harvest Batch #1',
    startDate: DateTime(2026, 11, 1),
    endDate: DateTime(2027, 1, 24),
    currentWeek: 1,
    status: 'active',
    progressPercent: 0.1,
    totalWeeks: 12,
    plans: [testPlan1, testPlan2],
  );

  final testAddress = const UserAddress(
    id: 101,
    fullName: 'Shivangi Sharma',
    phoneNumber: '9876543210',
    addressLine1: 'Tower 4, Green Valley',
    city: 'Gurugram',
    state: 'Haryana',
    pincode: '122018',
    isDefault: true,
    label: 'HOME',
  );

  final testPricing = const RfpPricing(
    basePrice: 8400.0,
    discountAmount: 420.0,
    discountPercentage: 5.0,
    finalPrice: 7980.0,
    bookingAmount: 798.0,
    remainingAmount: 7182.0,
    deliveriesCount: 24,
    remainingDeliveries: 22,
  );

  setUpAll(() {
    registerFallbackValue(const RfpPatchConfig(
      patchId: '1',
      patchLabel: 'P1',
      excludedVegetableIds: [],
      selectedWeight: 2.5,
      deliveryFrequency: 'once_a_week',
    ));
    registerFallbackValue(testAddress);
  });

  setUp(() {
    mockCreateBooking = MockCreateBookingUseCase();
    mockCalculatePricing = MockCalculatePricingUseCase();
    mockVerifyPayment = MockVerifyRfpPaymentUseCase();
    mockGetUserAddresses = MockGetUserAddressesUseCase();
    mockSaveUserAddress = MockSaveUserAddressUseCase();
    mockGetBatches = MockGetBatchesUseCase();
    mockGetPlans = MockGetPlansUseCase();
    mockGetPatches = MockGetPatchesUseCase();

    when(() => mockGetUserAddresses()).thenAnswer((_) async => [testAddress]);
    when(() => mockCalculatePricing(
          planId: any(named: 'planId'),
          patchConfigs: any(named: 'patchConfigs'),
          batchId: any(named: 'batchId'),
        )).thenAnswer((_) async => testPricing);

    checkoutCubit = RfpCheckoutCubit(
      createBooking: mockCreateBooking,
      calculatePricing: mockCalculatePricing,
      verifyPayment: mockVerifyPayment,
      getUserAddresses: mockGetUserAddresses,
      saveUserAddress: mockSaveUserAddress,
    );

    batchCubit = RfpBatchCubit(
      getBatches: mockGetBatches,
      getPlans: mockGetPlans,
      getPatches: mockGetPatches,
      calculatePricing: mockCalculatePricing,
    );
  });

  tearDown(() {
    checkoutCubit.close();
    batchCubit.close();
  });

  Widget buildTestApp(Widget child) {
    final router = GoRouter(
      initialLocation: '/rfp/checkout',
      routes: [
        GoRoute(
          path: '/rfp/checkout',
          builder: (context, state) => child,
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
        BlocProvider<RfpCheckoutCubit>.value(value: checkoutCubit),
        BlocProvider<RfpBatchCubit>.value(value: batchCubit),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('RfpPayloadBuilder & Exact Payload Requirements', () {
    test('builds exact backend payload without UI-only fields', () {
      final patchConfigs = [
        const RfpPatchConfig(
          patchId: 'plan_1',
          patchLabel: 'Daily Greens',
          excludedVegetableIds: [],
          selectedWeight: 2.5,
          deliveryFrequency: 'once_a_week',
          planPricingId: 11,
          selectedVegetableIds: ['1', '2'],
          deliveryDays: ['Monday'],
        ),
        const RfpPatchConfig(
          patchId: 'plan_2',
          patchLabel: 'Salad Thali',
          excludedVegetableIds: [],
          selectedWeight: 3.0,
          deliveryFrequency: 'twice_a_week',
          planPricingId: 21,
          selectedVegetableIds: ['4', '5'],
          deliveryDays: ['Monday', 'Thursday'],
        ),
      ];

      final List<RfpBatchModel> batches = [
        RfpBatchModel(
          id: '1',
          batchNumber: 1,
          seasonLabel: 'Batch #1',
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2027, 1, 24),
          currentWeek: 1,
          status: 'active',
          progressPercent: 0.1,
          totalWeeks: 12,
          plans: [testPlan1, testPlan2],
        ),
      ];

      final batchId = RfpPayloadBuilder.findBatchId('plan_1', batches);
      expect(batchId, 1);

      final days = RfpPayloadBuilder.buildDeliveryDays(patchConfigs);
      expect(days.length, 2);
      expect(days, ['Monday', 'Thursday']);

      final plansPayload = RfpPayloadBuilder.buildPlansPayload('plan_1', patchConfigs, batches);
      expect(plansPayload.length, 2);
      expect(plansPayload[0]['plan_pricing_id'], 11);
      expect(plansPayload[0]['vegetable_ids'], [1, 2]);
      expect(plansPayload[1]['plan_pricing_id'], 21);
      expect(plansPayload[1]['vegetable_ids'], [4, 5]);

      // Verify no UI-only fields in plans payload
      expect(plansPayload[0].containsKey('fullName'), isFalse);
      expect(plansPayload[0].containsKey('paymentMethod'), isFalse);
      expect(plansPayload[0].containsKey('pincode'), isFalse);
    });
  });

  group('RfpCheckoutCubit Booking Submission', () {
    test('submits booking and returns payment info without marking subscription ACTIVE', () async {
      checkoutCubit.selectSavedAddress(testAddress);

      final pendingBooking = RfpBooking(
        id: 'sub_123',
        batchId: '1',
        batchNumber: 1,
        planId: 'plan_1',
        planName: 'Daily Greens Thali',
        status: 'pending_payment',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 84)),
        patchConfigs: const [],
        totalAmount: 7980.0,
        bookingAmountPaid: 798.0,
        remainingAmount: 7182.0,
        bookedAt: DateTime.now(),
        address: const RfpBookingAddress(
          fullName: 'Shivangi Sharma',
          addressLine: 'Tower 4, Green Valley',
          city: 'Gurugram',
          pincode: '122018',
          phone: '9876543210',
        ),
        merchantTransactionId: 'TX_987654321',
        checkoutUrl: 'https://gateway.anaadfoods.com/pay/session_abc',
      );

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
          )).thenAnswer((_) async => pendingBooking);

      final result = await checkoutCubit.submitBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: const [],
      );

      expect(result, isNotNull);
      expect(result!.merchantTransactionId, 'TX_987654321');
      expect(result.checkoutUrl, 'https://gateway.anaadfoods.com/pay/session_abc');
      expect(result.status, 'pending_payment');
      expect(result.isActive, isFalse);

      expect(checkoutCubit.state.status, CheckoutStatus.loaded);
      expect(checkoutCubit.state.merchantTransactionId, 'TX_987654321');
      expect(checkoutCubit.state.checkoutUrl, 'https://gateway.anaadfoods.com/pay/session_abc');
    });

    test('prevents duplicate booking requests while in-flight', () async {
      checkoutCubit.selectSavedAddress(testAddress);

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
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return RfpBooking(
          id: 'sub_123',
          batchId: '1',
          batchNumber: 1,
          planId: 'plan_1',
          planName: 'Daily Greens Thali',
          status: 'pending_payment',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 84)),
          patchConfigs: const [],
          totalAmount: 7980.0,
          bookingAmountPaid: 798.0,
          remainingAmount: 7182.0,
          bookedAt: DateTime.now(),
          address: const RfpBookingAddress(
            fullName: 'Shivangi Sharma',
            addressLine: 'Tower 4',
            city: 'Gurugram',
            pincode: '122018',
            phone: '9876543210',
          ),
        );
      });

      final f1 = checkoutCubit.submitBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: const [],
      );

      final f2 = checkoutCubit.submitBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: const [],
      );

      final r2 = await f2;
      expect(r2, isNull);

      final r1 = await f1;
      expect(r1, isNotNull);
      verify(() => mockCreateBooking(
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
          )).called(1);
    });

    test('handles ALREADY_BOOKED backend error code user-friendly', () async {
      checkoutCubit.selectSavedAddress(testAddress);

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
          )).thenThrow(Exception('ALREADY_BOOKED'));

      final result = await checkoutCubit.submitBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: const [],
      );

      expect(result, isNull);
      expect(checkoutCubit.state.status, CheckoutStatus.error);
      expect(checkoutCubit.state.error, 'You already have an active subscription for this batch.');
    });

    test('handles BATCH_FULL backend error code user-friendly', () async {
      checkoutCubit.selectSavedAddress(testAddress);

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
          )).thenThrow(Exception('BATCH_FULL'));

      await checkoutCubit.submitBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: const [],
      );

      expect(checkoutCubit.state.status, CheckoutStatus.error);
      expect(checkoutCubit.state.error, 'This farming batch is currently full. Booking is closed.');
    });

    test('handles INVALID_SELECTION backend error code user-friendly', () async {
      checkoutCubit.selectSavedAddress(testAddress);

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
          )).thenThrow(Exception('INVALID_SELECTION'));

      await checkoutCubit.submitBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: const [],
      );

      expect(checkoutCubit.state.status, CheckoutStatus.error);
      expect(checkoutCubit.state.error, 'Invalid selection. Please review your vegetable and plan choices.');
    });

    test('handles PLAN_FULL backend error code user-friendly', () async {
      checkoutCubit.selectSavedAddress(testAddress);

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
            paymentType: any(named: 'paymentType'),
            addressId: any(named: 'addressId'),
          )).thenThrow(Exception('[PLAN_FULL] The plan is full'));

      await checkoutCubit.submitBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: const [],
      );

      expect(checkoutCubit.state.status, CheckoutStatus.error);
      expect(checkoutCubit.state.error, 'The selected plan is currently full. Please choose another plan or variant.');
    });

    test('selectPaymentType updates paymentType in state and forwards to createBooking', () async {
      checkoutCubit.selectSavedAddress(testAddress);
      checkoutCubit.selectPaymentType('full');
      expect(checkoutCubit.state.paymentType, 'full');
      expect(checkoutCubit.state.isFullPaymentSelected, isTrue);

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
            paymentType: any(named: 'paymentType'),
            addressId: any(named: 'addressId'),
          )).thenAnswer((_) async => RfpBooking(
            id: 'sub_full_1',
            batchId: '1',
            batchNumber: 1,
            planId: 'plan_1',
            planName: 'Daily Greens Thali',
            status: 'pending_payment',
            paymentType: 'full',
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 84)),
            patchConfigs: const [],
            totalAmount: 13035.0,
            bookingAmountPaid: 13035.0,
            remainingAmount: 0.0,
            bookedAt: DateTime.now(),
            address: const RfpBookingAddress(
              fullName: 'Shivangi Sharma',
              addressLine: 'Tower 4',
              city: 'Gurugram',
              pincode: '122018',
              phone: '9876543210',
            ),
          ));

      final result = await checkoutCubit.submitBooking(
        batchId: '1',
        planId: 'plan_1',
        locationId: 'loc_01',
        patchConfigs: const [],
      );

      expect(result, isNotNull);
      expect(result!.paymentType, 'full');
      expect(result.isFullPayment, isTrue);
    });
  });

  group('RfpCheckoutCubit Payment Verification', () {
    test('does not invent transaction ID and errors if missing', () async {
      final success = await checkoutCubit.verifyPayment();
      expect(success, isFalse);
      expect(checkoutCubit.state.status, CheckoutStatus.error);
      expect(checkoutCubit.state.error, 'No merchant transaction ID found to verify payment.');
      expect(checkoutCubit.state.isVerifyingPayment, isFalse);
    });

    test('prevents duplicate verification requests', () async {
      checkoutCubit.emit(checkoutCubit.state.copyWith(
        merchantTransactionId: 'TX_111',
        isVerifyingPayment: true,
      ));

      final result = await checkoutCubit.verifyPayment('TX_111');
      expect(result, isFalse);
    });

    test('handles SUCCESS: marks subscription active and transitions to CheckoutStatus.success', () async {
      checkoutCubit.emit(checkoutCubit.state.copyWith(
        merchantTransactionId: 'TX_111',
        booking: RfpBooking(
          id: 'sub_123',
          batchId: '1',
          batchNumber: 1,
          planId: 'plan_1',
          planName: 'Daily Greens Thali',
          status: 'pending_payment',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 84)),
          patchConfigs: const [],
          totalAmount: 7980.0,
          bookingAmountPaid: 798.0,
          remainingAmount: 7182.0,
          bookedAt: DateTime.now(),
          address: const RfpBookingAddress(
            fullName: 'Shivangi Sharma',
            addressLine: 'Tower 4',
            city: 'Gurugram',
            pincode: '122018',
            phone: '9876543210',
          ),
          merchantTransactionId: 'TX_111',
        ),
      ));

      when(() => mockVerifyPayment('TX_111')).thenAnswer((_) async => {
        'status': 'SUCCESS',
        'message': 'Payment successfully reconciled',
        'subscription_id': 'sub_123',
      });

      final success = await checkoutCubit.verifyPayment('TX_111');

      expect(success, isTrue);
      expect(checkoutCubit.state.status, CheckoutStatus.success);
      expect(checkoutCubit.state.booking?.status, 'active');
      expect(checkoutCubit.state.booking?.bookingPaid, isTrue);
      expect(checkoutCubit.state.isVerifyingPayment, isFalse);
    });

    test('handles verification failure: does not mark active and allows retry', () async {
      checkoutCubit.emit(checkoutCubit.state.copyWith(
        merchantTransactionId: 'TX_111',
        booking: RfpBooking(
          id: 'sub_123',
          batchId: '1',
          batchNumber: 1,
          planId: 'plan_1',
          planName: 'Daily Greens Thali',
          status: 'pending_payment',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 84)),
          patchConfigs: const [],
          totalAmount: 7980.0,
          bookingAmountPaid: 798.0,
          remainingAmount: 7182.0,
          bookedAt: DateTime.now(),
          address: const RfpBookingAddress(
            fullName: 'Shivangi Sharma',
            addressLine: 'Tower 4',
            city: 'Gurugram',
            pincode: '122018',
            phone: '9876543210',
          ),
          merchantTransactionId: 'TX_111',
        ),
      ));

      when(() => mockVerifyPayment('TX_111')).thenAnswer((_) async => {
        'status': 'FAILED',
        'message': 'Transaction was cancelled by user',
      });

      final success = await checkoutCubit.verifyPayment('TX_111');

      expect(success, isFalse);
      expect(checkoutCubit.state.status, CheckoutStatus.error);
      expect(checkoutCubit.state.error, 'Transaction was cancelled by user');
      expect(checkoutCubit.state.verificationFailed, isTrue);
      expect(checkoutCubit.state.booking?.status, 'pending_payment');
      expect(checkoutCubit.state.booking?.isActive, isFalse);
    });
  });

  group('Checkout Screen Component Placement & All Thali Display', () {
    testWidgets('renders all selected Thalis and their curated vegetable chips', (tester) async {
      batchCubit.emit(batchCubit.state.copyWith(
        selectedBatch: testBatch,
        batches: [testBatch],
        plans: [testPlan1, testPlan2],
        selectedPlanIds: {'plan_1', 'plan_2'},
        planConfigurations: {
          'plan_1': const RfpPlanConfig(
            planId: 'plan_1',
            selectedPricing: RfpPlanPricing(id: 11, variantName: 'SMALL', weightKg: 2.5, frequencyPerWeek: 1, pricePerDelivery: 350),
            selectedVegetableIds: {'1', '2'},
            selectedFrequency: 1,
            isConfigured: true,
          ),
          'plan_2': const RfpPlanConfig(
            planId: 'plan_2',
            selectedPricing: RfpPlanPricing(id: 21, variantName: 'SMALL', weightKg: 3.0, frequencyPerWeek: 1, pricePerDelivery: 400),
            selectedVegetableIds: {'4', '5'},
            selectedFrequency: 1,
            isConfigured: true,
          ),
        },
        pricing: testPricing,
      ));

      await tester.pumpWidget(buildTestApp(const RfpCheckoutScreen()));
      await tester.pumpAndSettle();

      // Check both Thali headers are rendered
      expect(find.textContaining('Daily Greens Thali'), findsOneWidget);
      expect(find.textContaining('Salad Harvest Thali'), findsOneWidget);

      // Check vegetable chips for both Thalis are displayed
      expect(find.text('Organic Spinach'), findsOneWidget);
      expect(find.text('Cherry Tomatoes'), findsOneWidget);
      expect(find.text('Hydroponic Lettuce'), findsOneWidget);
      expect(find.text('Cucumber'), findsOneWidget);

      // Check delivery destination connected via UserAddress
      expect(find.text('Shivangi Sharma'), findsOneWidget);
      expect(find.text('Tower 4, Green Valley'), findsOneWidget);
    });
  });
}
