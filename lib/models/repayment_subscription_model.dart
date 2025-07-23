class RepaymentSubscriptionResponse {
  final bool success;
  final PaymentLinks? paymentLinks;
  final int? subscriptionId;
  final String? merchantTransactionId;
  final int? installmentNumber;
  final String? installmentAmount;
  final String? nextPaymentDate;
  final String? message;

  RepaymentSubscriptionResponse({
    required this.success,
    this.paymentLinks,
    this.subscriptionId,
    this.merchantTransactionId,
    this.installmentNumber,
    this.installmentAmount,
    this.nextPaymentDate,
    this.message,
  });

  factory RepaymentSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return RepaymentSubscriptionResponse(
      success: json['success'] ?? false,
      paymentLinks: json['payment_links'] != null
          ? PaymentLinks.fromJson(json['payment_links'])
          : null,
      subscriptionId: json['subscription_id'],
      merchantTransactionId: json['merchant_transaction_id'],
      installmentNumber: json['installment_number'],
      installmentAmount: json['installment_amount'],
      nextPaymentDate: json['next_payment_date'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'payment_links': paymentLinks?.toJson(),
      'subscription_id': subscriptionId,
      'merchant_transaction_id': merchantTransactionId,
      'installment_number': installmentNumber,
      'installment_amount': installmentAmount,
      'next_payment_date': nextPaymentDate,
      'message': message,
    };
  }
}

class PaymentLinks {
  final String? web;
  final String? expiry;

  PaymentLinks({this.web, this.expiry});

  factory PaymentLinks.fromJson(Map<String, dynamic> json) {
    return PaymentLinks(
      web: json['web'],
      expiry: json['expiry'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'web': web,
      'expiry': expiry,
    };
  }
}
