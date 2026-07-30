import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:grocery_app/features/subscriptions/domain/entities/subscription_plan_entity.dart';
import 'package:grocery_app/features/subscriptions/domain/failures/subscription_failure.dart';
import 'package:grocery_app/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_user_subscriptions_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_details_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_plans_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/create_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/cancel_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/toggle_pause_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/repayment_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_invoices_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_plan_products_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/search_plans_for_variant_use_case.dart';
import 'package:grocery_app/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:grocery_app/features/subscriptions/presentation/cubit/subscription_state.dart';

// ─── Mocks ──────────────────────────────────────────────────────────

class MockGetUserSubscriptions extends Mock implements GetUserSubscriptionsUseCase {}
class MockGetSubscriptionDetails extends Mock implements GetSubscriptionDetailsUseCase {}
class MockGetSubscriptionPlans extends Mock implements GetSubscriptionPlansUseCase {}
class MockCreateSubscription extends Mock implements CreateSubscriptionUseCase {}
class MockCancelSubscription extends Mock implements CancelSubscriptionUseCase {}
class MockTogglePause extends Mock implements TogglePauseSubscriptionUseCase {}
class MockRepayment extends Mock implements RepaymentSubscriptionUseCase {}
class MockGetInvoices extends Mock implements GetSubscriptionInvoicesUseCase {}
class MockGetPlanProducts extends Mock implements GetSubscriptionPlanProductsUseCase {}
class MockSearchPlans extends Mock implements SearchPlansForVariantUseCase {}

// ─── Test Data ──────────────────────────────────────────────────────

SubscriptionEntity _makeSub({
  int id = 1,
  String status = 'ACTIVE',
  String paymentStatus = 'PAID_FULL',
  String paymentMethod = 'COD',
}) =>
    SubscriptionEntity(
      id: id, plan: 1, planName: 'SIDDH', startDate: '2026-06-09',
      endDate: '2027-06-04', status: status, paymentStatus: paymentStatus,
      paymentMethod: paymentMethod, deliveryAddress: 'Addr',
      deliveryCity: 'City', deliveryState: 'State', deliveryPincode: '123456',
      deliveryPhone: '9876543210', recipientName: 'Test', notes: '',
      subtotal: 100, deliveryCharges: 50, total: 150, amountPaid: 150,
      remainingAmount: 0, nextDeliveryDate: '2026-07-01',
      totalDeliveries: 12, completedDeliveries: 1, remainingPauseDays: 30,
      remainingPauseTimes: 3, createdAt: '2026-06-09',
      totalDeliveryCharges: 600, canPayNextInstallment: false, items: [],
    );

