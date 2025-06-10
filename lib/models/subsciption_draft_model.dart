import 'package:grocery_app/models/product_model.dart';

class SubscriptionDraft {
  final int plan;
  final Product product;
  final int quantity;

  SubscriptionDraft({
    required this.plan,
    required this.product,
    required this.quantity,
  });
}
