// TODO Implement this library.
class Subscription {
  final String id;
  final String planName;
  final int quantity;
  final DateTime nextDeliveryDate;
  final int deliveriesLeft;
  final String status;

  Subscription({
    required this.id,
    required this.planName,
    required this.quantity,
    required this.nextDeliveryDate,
    required this.deliveriesLeft, 
    required  this.status,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      planName: json['plan_name'],
      quantity: json['quantity'],
      nextDeliveryDate: DateTime.parse(json['next_delivery_date']),
      deliveriesLeft: json['deliveries_left'],
       status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'quantity': quantity,
      'next_delivery_date': nextDeliveryDate.toIso8601String(),
      'deliveries_left': deliveriesLeft,
       'status': status,
    };
  }
}