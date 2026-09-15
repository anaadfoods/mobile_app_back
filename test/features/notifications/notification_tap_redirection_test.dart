import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_app/services/navigation_service.dart';
import 'package:grocery_app/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NavigationService Declarative Routing Tests', () {
    test('NavigationService methods are callable and route names match enum', () {
      expect(NavigationService.create(), isNotNull);
      expect(AppRoute.notifications.name, 'notifications');
      expect(AppRoute.productDetails.name, 'product_details');
      expect(AppRoute.orderDetails.name, 'order_details');
      expect(AppRoute.subscriptionDetails.name, 'subscription_details');
      expect(AppRoute.allProducts.name, 'products');
      expect(AppRoute.orderList.name, 'order_list');
      expect(AppRoute.subscriptionList.name, 'subscription_list');
      expect(AppRoute.panchang.name, 'panchang');
      expect(AppRoute.checkout.name, 'checkout');
    });
  });
}
