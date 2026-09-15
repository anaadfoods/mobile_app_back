import 'package:grocery_app/models/cart_model.dart';

class CheckoutCalculator {
  /// Calculate delivery charge based on payment method
  static double deliveryCharge({
    required String paymentMethod,
    required double codCharge,
    required double prepaidCharge,
  }) {
    return paymentMethod == 'COD' ? codCharge : prepaidCharge;
  }

  /// Calculate base price for subscription orders
  static double subscriptionBasePrice(double? unitPrice, int? quantity) {
    return (unitPrice ?? 0.0) * (quantity ?? 1);
  }

  /// Calculate base price for cart orders
  static double cartBasePrice(CartModel? cart) {
    if (cart == null) return 0.0;
    final double parsedPrice = double.tryParse(cart.totalPrice) ?? 0.0;
    if (parsedPrice > 0.0) return parsedPrice;
    return cart.items.fold<double>(
      0.0,
      (sum, item) => sum + (item.productVariant.finalPrice * item.quantity),
    );
  }

  /// Calculate base price for single product (Buy Now)
  static double singleProductBasePrice(double? finalPrice, int? quantity) {
    return (finalPrice ?? 0.0) * (quantity ?? 1);
  }

  /// Calculate total price by combining base price and delivery charge
  static double total(double basePrice, double deliveryCharge) {
    return basePrice + deliveryCharge;
  }
}
