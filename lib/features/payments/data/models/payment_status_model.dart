import '../../domain/entities/payment_status.dart';

class PaymentStatusModel extends PaymentStatus {
  const PaymentStatusModel({
    required super.status,
    required super.respMessage,
  });

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) {
    final statusVal =
        json['transaction_status']?.toString() ??
        json['status']?.toString() ??
        '';
    final messageVal =
        json['resp_message']?.toString() ??
        json['message']?.toString() ??
        '';
    return PaymentStatusModel(
      status: statusVal,
      respMessage: messageVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_status': status,
      'resp_message': respMessage,
    };
  }
}
