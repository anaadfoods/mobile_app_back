import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/utils/checkout_calculator.dart';

void main() {
  group('CheckoutCalculator', () {
    test('deliveryCharge returns codCharge for COD and prepaidCharge for others', () {
      expect(
        CheckoutCalculator.deliveryCharge(
          paymentMethod: 'COD',
          codCharge: 50.0,
          prepaidCharge: 20.0,
        ),
        50.0,
      );

      expect(
        CheckoutCalculator.deliveryCharge(
          paymentMethod: 'UPI',
          codCharge: 50.0,
          prepaidCharge: 20.0,
        ),
        20.0,
      );
    });

    test('subscriptionBasePrice multiplies unitPrice by quantity', () {
      expect(CheckoutCalculator.subscriptionBasePrice(10.0, 3), 30.0);
      expect(CheckoutCalculator.subscriptionBasePrice(null, 3), 0.0);
      expect(CheckoutCalculator.subscriptionBasePrice(10.0, null), 10.0);
    });

    test('singleProductBasePrice multiplies finalPrice by quantity', () {
      expect(CheckoutCalculator.singleProductBasePrice(15.5, 2), 31.0);
      expect(CheckoutCalculator.singleProductBasePrice(null, 2), 0.0);
      expect(CheckoutCalculator.singleProductBasePrice(15.5, null), 15.5);
    });

    test('total sums basePrice and deliveryCharge', () {
      expect(CheckoutCalculator.total(100.0, 15.0), 115.0);
    });
  });
}
