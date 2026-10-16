import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_booking.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_delivery.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_patch_config.dart';
import 'package:grocery_app/features/rfp/domain/entities/rfp_delivery_otp_status.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_booking_details_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_delivery_otp_status_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/get_delivery_schedule_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/pay_remaining_use_case.dart';
import 'package:grocery_app/features/rfp/domain/usecases/verify_rfp_payment_use_case.dart';
import 'package:grocery_app/features/rfp/presentation/cubit/rfp_dashboard_cubit.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_active_harvest_card.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_active_subscriber_view.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_deliveries_paused_view.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_delivery_otp_card.dart';
import 'package:grocery_app/features/rfp/presentation/widgets/rfp_seasonal_harvest_log.dart';

class MockGetActiveBookingUseCase extends Mock
    implements GetActiveBookingUseCase {}

class MockGetDeliveryScheduleUseCase extends Mock
    implements GetDeliveryScheduleUseCase {}

class MockGetUpcomingDeliveriesUseCase extends Mock
    implements GetUpcomingDeliveriesUseCase {}

class MockPayRemainingUseCase extends Mock implements PayRemainingUseCase {}

class MockVerifyRfpPaymentUseCase extends Mock
    implements VerifyRfpPaymentUseCase {}

class MockGetDeliveryOtpStatusUseCase extends Mock
    implements GetDeliveryOtpStatusUseCase {}

