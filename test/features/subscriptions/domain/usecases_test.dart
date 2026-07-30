import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:grocery_app/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:grocery_app/features/subscriptions/domain/entities/subscription_plan_entity.dart';
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

class MockSubscriptionsRepository extends Mock
    implements SubscriptionsRepository {}

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
  late MockSubscriptionsRepository mockRepo;

  setUp(() {
    mockRepo = MockSubscriptionsRepository();
  });

  group('Subscriptions Feature Use Cases', () {
    test('GetUserSubscriptionsUseCase filters out unpaid UPI subscriptions',
        () async {
      when(() => mockRepo.getUserSubscriptions()).thenAnswer((_) async => [
            _makeSub(id: 1, paymentMethod: 'COD', paymentStatus: 'PAID_FULL'),
            _makeSub(
                id: 2, paymentMethod: 'UPI', paymentStatus: 'PAYMENT_PENDING'),
            _makeSub(id: 3, paymentMethod: 'UPI', paymentStatus: 'PAID_FULL'),
            _makeSub(id: 4, paymentMethod: 'UPI', paymentStatus: 'FAILED'),
            _makeSub(id: 5, paymentMethod: 'UPI', paymentStatus: 'PENDING'),
          ]);

      final useCase = GetUserSubscriptionsUseCase(mockRepo);
      final result = await useCase();

      expect(result.length, 2);
      expect(result.map((e) => e.id).toList(), [1, 3]);
    });

    test('GetSubscriptionDetailsUseCase calls repository', () async {
      when(() => mockRepo.getSubscriptionDetails(1))
          .thenAnswer((_) async => _makeSub(id: 1));

      final useCase = GetSubscriptionDetailsUseCase(mockRepo);
      final result = await useCase(1);
      expect(result.id, 1);
      verify(() => mockRepo.getSubscriptionDetails(1)).called(1);
    });

    test('GetSubscriptionPlansUseCase calls repository', () async {
      when(() => mockRepo.getSubscriptionPlans()).thenAnswer((_) async => [
            const SubscriptionPlanEntity(
              id: 1, name: 'SIDDH', durationMonths: 12,
              discountPercentage: '10', totalDiscountPercentage: 10.0,
              tagline: 'Test', description: 'Plan', isActive: true,
              activationDate: '2026-01-01', isOneTimeOnly: false,
              allowsInstallments: true, installmentFrequencyMonths: 3,
              isAvailable: true,
            ),
          ]);

      final useCase = GetSubscriptionPlansUseCase(mockRepo);
      final result = await useCase();
      expect(result.length, 1);
      expect(result.first.name, 'SIDDH');
    });

    test('CreateSubscriptionUseCase calls repository with params', () async {
      when(() => mockRepo.createSubscription(any())).thenAnswer(
        (_) async => const SubscriptionCreateResponseEntity(
          subscriptionId: 42,
          checkoutUrl: 'https://pay.example.com',
        ),
      );

      final useCase = CreateSubscriptionUseCase(mockRepo);
      final result = await useCase({'plan': 1});
      expect(result.subscriptionId, 42);
      expect(result.requiresOnlinePayment, true);
    });

    test('CancelSubscriptionUseCase calls repository', () async {
      when(() => mockRepo.cancelSubscription(1, reason: 'Too expensive'))
          .thenAnswer((_) async => {
                'success': true,
                'message': 'Cancelled',
              });

      final useCase = CancelSubscriptionUseCase(mockRepo);
      final result = await useCase(1, reason: 'Too expensive');
      expect(result['success'], true);
    });

    test('TogglePauseSubscriptionUseCase calls repository', () async {
      when(() => mockRepo.togglePauseSubscription(1, any(), any()))
          .thenAnswer(
        (_) async => const PauseResponseEntity(message: 'Paused'),
      );

      final useCase = TogglePauseSubscriptionUseCase(mockRepo);
      final result = await useCase(1, DateTime(2026), DateTime(2026, 2));
      expect(result.message, 'Paused');
    });

    test('RepaymentSubscriptionUseCase calls repository', () async {
      when(() => mockRepo.repaymentSubscription(1)).thenAnswer(
        (_) async => const RepaymentResponseEntity(
          success: true,
          message: 'Payment session created',
          checkoutUrl: 'https://pay.example.com',
        ),
      );

      final useCase = RepaymentSubscriptionUseCase(mockRepo);
      final result = await useCase(1);
      expect(result.success, true);
      expect(result.requiresOnlinePayment, true);
    });

    test('GetSubscriptionInvoicesUseCase calls repository', () async {
      when(() => mockRepo.getSubscriptionInvoices(1)).thenAnswer(
        (_) async => const SubscriptionInvoiceResponse(
          success: true,
          subscriptionId: 1,
          invoices: [],
          totalInvoices: 0,
        ),
      );

      final useCase = GetSubscriptionInvoicesUseCase(mockRepo);
      final result = await useCase(1);
      expect(result.success, true);
    });

    test('GetSubscriptionPlanProductsUseCase calls repository', () async {
      when(() => mockRepo.getSubscriptionPlanProducts(1))
          .thenAnswer((_) async => []);

      final useCase = GetSubscriptionPlanProductsUseCase(mockRepo);
      final result = await useCase(1);
      expect(result, isEmpty);
    });

    test('SearchPlansForVariantUseCase calls repository', () async {
      when(() => mockRepo.searchPlansForVariant(42))
          .thenAnswer((_) async => []);

      final useCase = SearchPlansForVariantUseCase(mockRepo);
      final result = await useCase(42);
      expect(result, isEmpty);
    });
  });
}
