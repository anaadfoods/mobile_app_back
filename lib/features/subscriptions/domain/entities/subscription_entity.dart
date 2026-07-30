/// Domain entity for a subscription.
/// Pure Dart — no Flutter or third-party imports.
class SubscriptionEntity {
  final int id;
  final int plan;
  final String planName;
  final String startDate;
  final String endDate;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryState;
  final String deliveryPincode;
  final String deliveryPhone;
  final String recipientName;
  final String notes;
  final double subtotal;
  final double deliveryCharges;
  final double total;
  final double amountPaid;
  final double remainingAmount;
  final String nextDeliveryDate;
  final String? lastPaymentDate;
  final String? nextPaymentDate;
  final int totalDeliveries;
  final int completedDeliveries;
  final int remainingPauseDays;
  final int remainingPauseTimes;
  final String createdAt;
  final double totalDeliveryCharges;
  final bool canPayNextInstallment;
  final InstallmentInfoEntity? installmentInfo;
  final List<SubscriptionItemEntity> items;
  final String? pauseStartDate;
  final String? pauseEndDate;
  final String? subscriptionNumber;

  const SubscriptionEntity({
    required this.id,
    required this.plan,
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryState,
    required this.deliveryPincode,
    required this.deliveryPhone,
    required this.recipientName,
    required this.notes,
    required this.subtotal,
    required this.deliveryCharges,
    required this.total,
    required this.amountPaid,
    required this.remainingAmount,
    required this.nextDeliveryDate,
    this.lastPaymentDate,
    this.nextPaymentDate,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.remainingPauseDays,
    required this.remainingPauseTimes,
    required this.createdAt,
    required this.totalDeliveryCharges,
    required this.canPayNextInstallment,
    this.installmentInfo,
    required this.items,
    this.pauseStartDate,
    this.pauseEndDate,
    this.subscriptionNumber,
  });

  String get installmentPaymentStatus =>
      installmentInfo?.installmentPaymentStatus ?? 'PAID';

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isPaused => status.toUpperCase() == 'PAUSED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
}

class InstallmentInfoEntity {
  final int currentInstallment;
  final int totalInstallments;
  final int remainingInstallments;
  final String installmentAmount;
  final String nextInstallmentAmount;
  final int installmentFrequencyMonths;
  final String installmentPaymentStatus;

  const InstallmentInfoEntity({
    required this.currentInstallment,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.installmentAmount,
    required this.nextInstallmentAmount,
    required this.installmentFrequencyMonths,
    required this.installmentPaymentStatus,
  });
}

class SubscriptionItemEntity {
  final int id;
  final int productVariant;
  final String productName;
  final String productCategory;
  final int quantity;
  final double price;
  final double discountedPrice;
  final double unitWeight;
  final String weightUnit;
  final double totalWeight;
  final String? imageUrl;

  const SubscriptionItemEntity({
    required this.id,
    required this.productVariant,
    required this.productName,
    required this.productCategory,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
    required this.unitWeight,
    required this.weightUnit,
    required this.totalWeight,
    this.imageUrl,
  });
}

/// Result of creating a subscription.
class SubscriptionCreateResponseEntity {
  final SubscriptionEntity? subscription;
  final Map<String, dynamic>? paymentLinks;
  final int? subscriptionId;
  final String? merchantTransactionId;
  final String? checkoutUrl;
  final String? subscriptionNumber;

  const SubscriptionCreateResponseEntity({
    this.subscription,
    this.paymentLinks,
    this.subscriptionId,
    this.merchantTransactionId,
    this.checkoutUrl,
    this.subscriptionNumber,
  });

  bool get requiresOnlinePayment => checkoutUrl != null || paymentLinks != null;
}

/// Result of toggling pause on a subscription.
class PauseResponseEntity {
  final String message;
  const PauseResponseEntity({required this.message});
}

/// Result of a repayment attempt.
class RepaymentResponseEntity {
  final bool success;
  final Map<String, dynamic>? paymentLinks;
  final int? subscriptionId;
  final String message;
  final String? checkoutUrl;

  const RepaymentResponseEntity({
    required this.success,
    this.paymentLinks,
    this.subscriptionId,
    required this.message,
    this.checkoutUrl,
  });

  bool get requiresOnlinePayment => checkoutUrl != null || paymentLinks != null;
}