void main() {
  late MockGetUserSubscriptions mockGetSubs;
  late MockGetSubscriptionDetails mockGetDetails;
  late MockGetSubscriptionPlans mockGetPlans;
  late MockCreateSubscription mockCreate;
  late MockCancelSubscription mockCancel;
  late MockTogglePause mockTogglePause;
  late MockRepayment mockRepayment;
  late MockGetInvoices mockGetInvoices;
  late MockGetPlanProducts mockGetProducts;
  late MockSearchPlans mockSearch;

  SubscriptionCubit buildCubit() => SubscriptionCubit(
        getUserSubscriptions: mockGetSubs,
        getSubscriptionDetails: mockGetDetails,
        getSubscriptionPlans: mockGetPlans,
        createSubscription: mockCreate,
        cancelSubscription: mockCancel,
        togglePause: mockTogglePause,
        repayment: mockRepayment,
        getInvoices: mockGetInvoices,
        getPlanProducts: mockGetProducts,
        searchPlans: mockSearch,
      );

  setUp(() {
    mockGetSubs = MockGetUserSubscriptions();
    mockGetDetails = MockGetSubscriptionDetails();
    mockGetPlans = MockGetSubscriptionPlans();
    mockCreate = MockCreateSubscription();
    mockCancel = MockCancelSubscription();
    mockTogglePause = MockTogglePause();
    mockRepayment = MockRepayment();
    mockGetInvoices = MockGetInvoices();
    mockGetProducts = MockGetPlanProducts();
    mockSearch = MockSearchPlans();
  });

  group('SubscriptionCubit Characterization Tests', () {
    // ── Fetch & UPI filter ──────────────────────────────────────────

    blocTest<SubscriptionCubit, SubscriptionState>(
      'fetchUserSubscriptions emits Loading then Success with returned subscriptions',
      build: () {
        // The use case does the filtering; mock returns already-filtered data
        when(() => mockGetSubs()).thenAnswer((_) async => [
              _makeSub(id: 1, paymentMethod: 'COD', paymentStatus: 'PAID_FULL'),
              _makeSub(id: 3, paymentMethod: 'UPI', paymentStatus: 'PAID_FULL'),
            ]);
        return buildCubit();
      },
      act: (cubit) => cubit.fetchUserSubscriptions(),
      expect: () => [
        isA<SubscriptionLoading>(),
        isA<SubscriptionSuccess>()
            .having((s) => s.userSubscriptions.length, 'count', 2)
            .having((s) => s.userSubscriptions.map((e) => e.id).toList(),
                'ids', [1, 3]),
      ],
    );

    // ── Pause → Resume state transitions ────────────────────────────

    blocTest<SubscriptionCubit, SubscriptionState>(
      'togglePauseSubscription (pause) emits ActionSuccess then refreshes subscriptions',
      build: () {
        when(() => mockTogglePause(1, any(), any())).thenAnswer(
          (_) async => const PauseResponseEntity(message: 'Subscription paused'),
        );
        when(() => mockGetSubs()).thenAnswer((_) async => [
              _makeSub(id: 1, status: 'PAUSED'),
            ]);
        return buildCubit();
      },
      act: (cubit) => cubit.togglePauseSubscription(
        1,
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 15),
      ),
      expect: () => [
        isA<SubscriptionActionSuccess>()
            .having((s) => s.message, 'msg', 'Subscription paused'),
        isA<SubscriptionLoading>(),
        isA<SubscriptionSuccess>()
            .having((s) => s.userSubscriptions.first.status, 'status', 'PAUSED'),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'togglePauseSubscription (resume) emits ActionSuccess then refreshes subscriptions',
      build: () {
        when(() => mockTogglePause(1, null, null)).thenAnswer(
          (_) async => const PauseResponseEntity(message: 'Subscription resumed'),
        );
        when(() => mockGetSubs()).thenAnswer((_) async => [
              _makeSub(id: 1, status: 'ACTIVE'),
            ]);
        return buildCubit();
      },
      act: (cubit) => cubit.togglePauseSubscription(1, null, null),
      expect: () => [
        isA<SubscriptionActionSuccess>()
            .having((s) => s.message, 'msg', 'Subscription resumed'),
        isA<SubscriptionLoading>(),
        isA<SubscriptionSuccess>()
            .having((s) => s.userSubscriptions.first.status, 'status', 'ACTIVE'),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'togglePauseSubscription failure restores previous state',
      build: () {
        when(() => mockTogglePause(1, any(), any()))
            .thenThrow(SubscriptionFailure.pauseRejected('No pause days left'));
        return buildCubit();
      },
      act: (cubit) => cubit.togglePauseSubscription(
        1,
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 15),
      ),
      expect: () => [
        isA<SubscriptionError>()
            .having((s) => s.message, 'msg', contains('No pause days left')),
        isA<SubscriptionSuccess>(), // restored previous state
      ],
    );

    // ── Cancel state flow ───────────────────────────────────────────

    blocTest<SubscriptionCubit, SubscriptionState>(
      'cancelSubscription emits ActionSuccess and refreshes subscriptions',
      build: () {
        when(() => mockCancel(1, reason: 'Too expensive')).thenAnswer(
          (_) async => {'success': true, 'message': 'Subscription cancelled'},
        );
        when(() => mockGetSubs()).thenAnswer((_) async => [
              _makeSub(id: 1, status: 'CANCELLED'),
            ]);
        return buildCubit();
      },
      act: (cubit) =>
          cubit.cancelSubscription(1, reason: 'Too expensive'),
      expect: () => [
        isA<SubscriptionActionSuccess>()
            .having((s) => s.message, 'msg', 'Subscription cancelled'),
        isA<SubscriptionLoading>(),
        isA<SubscriptionSuccess>().having(
            (s) => s.userSubscriptions.first.status, 'status', 'CANCELLED'),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'cancelSubscription failure restores previous state',
      build: () {
        when(() => mockCancel(1, reason: any(named: 'reason')))
            .thenThrow(SubscriptionFailure.cancellationRejected(
                'Already cancelled'));
        return buildCubit();
      },
      act: (cubit) => cubit.cancelSubscription(1, reason: 'Reason'),
      expect: () => [
        isA<SubscriptionError>()
            .having((s) => s.message, 'msg', contains('Already cancelled')),
        isA<SubscriptionSuccess>(), // restored previous state
      ],
    );

    // ── Repayment state flow ────────────────────────────────────────

    blocTest<SubscriptionCubit, SubscriptionState>(
      'handleRepayment emits RepaymentInitiated when online payment link returned',
      build: () {
        when(() => mockRepayment(1)).thenAnswer((_) async =>
            RepaymentResponseEntity(
              success: true,
              paymentLinks: {'checkout_url': 'https://pay.example.com'},
              subscriptionId: 1,
              message: 'Payment session created',
              checkoutUrl: 'https://pay.example.com',
            ));
        return buildCubit();
      },
      act: (cubit) => cubit.handleRepayment(1),
      expect: () => [
        isA<SubscriptionLoading>(),
        isA<SubscriptionRepaymentInitiated>(),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'handleRepayment emits ActionSuccess when no payment link (instant success)',
      build: () {
        when(() => mockRepayment(1)).thenAnswer((_) async =>
            const RepaymentResponseEntity(
              success: true,
              message: 'Repayment processed successfully',
            ));
        when(() => mockGetSubs()).thenAnswer((_) async => [
              _makeSub(id: 1, paymentStatus: 'PAID_FULL'),
            ]);
        return buildCubit();
      },
      act: (cubit) => cubit.handleRepayment(1),
      expect: () => [
        isA<SubscriptionLoading>(),
        isA<SubscriptionActionSuccess>()
            .having((s) => s.message, 'msg', 'Repayment processed successfully'),
        isA<SubscriptionLoading>(),
        isA<SubscriptionSuccess>(),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'handleRepayment failure emits error',
      build: () {
        when(() => mockRepayment(1))
            .thenThrow(SubscriptionFailure.repaymentFailed('Insufficient balance'));
        return buildCubit();
      },
      act: (cubit) => cubit.handleRepayment(1),
      expect: () => [
        isA<SubscriptionLoading>(),
        isA<SubscriptionError>()
            .having((s) => s.message, 'msg', contains('Insufficient balance')),
      ],
    );

    // ── Create subscription ─────────────────────────────────────────

    blocTest<SubscriptionCubit, SubscriptionState>(
      'createSubscription emits SubscriptionCreated for online payment',
      build: () {
        when(() => mockCreate(any())).thenAnswer((_) async =>
            const SubscriptionCreateResponseEntity(
              paymentLinks: {'checkout_url': 'https://pay.example.com'},
              subscriptionId: 42,
              checkoutUrl: 'https://pay.example.com',
            ));
        when(() => mockGetSubs()).thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) => cubit.createSubscription({'plan': 1}),
      expect: () => [
        isA<SubscriptionLoading>(),
        isA<SubscriptionCreated>()
            .having((s) => s.subscriptionId, 'id', 42),
        // fetchUserSubscriptions refresh triggers Loading then Success
        isA<SubscriptionLoading>(),
        isA<SubscriptionSuccess>(),
      ],
    );
  });
}
