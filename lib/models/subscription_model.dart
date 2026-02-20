class Subscription {
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
  final InstallmentInfo? installmentInfo;
  final bool canPayNextInstallment;
  final List<SubscriptionItem> items;

  Subscription({
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
    required this.installmentInfo,
    required this.canPayNextInstallment,
    required this.items,
  });

  String get installmentPaymentStatus =>
      installmentInfo?.installmentPaymentStatus ?? "PAID";

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      plan: json['plan'] ?? 0,
      planName: json['plan_name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',

      deliveryCity: json['delivery_city'] ?? '',
      deliveryState: json['delivery_state'] ?? '',
      deliveryPincode: json['delivery_pincode'] ?? '',
      deliveryPhone: json['delivery_phone'] ?? '',
      recipientName: json['recipient_name'] ?? json['delivery_name'] ?? '',
      notes: json['notes'] ?? '',
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0.0') ?? 0.0,
      deliveryCharges:
          double.tryParse(json['delivery_charges']?.toString() ?? '0.0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0,
      amountPaid:
          double.tryParse(json['amount_paid']?.toString() ?? '0.0') ?? 0.0,
      remainingAmount:
          double.tryParse(json['remaining_amount']?.toString() ?? '0.0') ?? 0.0,
      nextDeliveryDate: json['next_delivery_date'] ?? '',
      lastPaymentDate: json['last_payment_date']?.toString(),
      nextPaymentDate: json['next_payment_date']?.toString(),
      totalDeliveries: json['total_deliveries'] ?? 0,
      completedDeliveries: json['completed_deliveries'] ?? 0,
      remainingPauseDays: json['remaining_pause_days'] ?? 0,
      remainingPauseTimes: json['remaining_pause_times'] ?? 0,
      createdAt: json['created_at'] ?? '',
      totalDeliveryCharges:
          double.tryParse(
            json['total_delivery_charges']?.toString() ?? '0.0',
          ) ??
          0.0,
      canPayNextInstallment: json['can_pay_next_installment'] ?? false,
      installmentInfo:
          json['installment_info'] != null
              ? InstallmentInfo.fromJson(json['installment_info'])
              : null,
      items:
          (json['items'] as List?)
              ?.map((item) => SubscriptionItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class InstallmentInfo {
  final int currentInstallment;
  final int totalInstallments;
  final int remainingInstallments;
  final String installmentAmount;
  final String nextInstallmentAmount;
  final int installmentFrequencyMonths;
  final String installmentPaymentStatus;

  InstallmentInfo({
    required this.currentInstallment,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.installmentAmount,
    required this.nextInstallmentAmount,
    required this.installmentFrequencyMonths,
    required this.installmentPaymentStatus,
  });

  factory InstallmentInfo.fromJson(Map<String, dynamic> json) {
    return InstallmentInfo(
      currentInstallment: json['current_installment'] ?? 0,
      totalInstallments: json['total_installments'] ?? 0,
      remainingInstallments: json['remaining_installments'] ?? 0,
      installmentAmount: json['installment_amount'] ?? '',
      nextInstallmentAmount: json['next_installment_amount'] ?? '',
      installmentFrequencyMonths: json['installment_frequency_months'] ?? 0,
      installmentPaymentStatus: json['installment_payment_status'] ?? '',
    );
  }
}

class SubscriptionItem {
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

  SubscriptionItem({
    required this.id,
    required this.imageUrl,
    required this.productVariant,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.discountedPrice,
    required this.unitWeight,
    required this.weightUnit,
    required this.totalWeight,
    required this.productCategory,
  });

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionItem(
      id: json['id'] ?? 0,
      productVariant: json['product_variant'] ?? 0,
      productName: json['product_name'] ?? '',
      productCategory: json['product_category'] ?? '',
      imageUrl: json["product_var_image"],

      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      discountedPrice:
          double.tryParse(json['discounted_price']?.toString() ?? '0.0') ?? 0.0,
      unitWeight:
          double.tryParse(json['unit_weight']?.toString() ?? '0.0') ?? 0.0,
      weightUnit: json['weight_unit'] ?? '',
      totalWeight:
          double.tryParse(json['total_weight']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}
