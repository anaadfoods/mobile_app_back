class PaymentStatus {
  final int orderId;
  final String orderNumber;
  final String paymentStatus;
  final String transactionStatus;
  final String transactionId;
  final String merchantTransactionId;
  final String amount;
  final String createdAt;
  final String? completedAt;
  final String respMessage;
  final String? errorCode;

  PaymentStatus({
    required this.orderId,
    required this.orderNumber,
    required this.paymentStatus,
    required this.transactionStatus,
    required this.transactionId,
    required this.merchantTransactionId,
    required this.amount,
    required this.createdAt,
    this.completedAt,
    required this.respMessage,
    this.errorCode,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      orderId:
          json['order_id'] is int
              ? json['order_id']
              : int.parse(json['order_id'].toString()),
      orderNumber: json['order_number'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      transactionStatus: json['transaction_status'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      merchantTransactionId: json['merchant_transaction_id'] ?? '',
      amount: json['amount'] ?? '',
      createdAt: json['created_at'] ?? '',
      completedAt: json['completed_at'],
      respMessage: json['resp_message'] ?? '',
      errorCode: json['error_code'],
    );
  }
}

class SubscriptionPaymentStatus {
  final int subscriptionId;
  final String paymentStatus;
  final String transactionStatus;
  final String? transactionId;
  final String merchantTransactionId;
  final String amount;
  final String createdAt;
  final String? completedAt;
  final String? respMessage;
  final String? errorCode;

  SubscriptionPaymentStatus({
    required this.subscriptionId,
    required this.paymentStatus,
    required this.transactionStatus,
    this.transactionId,
    required this.merchantTransactionId,
    required this.amount,
    required this.createdAt,
    this.completedAt,
    this.respMessage,
    this.errorCode,
  });

  factory SubscriptionPaymentStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentStatus(
      subscriptionId: json['subscription_id'] ?? 0,
      paymentStatus: json['payment_status'] ?? '',
      transactionStatus: json['transaction_status'] ?? '',
      transactionId: json['transaction_id'],
      merchantTransactionId: json['merchant_transaction_id'] ?? '',
      amount: json['amount']?.toString() ?? '',
      createdAt: json['created_at'] ?? '',
      completedAt: json['completed_at'],
      respMessage: json['resp_message'],
      errorCode: json['error_code'],
    );
  }
}
