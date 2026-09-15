import '../entities/subscription_entity.dart';
import '../entities/subscription_plan_entity.dart';

/// Abstract repository interface for the Subscriptions feature.
/// Pure Dart — implementations live in data/.
abstract class SubscriptionsRepository {
  /// Fetch all subscriptions for the logged-in user.
  Future<List<SubscriptionEntity>> getUserSubscriptions();

  /// Fetch details for a specific subscription by ID.
  Future<SubscriptionEntity> getSubscriptionDetails(int subscriptionId);

  /// Fetch all available subscription plans.
  Future<List<SubscriptionPlanEntity>> getSubscriptionPlans();

  /// Create a new subscription. Returns a response which may contain
  /// payment links for online payment or the subscription directly for COD.
  Future<SubscriptionCreateResponseEntity> createSubscription(
    Map<String, dynamic> requestData,
  );

  /// Cancel a subscription, optionally with a reason.
  Future<Map<String, dynamic>> cancelSubscription(
    int subscriptionId, {
    String? reason,
  });

  /// Toggle pause/resume on a subscription.
  Future<PauseResponseEntity> togglePauseSubscription(
    int subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
  );

  /// Initiate repayment for an unpaid subscription.
  Future<RepaymentResponseEntity> repaymentSubscription(int subscriptionId);

  /// Fetch invoices for a subscription.
  Future<SubscriptionInvoiceResponse> getSubscriptionInvoices(
    int subscriptionId,
  );

  /// Fetch products available for a specific plan.
  Future<List<SubscriptionPlanProductEntity>> getSubscriptionPlanProducts(
    int planId,
  );

  /// Search for plans that contain a specific product variant.
  Future<List<PlanSearchResultEntity>> searchPlansForVariant(int variantId);
}

/// Domain entity for subscription invoice response.
class SubscriptionInvoiceResponse {
  final bool success;
  final int subscriptionId;
  final List<InvoiceEntity> invoices;
  final int totalInvoices;

  const SubscriptionInvoiceResponse({
    required this.success,
    required this.subscriptionId,
    required this.invoices,
    required this.totalInvoices,
  });
}

/// Domain entity for a single invoice.
class InvoiceEntity {
  final int id;
  final String invoiceNumber;
  final String s3Url;
  final String displayName;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.s3Url,
    required this.displayName,
  });
}

/// Domain entity for a subscription plan product.
class SubscriptionPlanProductEntity {
  final int id;
  final String name;
  final String category;
  final double price;
  final double discountedPrice;
  final double unitWeight;
  final String weightUnit;
  final String? imageUrl;
  final int variantId;

  const SubscriptionPlanProductEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.discountedPrice,
    required this.unitWeight,
    required this.weightUnit,
    this.imageUrl,
    required this.variantId,
  });
}

/// Domain entity for plan search results.
class PlanSearchResultEntity {
  final int planId;
  final String planName;
  final int durationMonths;
  final String discountPercentage;

  const PlanSearchResultEntity({
    required this.planId,
    required this.planName,
    required this.durationMonths,
    required this.discountPercentage,
  });
}
