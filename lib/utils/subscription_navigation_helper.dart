import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/products/presentation/screens/product_details_screen.dart';
import 'package:grocery_app/features/products/data/repositories/products_repository_impl.dart';

class SubscriptionNavigationHelper {
  static Future<void> navigateToProductDetails(
    BuildContext context,
    Product product,
  ) async {
    // Navigate to ProductDetailsScreen with autoOpenSubscription set to true.
    // The screen itself handles loading plans and selecting the first available plan by default
    // if no initialPlanId is provided.
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(
        ProductDetailsScreen(product: product, autoOpenSubscription: true),
      ),
    );
  }
}