void main() {
  final sampleAddress = const RfpBookingAddress(
    fullName: 'Ravi Kumar',
    addressLine: 'A-204, Green Meadows',
    city: 'Dehradun',
    pincode: '248001',
    phone: '9876543210',
  );

  final sampleBooking = RfpBooking(
    id: 'bkg_01',
    batchId: 'batch_01',
    batchNumber: 8842,
    planId: 'plan_01',
    planName: 'Ritu Thali',
    status: 'active',
    startDate: DateTime(2026, 9, 1),
    endDate: DateTime(2026, 11, 24),
    patchConfigs: const [
      RfpPatchConfig(
        patchId: 'p1',
        patchLabel: 'P1',
        excludedVegetableIds: [],
        selectedWeight: 5.0,
        deliveryFrequency: 'twice_a_week',
      ),
    ],
    totalAmount: 18000,
    bookingAmountPaid: 10000,
    remainingAmount: 8000,
    bookedAt: DateTime(2026, 8, 20),
    address: sampleAddress,
    bookingPaid: true,
    remainingPaid: false,
    deliveryDays: const ['Monday', 'Thursday'],
  );

  final sampleDeliveries = [
    RfpDelivery(
      id: 'd1',
      weekNumber: 1,
      date: DateTime(2026, 9, 3),
      dayOfWeek: 'Monday',
      status: 'delivered',
      patches: const [
        RfpDeliveryPatch(
          patchId: 'p1',
          patchLabel: 'P1',
          weightKg: 5.0,
          includedVegetables: ['Carrots', 'Spinach', 'Methi'],
        ),
      ],
      description: 'First Basket',
    ),
    RfpDelivery(
      id: 'd2',
      weekNumber: 2,
      date: DateTime(2026, 9, 10),
      dayOfWeek: 'Monday',
      status: 'cancelled',
      patches: const [],
      description: 'Weekend Special',
      cancellationReason: 'Road blockage due to landslides.',
    ),
    RfpDelivery(
      id: 'd3',
      weekNumber: 3,
      date: DateTime(2026, 9, 17),
      dayOfWeek: 'Monday',
      status: 'upcoming',
      patches: const [
        RfpDeliveryPatch(
          patchId: 'p1',
          patchLabel: 'P1',
          weightKg: 5.0,
          includedVegetables: ['Tomatoes', 'Broccoli', 'Potatoes'],
        ),
      ],
      description: 'Packing station: Crating at cold room 2',
    ),
  ];

  group('RfpActiveSubscriberView', () {
    testWidgets(
      'renders ledger notice, active order card, and seasonal harvest log',
      (tester) async {
        bool payNowTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RfpActiveSubscriberView(
                booking: sampleBooking,
                deliveries: sampleDeliveries,
                onPayNow: () => payNowTapped = true,
              ),
            ),
          ),
        );

        // Ledger notice
        expect(find.text('HARVEST LEDGER NOTICE'), findsOneWidget);
        expect(find.text('Pay Now'), findsOneWidget);

        await tester.tap(find.text('Pay Now'));
        expect(payNowTapped, isTrue);

        // Active harvest order card
        expect(find.text('● ACTIVE HARVEST ORDER'), findsOneWidget);
        expect(find.text('Batch No. #8842'), findsOneWidget);
        expect(find.text('UPCOMING DISPATCH'), findsOneWidget);
        expect(find.text('Ritu Thali'), findsOneWidget);
        expect(find.text('5KG • 2x/week'), findsOneWidget);
        expect(find.text('Freshly Picked This Run'), findsOneWidget);
        expect(find.text('Harvested Morning of Delivery'), findsOneWidget);
        expect(find.text('View Details'), findsOneWidget);

        // 12-Week Harvest Log
        expect(find.text('SEASONAL JOURNEY'), findsOneWidget);
        expect(find.text('12-Week Harvest Log'), findsOneWidget);
        expect(find.text('CANCELLED / DELAYED'), findsOneWidget);
        expect(find.text('"Road blockage due to landslides."'), findsOneWidget);
      },
    );
  });

  group('RfpSeasonalHarvestLog Filtering & Edge Cases', () {
    testWidgets('allows viewing schedule by week and resets to all', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RfpSeasonalHarvestLog(
                booking: sampleBooking,
                deliveries: sampleDeliveries,
              ),
            ),
          ),
        ),
      );

      // All 3 deliveries initially visible
      expect(find.text('Week 1 • First Basket'), findsOneWidget);
      expect(find.text('Week 2 • Mid-Week Batch'), findsOneWidget);
      expect(find.text('Week 3 • Mon Dispatch'), findsOneWidget);

      // Tap Week 1 filter chip
      await tester.tap(find.text('Week 1'));
      await tester.pumpAndSettle();

      expect(find.text('Week 1 • First Basket'), findsOneWidget);
      expect(find.text('Week 2 • Mid-Week Batch'), findsNothing);
      expect(find.text('Week 3 • Mon Dispatch'), findsNothing);

      // Tap All filter chip
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('Week 1 • First Basket'), findsOneWidget);
      expect(find.text('Week 2 • Mid-Week Batch'), findsOneWidget);
      expect(find.text('Week 3 • Mon Dispatch'), findsOneWidget);
    });

    testWidgets('renders empty state when deliveries are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RfpSeasonalHarvestLog(
              booking: sampleBooking,
              deliveries: const [],
            ),
          ),
        ),
      );

      expect(
        find.text('No scheduled deliveries found for this subscription.'),
        findsOneWidget,
      );
    });
  });

  group('RfpDeliveriesPausedView', () {
    testWidgets(
      'renders paused notice, lockdown warning, allotments, schedule, and sticky pay bar',
      (tester) async {
        bool payRemainingTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: RfpDeliveriesPausedView(
              booking: sampleBooking,
              deliveries: sampleDeliveries,
              onPayRemaining: () => payRemainingTapped = true,
            ),
          ),
        );

        // Top paused notice card
        expect(find.text('HARVEST NOTICE'), findsOneWidget);
        expect(find.text('DELIVERIES PAUSED'), findsOneWidget);
        expect(find.text('Payment Due by Week 3: Oct 15th'), findsOneWidget);

        // Lockdown card
        expect(find.text('Ritu Thali'), findsOneWidget);
        expect(
          find.textContaining('Please clear your remaining balance'),
          findsOneWidget,
        );

        // Box allotment overview
        expect(find.text('Box Allotment Overview'), findsOneWidget);
        expect(find.text('Root Veg'), findsOneWidget);
        expect(find.text('Greens Tub'), findsOneWidget);
        expect(find.text('Winter Orcha...'), findsOneWidget);

        // Harvest schedule
        expect(find.text('Harvest Schedule'), findsOneWidget);
        expect(find.text('Action required'), findsOneWidget);
        expect(find.text('Week 1: Early Harvest'), findsOneWidget);
        expect(find.text('Week 3: Orchard & Roots'), findsOneWidget);
        expect(find.text('PAUSED'), findsOneWidget);

        // Sticky pay button
        expect(find.textContaining('PAY REMAINING'), findsOneWidget);

        await tester.tap(find.textContaining('PAY REMAINING'));
        expect(payRemainingTapped, isTrue);
      },
    );

    testWidgets('hides sticky pay bar when remaining amount is already paid', (
      tester,
    ) async {
      final paidBooking = sampleBooking.copyWith(
        remainingPaid: true,
        remainingAmount: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RfpDeliveriesPausedView(
            booking: paidBooking,
            deliveries: sampleDeliveries,
          ),
        ),
      );

      expect(find.textContaining('PAY REMAINING'), findsNothing);
    });
  });

  group('RfpDashboardCubit Pay Remaining & Payment Verification', () {
    late MockGetActiveBookingUseCase mockActiveBooking;
    late MockGetDeliveryScheduleUseCase mockSchedule;
    late MockGetUpcomingDeliveriesUseCase mockUpcoming;
    late MockPayRemainingUseCase mockPayRemaining;
    late MockVerifyRfpPaymentUseCase mockVerifyPayment;
    late RfpDashboardCubit cubit;

    setUp(() {
      mockActiveBooking = MockGetActiveBookingUseCase();
      mockSchedule = MockGetDeliveryScheduleUseCase();
      mockUpcoming = MockGetUpcomingDeliveriesUseCase();
      mockPayRemaining = MockPayRemainingUseCase();
      mockVerifyPayment = MockVerifyRfpPaymentUseCase();

      cubit = RfpDashboardCubit(
        getActiveBooking: mockActiveBooking,
        getDeliverySchedule: mockSchedule,
        getUpcomingDeliveries: mockUpcoming,
        payRemaining: mockPayRemaining,
        verifyPayment: mockVerifyPayment,
      );
    });

    test(
      'payRemaining blocks request if remaining amount is already paid',
      () async {
        final paidBooking = sampleBooking.copyWith(
          remainingPaid: true,
          remainingAmount: 0.0,
        );
        cubit.setInitialBooking(paidBooking);

        final res = await cubit.payRemaining();
        expect(res, isNull);
        expect(cubit.state.error, 'Remaining amount is already paid.');
        verifyZeroInteractions(mockPayRemaining);
      },
    );

    test(
      'payRemaining calls use case with backend numeric subscription ID',
      () async {
        final bookingWithNumericId = sampleBooking.copyWith(id: '42');
        cubit.setInitialBooking(bookingWithNumericId);

        when(() => mockPayRemaining(42)).thenAnswer(
          (_) async => {
            'success': true,
            'checkout_url': 'https://payment.gateway/pay/42',
            'merchant_transaction_id': 'MTX-42',
          },
        );

        final res = await cubit.payRemaining();
        expect(res, isNotNull);
        expect(res!['checkout_url'], 'https://payment.gateway/pay/42');
        expect(res['merchant_transaction_id'], 'MTX-42');
        verify(() => mockPayRemaining(42)).called(1);
      },
    );

    test('verifyRemainingPayment reloads dashboard upon SUCCESS', () async {
      cubit.setInitialBooking(sampleBooking);

      when(
        () => mockVerifyPayment('MTX-42'),
      ).thenAnswer((_) async => {'success': true, 'status': 'SUCCESS'});
      when(() => mockActiveBooking()).thenAnswer(
        (_) async =>
            sampleBooking.copyWith(remainingPaid: true, remainingAmount: 0.0),
      );
      when(() => mockSchedule(any())).thenAnswer((_) async => sampleDeliveries);
      when(() => mockUpcoming(any())).thenAnswer((_) async => []);

      final success = await cubit.verifyRemainingPayment('MTX-42');
      expect(success, isTrue);
      expect(cubit.state.activeBooking?.remainingPaid, isTrue);
    });

    test(
      'verifyRemainingPayment returns false upon verification failure',
      () async {
        cubit.setInitialBooking(sampleBooking);

        when(
          () => mockVerifyPayment('MTX-42'),
        ).thenAnswer((_) async => {'success': false, 'status': 'FAILED'});

        final success = await cubit.verifyRemainingPayment('MTX-42');
        expect(success, isFalse);
      },
    );

    test(
      'checkDeliveryOtpStatus updates activeOtpStatus in cubit state',
      () async {
        final mockOtpUseCase = MockGetDeliveryOtpStatusUseCase();
        final otpCubit = RfpDashboardCubit(
          getActiveBooking: mockActiveBooking,
          getDeliverySchedule: mockSchedule,
          getUpcomingDeliveries: mockUpcoming,
          getDeliveryOtpStatus: mockOtpUseCase,
        );

        final outDelivery = RfpDelivery(
          id: 'd_out_42',
          weekNumber: 4,
          date: DateTime.now(),
          dayOfWeek: 'Monday',
          status: 'out_for_delivery',
          patches: const [],
        );
        otpCubit.emit(
          otpCubit.state.copyWith(upcomingDeliveries: [outDelivery]),
        );

        when(() => mockOtpUseCase('d_out_42')).thenAnswer(
          (_) async =>
              const RfpDeliveryOtpStatus(state: 'ACTIVE', otp: '998877'),
        );

        await otpCubit.checkDeliveryOtpStatus('d_out_42');
        expect(otpCubit.state.activeOtpStatus?.isActive, isTrue);
        expect(otpCubit.state.activeOtpStatus?.otp, '998877');
        verify(() => mockOtpUseCase('d_out_42')).called(1);
      },
    );
  });

  group('RfpDeliveryOtpCard & Active OTP flow', () {
    const activeOtp = RfpDeliveryOtpStatus(state: 'ACTIVE', otp: '789123');

    testWidgets(
      'RfpDeliveryOtpCard displays prominent OTP digits and security badge',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: RfpDeliveryOtpCard(otpStatus: activeOtp)),
          ),
        );

        expect(find.text('DELIVERY VERIFICATION OTP'), findsOneWidget);
        expect(find.textContaining('7  8  9  1  2  3'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
        expect(find.text('Doorstep Security'), findsOneWidget);
      },
    );

    testWidgets(
      'RfpDeliveryOtpCard displays awaiting state when out for delivery without active OTP',
      (tester) async {
        bool refreshed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RfpDeliveryOtpCard(
                isOutForDelivery: true,
                otpStatus: null,
                onRefresh: () => refreshed = true,
              ),
            ),
          ),
        );

        expect(find.text('OUT FOR DELIVERY'), findsOneWidget);
        expect(find.text('Waiting for agent OTP...'), findsOneWidget);
        expect(find.text('Check OTP'), findsOneWidget);

        await tester.tap(find.text('Check OTP'));
        await tester.pump();
        expect(refreshed, isTrue);
      },
    );

    testWidgets(
      'RfpDeliveryOtpCard displays expired notice when previous OTP expired',
      (tester) async {
        final expiredOtp = RfpDeliveryOtpStatus(
          state: 'ACTIVE',
          otp: '123456',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RfpDeliveryOtpCard(
                isOutForDelivery: true,
                otpStatus: expiredOtp,
              ),
            ),
          ),
        );

        expect(find.text('OUT FOR DELIVERY'), findsOneWidget);
        expect(find.text('Ask agent for a new code'), findsOneWidget);
      },
    );

    testWidgets(
      'RfpActiveSubscriberView renders RfpDeliveryOtpCard when otpStatus is ACTIVE',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RfpActiveSubscriberView(
                booking: sampleBooking,
                deliveries: sampleDeliveries,
                otpStatus: activeOtp,
              ),
            ),
          ),
        );

        expect(find.byType(RfpDeliveryOtpCard), findsOneWidget);
        expect(find.text('DELIVERY VERIFICATION OTP'), findsOneWidget);
        expect(find.textContaining('7  8  9  1  2  3'), findsOneWidget);
      },
    );

    testWidgets(
      'RfpActiveSubscriberView renders RfpDeliveryOtpCard awaiting state when delivery is OUT_FOR_DELIVERY',
      (tester) async {
        final outDelivery = RfpDelivery(
          id: 'd_out',
          weekNumber: 4,
          date: DateTime.now(),
          dayOfWeek: 'Monday',
          status: 'out_for_delivery',
          patches: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RfpActiveSubscriberView(
                booking: sampleBooking,
                deliveries: [outDelivery],
                otpStatus: null,
              ),
            ),
          ),
        );

        expect(find.byType(RfpDeliveryOtpCard), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(RfpDeliveryOtpCard),
            matching: find.text('OUT FOR DELIVERY'),
          ),
          findsOneWidget,
        );
        expect(find.text('Waiting for agent OTP...'), findsOneWidget);
      },
    );

    testWidgets(
      'RfpActiveHarvestCard renders OUT FOR DELIVERY and OTP badge when out for delivery',
      (tester) async {
        final outDelivery = RfpDelivery(
          id: 'd_out',
          weekNumber: 4,
          date: DateTime.now(),
          dayOfWeek: 'Monday',
          status: 'out_for_delivery',
          patches: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RfpActiveHarvestCard(
                booking: sampleBooking,
                deliveries: [outDelivery],
                otpStatus: activeOtp,
              ),
            ),
          ),
        );

        expect(find.text('OUT FOR DELIVERY'), findsOneWidget);
        expect(find.text('OTP: 789123'), findsOneWidget);
      },
    );

    testWidgets(
      'RfpDeliveryOtpCard updates in real time when new OTP is ingested',
      (tester) async {
        final outDelivery = RfpDelivery(
          id: 'd_out',
          weekNumber: 4,
          date: DateTime.now(),
          dayOfWeek: 'Monday',
          status: 'out_for_delivery',
          patches: const [],
        );

        final cubit = RfpDashboardCubit(
          getActiveBooking: MockGetActiveBookingUseCase(),
          getDeliverySchedule: MockGetDeliveryScheduleUseCase(),
          getUpcomingDeliveries: MockGetUpcomingDeliveriesUseCase(),
        );

        cubit.setInitialBooking(sampleBooking);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return RfpActiveSubscriberView(
                    booking: sampleBooking,
                    deliveries: [outDelivery],
                    otpStatus: cubit.state.activeOtpStatus,
                  );
                },
              ),
            ),
          ),
        );

        // Initially awaiting OTP
        expect(find.text('Waiting for agent OTP...'), findsOneWidget);

        // Delivery agent generates OTP -> ingested live
        cubit.ingestLiveOtp(otp: '654321');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RfpActiveSubscriberView(
                booking: sampleBooking,
                deliveries: [outDelivery],
                otpStatus: cubit.state.activeOtpStatus,
              ),
            ),
          ),
        );

        expect(find.textContaining('6  5  4  3  2  1'), findsOneWidget);
        expect(
          find.text(
            'Share this OTP with your delivery agent to receive your fresh harvest box:',
          ),
          findsOneWidget,
        );

        // Delivery agent re-generates OTP -> new OTP ingested live
        cubit.ingestLiveOtp(otp: '998877');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RfpActiveSubscriberView(
                booking: sampleBooking,
                deliveries: [outDelivery],
                otpStatus: cubit.state.activeOtpStatus,
              ),
            ),
          ),
        );

        expect(find.textContaining('9  9  8  8  7  7'), findsOneWidget);
        expect(find.textContaining('6  5  4  3  2  1'), findsNothing);
      },
    );
  });
}
