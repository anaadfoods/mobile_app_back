import 'package:grocery_app/services/api_exception.dart';
import 'package:grocery_app/models/subscription_model.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/subscription_plan_entity.dart';
import '../../domain/failures/subscription_failure.dart';
import '../../domain/repositories/subscriptions_repository.dart';
import '../datasources/subscriptions_remote_data_source.dart';

class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  final SubscriptionsRemoteDataSource _dataSource;

  SubscriptionsRepositoryImpl(this._dataSource);

  // ─── Mapping helpers ──────────────────────────────────────────────

  static SubscriptionEntity _mapSubscription(Subscription s) {
    return SubscriptionEntity(
      id: s.id,
      plan: s.plan,
      planName: s.planName,
      startDate: s.startDate,
      endDate: s.endDate,
      status: s.status,
      paymentStatus: s.paymentStatus,
      paymentMethod: s.paymentMethod,
      deliveryAddress: s.deliveryAddress,
      deliveryCity: s.deliveryCity,
      deliveryState: s.deliveryState,
      deliveryPincode: s.deliveryPincode,
      deliveryPhone: s.deliveryPhone,
      recipientName: s.recipientName,
      notes: s.notes,
      subtotal: s.subtotal,
      deliveryCharges: s.deliveryCharges,
      total: s.total,
      amountPaid: s.amountPaid,
      remainingAmount: s.remainingAmount,
      nextDeliveryDate: s.nextDeliveryDate,
      lastPaymentDate: s.lastPaymentDate,
      nextPaymentDate: s.nextPaymentDate,
      totalDeliveries: s.totalDeliveries,
      completedDeliveries: s.completedDeliveries,
      remainingPauseDays: s.remainingPauseDays,
      remainingPauseTimes: s.remainingPauseTimes,
      createdAt: s.createdAt,
      totalDeliveryCharges: s.totalDeliveryCharges,
      canPayNextInstallment: s.canPayNextInstallment,
      installmentInfo: s.installmentInfo != null
          ? InstallmentInfoEntity(
              currentInstallment: s.installmentInfo!.currentInstallment,
              totalInstallments: s.installmentInfo!.totalInstallments,
              remainingInstallments: s.installmentInfo!.remainingInstallments,
              installmentAmount: s.installmentInfo!.installmentAmount,
              nextInstallmentAmount: s.installmentInfo!.nextInstallmentAmount,
              installmentFrequencyMonths:
                  s.installmentInfo!.installmentFrequencyMonths,
              installmentPaymentStatus:
                  s.installmentInfo!.installmentPaymentStatus,
            )
          : null,
      items: s.items
          .map((i) => SubscriptionItemEntity(
                id: i.id,
                productVariant: i.productVariant,
                productName: i.productName,
                productCategory: i.productCategory,
                quantity: i.quantity,
                price: i.price,
                discountedPrice: i.discountedPrice,
                unitWeight: i.unitWeight,
                weightUnit: i.weightUnit,
                totalWeight: i.totalWeight,
                imageUrl: i.imageUrl,
              ))
          .toList(),
      pauseStartDate: s.pauseStartDate,
      pauseEndDate: s.pauseEndDate,
      subscriptionNumber: s.subscriptionNumber,
    );
  }

  // ─── Repository methods ───────────────────────────────────────────

  @override
  Future<List<SubscriptionEntity>> getUserSubscriptions() async {
    try {
      final subs = await _dataSource.getSubscriptions();
      return subs.map(_mapSubscription).toList();
    } on ApiException catch (e) {
      throw SubscriptionFailure.server(e.message);
    } catch (e) {
      throw SubscriptionFailure(
        'Sorry, we are not available right now. Please try again later.',
      );
    }
  }

  @override
  Future<SubscriptionEntity> getSubscriptionDetails(int subscriptionId) async {
    try {
      final sub = await _dataSource.getSubscriptionDetails(subscriptionId);
      return _mapSubscription(sub);
    } on ApiException catch (e) {
      if (e.statusCode == 404) throw SubscriptionFailure.notFound();
      throw SubscriptionFailure.server(e.message);
    } catch (e) {
      throw SubscriptionFailure('Failed to load subscription details.');
    }
  }

  @override
  Future<List<SubscriptionPlanEntity>> getSubscriptionPlans() async {
    try {
      final plans = await _dataSource.getSubscriptionPlans();
      return plans
          .map((p) => SubscriptionPlanEntity(
                id: p.id,
                name: p.name,
                durationMonths: p.durationMonths,
                discountPercentage: p.discountPercentage,
                totalDiscountPercentage: p.totalDiscountPercentage,
                tagline: p.tagline,
                description: p.description,
                isActive: p.isActive,
                activationDate: p.activationDate,
                isOneTimeOnly: p.isOneTimeOnly,
                allowsInstallments: p.allowsInstallments,
                installmentFrequencyMonths: p.installmentFrequencyMonths,
                isAvailable: p.isAvailable,
              ))
          .toList();
    } on ApiException catch (e) {
      throw SubscriptionFailure.server(e.message);
    } catch (e) {
      throw SubscriptionFailure('Failed to fetch subscription plans.');
    }
  }

  @override
  Future<SubscriptionCreateResponseEntity> createSubscription(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final result = await _dataSource.createSubscription(requestData);
      if (result['type'] == 'online_payment') {
        return SubscriptionCreateResponseEntity(
          paymentLinks: result,
          subscriptionId: result['subscription_id'] as int?,
          merchantTransactionId:
              result['merchant_transaction_id']?.toString(),
          checkoutUrl: result['checkout_url']?.toString(),
          subscriptionNumber: result['subscription_number']?.toString(),
        );
      } else {
        final sub = result['data'] as Subscription?;
        return SubscriptionCreateResponseEntity(
          subscription: sub != null ? _mapSubscription(sub) : null,
          subscriptionId: result['subscription_id'] as int? ?? sub?.id,
          subscriptionNumber: result['subscription_number']?.toString() ??
              sub?.subscriptionNumber,
        );
      }
    } on ApiException catch (e) {
      throw SubscriptionFailure.server(e.message);
    } catch (e) {
      throw SubscriptionFailure('Failed to create subscription.');
    }
  }

  @override
  Future<Map<String, dynamic>> cancelSubscription(
    int subscriptionId, {
    String? reason,
  }) async {
    try {
      return await _dataSource.cancelSubscription(
        subscriptionId,
        reason: reason,
      );
    } on ApiException catch (e) {
      throw SubscriptionFailure.cancellationRejected(e.message);
    } catch (e) {
      throw SubscriptionFailure('Failed to cancel subscription.');
    }
  }

  @override
  Future<PauseResponseEntity> togglePauseSubscription(
    int subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final result = await _dataSource.togglePauseSubscription(
        subscriptionId,
        startDate,
        endDate,
      );
      return PauseResponseEntity(
        message: result['message'] ?? 'Status updated successfully.',
      );
    } on ApiException catch (e) {
      throw SubscriptionFailure.pauseRejected(e.message);
    } catch (e) {
      throw SubscriptionFailure('Failed to update subscription status.');
    }
  }

  @override
  Future<RepaymentResponseEntity> repaymentSubscription(
    int subscriptionId,
  ) async {
    try {
      final result = await _dataSource.repaymentSubscription(subscriptionId);
      if (result['type'] == 'online_payment') {
        return RepaymentResponseEntity(
          success: true,
          paymentLinks: result,
          subscriptionId: result['subscription_id'] as int?,
          message: result['message'] ?? 'Payment session created',
          checkoutUrl: result['checkout_url']?.toString(),
        );
      }
      return RepaymentResponseEntity(
        success: true,
        message: result['message'] ?? 'Repayment processed successfully',
      );
    } on ApiException catch (e) {
      throw SubscriptionFailure.repaymentFailed(e.message);
    } catch (e) {
      throw SubscriptionFailure('Failed to process repayment.');
    }
  }

  @override
  Future<SubscriptionInvoiceResponse> getSubscriptionInvoices(
    int subscriptionId,
  ) async {
    try {
      final response =
          await _dataSource.getSubscriptionInvoices(subscriptionId);
      return SubscriptionInvoiceResponse(
        success: response.success,
        subscriptionId: response.subscriptionId,
        invoices: response.invoices
            .map((i) => InvoiceEntity(
                  id: i.id,
                  invoiceNumber: i.odooInvoiceNumber,
                  s3Url: i.s3Url,
                  displayName: i.displayName,
                ))
            .toList(),
        totalInvoices: response.totalInvoices,
      );
    } on ApiException catch (e) {
      throw SubscriptionFailure.server(e.message);
    } catch (e) {
      throw SubscriptionFailure('Failed to fetch invoices.');
    }
  }

  @override
  Future<List<SubscriptionPlanProductEntity>> getSubscriptionPlanProducts(
    int planId,
  ) async {
    try {
      final response = await _dataSource.getSubscriptionPlanProducts(planId);
      return response.products
          .map((p) => SubscriptionPlanProductEntity(
                id: p.productId,
                name: p.productName,
                category: '',
                price: 0,
                discountedPrice: 0,
                unitWeight: p.maxWeightLimit,
                weightUnit: 'kg',
                variantId: p.productId,
              ))
          .toList();
    } on ApiException catch (e) {
      throw SubscriptionFailure.server(e.message);
    } catch (e) {
      throw SubscriptionFailure('Failed to fetch plan products.');
    }
  }

  @override
  Future<List<PlanSearchResultEntity>> searchPlansForVariant(
    int variantId,
  ) async {
    try {
      final results = await _dataSource.searchPlansForVariant(variantId);
      return results
          .map((r) => PlanSearchResultEntity(
                planId: r.planId,
                planName: r.planName,
                durationMonths: 1,
                discountPercentage: r.discountPercentage.toString(),
              ))
          .toList();
    } catch (e) {
      throw SubscriptionFailure(
        'Failed to find plans for the selected product.',
      );
    }
  }
}
