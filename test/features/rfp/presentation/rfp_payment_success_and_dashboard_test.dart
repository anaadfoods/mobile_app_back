import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_booking.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_delivery.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_patch_config.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_pricing.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_booking_details_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_delivery_schedule_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/pay_remaining_use_case.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_checkout_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_dashboard_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/screens/rfp_payment_success_screen.dart';
import 'package:grocery_app/features/rfp/presentation/screens/rfp_dashboard_screen.dart';

class MockGetActiveBookingUseCase extends Mock
    implements GetActiveBookingUseCase {}

class MockGetDeliveryScheduleUseCase extends Mock
    implements GetDeliveryScheduleUseCase {}

class MockGetUpcomingDeliveriesUseCase extends Mock
    implements GetUpcomingDeliveriesUseCase {}

class MockGetBookingDetailsUseCase extends Mock
    implements GetBookingDetailsUseCase {}

class MockPayRemainingUseCase extends Mock implements PayRemainingUseCase {}

class MockRfpCheckoutCubit extends Mock implements RfpCheckoutCubit {}

void main() {
  late MockGetActiveBookingUseCase mockGetActiveBooking;
  late MockGetDeliveryScheduleUseCase mockGetDeliverySchedule;
  late MockGetUpcomingDeliveriesUseCase mockGetUpcomingDeliveries;
  late MockGetBookingDetailsUseCase mockGetBookingDetails;
  late MockPayRemainingUseCase mockPayRemaining;
  late RfpDashboardCubit dashboardCubit;
  late MockRfpCheckoutCubit mockCheckoutCubit;

  final testBooking = RfpBooking(
    id: 'sub_58',
    batchId: '1',
    batchNumber: 1,
    batchName: 'Oct-Jan 2026 Batch — Cohort 01',
    planId: 'plan_3',
    planName: 'RITU THALI',
    status: 'ACTIVE',
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 12, 24),
    patchConfigs: const [
      RfpPatchConfig(
        patchId: 'patch_1',
        patchLabel: 'RITU THALI',
        excludedVegetableIds: [],
        selectedWeight: 2.5,
        deliveryFrequency: 'once_a_week',
      ),
    ],
    totalAmount: 10120,
    bookingAmountPaid: 920,
    remainingAmount: 9200,
    bookedAt: DateTime(2026, 10, 1),
    bookingPaid: true,
    remainingPaid: false,
    deliveryDays: const ['Monday'],
    address: const RfpBookingAddress(
      fullName: 'Jane Doe',
      addressLine: 'Flat 4B, Green Meadows',
      city: 'Pune',
      state: 'Maharashtra',
      pincode: '411001',
      phone: '9876543210',
    ),
    deliveries: [
      RfpDelivery(
        id: 'del_401',
        weekNumber: 1,
        date: DateTime(2026, 10, 5),
        status: 'pending',
        dayOfWeek: 'Monday',
        patches: const [],
      ),
      RfpDelivery(
        id: 'del_400',
        weekNumber: 0,
        date: DateTime(2026, 9, 28),
        status: 'delivered',
        dayOfWeek: 'Monday',
        patches: const [],
      ),
    ],
  );

  setUp(() {
    mockGetActiveBooking = MockGetActiveBookingUseCase();
    mockGetDeliverySchedule = MockGetDeliveryScheduleUseCase();
    mockGetUpcomingDeliveries = MockGetUpcomingDeliveriesUseCase();
    mockGetBookingDetails = MockGetBookingDetailsUseCase();
    mockPayRemaining = MockPayRemainingUseCase();
    mockCheckoutCubit = MockRfpCheckoutCubit();

    when(() => mockCheckoutCubit.stream).thenAnswer((_) => const Stream.empty());

    dashboardCubit = RfpDashboardCubit(
      getActiveBooking: mockGetActiveBooking,
      getDeliverySchedule: mockGetDeliverySchedule,
      getUpcomingDeliveries: mockGetUpcomingDeliveries,
      getBookingDetails: mockGetBookingDetails,
      payRemaining: mockPayRemaining,
    );
  });

  tearDown(() {
    dashboardCubit.close();
  });

  group('RfpPaymentSuccessScreen', () {
    testWidgets('renders pending view when payment is not yet verified', (tester) async {
      when(() => mockCheckoutCubit.state).thenReturn(
        const RfpCheckoutState(
          status: CheckoutStatus.loaded,
          isVerifyingPayment: false,
          booking: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RfpCheckoutCubit>.value(
            value: mockCheckoutCubit,
            child: const RfpPaymentSuccessScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Verification Pending'), findsOneWidget);
      expect(find.text('Return to Checkout'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
      expect(find.text('Payment Verified & Confirmed!'), findsNothing);
    });

    testWidgets('renders verified confirmation when verify-payment succeeds', (tester) async {
      when(() => mockCheckoutCubit.state).thenReturn(
        RfpCheckoutState(
          status: CheckoutStatus.success,
          merchantTransactionId: 'RFPSUB-58-BOOKING-05102026',
          booking: testBooking,
          pricing: const RfpPricing(
            basePrice: 10120,
            discountAmount: 0,
            finalPrice: 10120,
            bookingAmount: 920,
            remainingAmount: 9200,
            deliveriesCount: 12,
            remainingDeliveries: 10,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RfpCheckoutCubit>.value(
            value: mockCheckoutCubit,
            child: const RfpPaymentSuccessScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Verified & Confirmed!'), findsOneWidget);
      expect(find.textContaining('Oct-Jan 2026 Batch'), findsOneWidget);
      expect(find.text('#sub_58'), findsOneWidget);
      expect(find.text('₹920 paid'), findsOneWidget);
      expect(find.text('View Farm Dashboard'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
    });
  });

  group('RfpDashboardScreen', () {
    testWidgets('renders loading state when initial fetch is running', (tester) async {
      dashboardCubit.emit(const RfpDashboardState(isLoading: true));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RfpDashboardCubit>.value(
            value: dashboardCubit,
            child: const RfpDashboardScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state and retries on tap', (tester) async {
      dashboardCubit.emit(const RfpDashboardState(
        isLoading: false,
        error: 'Failed to connect to farming backend',
      ));

      when(() => mockGetActiveBooking()).thenAnswer((_) async => testBooking);
      when(() => mockGetDeliverySchedule('sub_58')).thenAnswer((_) async => testBooking.deliveries);
      when(() => mockGetUpcomingDeliveries('sub_58')).thenAnswer((_) async => [testBooking.deliveries.first]);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RfpDashboardCubit>.value(
            value: dashboardCubit,
            child: const RfpDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load subscription'), findsOneWidget);
      expect(find.text('Failed to connect to farming backend'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Oct-Jan 2026 Batch'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('renders empty state when customer has no active subscription', (tester) async {
      when(() => mockGetActiveBooking()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RfpDashboardCubit>.value(
            value: dashboardCubit,
            child: const RfpDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Active Subscription Found'), findsOneWidget);
      expect(find.text('Explore Batches'), findsOneWidget);
    });

    testWidgets('renders full active subscription dashboard with batch, plans, deliveries, and billing', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      dashboardCubit.emit(RfpDashboardState(
        isLoading: false,
        activeBooking: testBooking,
        upcomingDeliveries: [testBooking.deliveries.first],
        deliveryHistory: [testBooking.deliveries.last],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RfpDashboardCubit>.value(
            value: dashboardCubit,
            child: const RfpDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Batch name & status
      expect(find.text('Oct-Jan 2026 Batch — Cohort 01'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Delivery: Every Monday'), findsOneWidget);

      // Active Plans
      expect(find.text('Active Plans'), findsOneWidget);
      expect(find.textContaining('RITU THALI'), findsWidgets);

      // Delivery Timeline & Delivery History
      expect(find.text('Delivery Timeline'), findsOneWidget);
      expect(find.text('Delivery History'), findsOneWidget);
      expect(find.text('DELIVERED'), findsOneWidget);

      // Billing Overview & Remaining Balance
      expect(find.text('Billing Overview'), findsOneWidget);
      expect(find.text('₹9,200'), findsOneWidget);
      expect(find.text('Pay Remaining Balance'), findsOneWidget);
    });

    testWidgets('supports pull-to-refresh on dashboard', (tester) async {
      when(() => mockGetActiveBooking()).thenAnswer((_) async => testBooking);
      when(() => mockGetDeliverySchedule('sub_58')).thenAnswer((_) async => testBooking.deliveries);
      when(() => mockGetUpcomingDeliveries('sub_58')).thenAnswer((_) async => [testBooking.deliveries.first]);

      dashboardCubit.emit(RfpDashboardState(
        isLoading: false,
        activeBooking: testBooking,
        upcomingDeliveries: [testBooking.deliveries.first],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RfpDashboardCubit>.value(
            value: dashboardCubit,
            child: const RfpDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(find.text('Oct-Jan 2026 Batch — Cohort 01'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      verify(() => mockGetActiveBooking()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('renders RfpDeliveryOtpCard when delivery is out for delivery or active OTP exists', (tester) async {
      final outDelivery = RfpDelivery(
        id: 'del_out',
        weekNumber: 1,
        date: DateTime.now(),
        status: 'out_for_delivery',
        dayOfWeek: 'Monday',
        patches: const [],
      );

      dashboardCubit.emit(RfpDashboardState(
        isLoading: false,
        activeBooking: testBooking,
        upcomingDeliveries: [outDelivery],
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<RfpDashboardCubit>.value(
            value: dashboardCubit,
            child: const RfpDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OUT FOR DELIVERY'), findsOneWidget);
      expect(find.text('Waiting for agent OTP...'), findsOneWidget);
      expect(find.text('Check OTP'), findsOneWidget);
    });
  });
}
