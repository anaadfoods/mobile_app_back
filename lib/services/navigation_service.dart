import 'package:grocery_app/common_widgets/global_import.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static var globalNavigatorKey;

  /// Navigate to notifications screen
  static Future<void> navigateToNotifications() async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NotificationsScreen()),
      );
    }
  }

  /// Navigate to order details
  static Future<void> navigateToOrderDetails(String? orderId) async {
    final context = _instance.navigatorKey.currentState?.context;
    if (context == null) {
      debugPrint('Navigation context is null for order details');
      return;
    }
    if (orderId == null || orderId.isEmpty) {
      debugPrint('orderId is null or empty, falling back to notifications');
      await navigateToNotifications();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: orderId),
      ),
    );
  }

  /// Navigate to subscription details
  static Future<void> navigateToSubscriptionDetails(
    String? subscriptionId,
  ) async {
    final context = _instance.navigatorKey.currentState?.context;
    if (context == null) {
      debugPrint('Navigation context is null for subscription details');
      return;
    }
    if (subscriptionId == null || subscriptionId.isEmpty) {
      debugPrint('subscriptionId is null or empty, falling back to notifications');
      await navigateToNotifications();
      return;
    }

    debugPrint('Navigating to subscription details for id: $subscriptionId');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                SubscriptionPlanDetailScreen(subscriptionId: subscriptionId),
      ),
    );
  }

  /// Navigate to cart
  static Future<void> navigateToCart() async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartScreen()),
      );
    }
  }

  /// Navigate to account/profile
  static Future<void> navigateToAccount() async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountScreenFinal()),
      );
    }
  }

  /// Navigate to promo/offer details (placeholder)
  static Future<void> navigateToPromoDetails(String? promoId) async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null && promoId != null) {
      // For now, navigate to notifications screen as a fallback
      await navigateToNotifications();
    }
  }

  static Future<void> navigateToProductDetails(String? productId) async {
    final context = _instance.navigatorKey.currentState?.context;
    if (context == null) {
      debugPrint('Navigation context is null for product details');
      return;
    }
    if (productId == null || productId.isEmpty) {
      debugPrint('productId is null or empty, falling back to notifications');
      await navigateToNotifications();
      return;
    }

    debugPrint('Navigating to product details for: $productId');

    try {
      // Parse productId from String to int
      final int parsedProductId = int.parse(productId);
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final product = await CategoryService.fetchProductById(parsedProductId);

      // Hide loading
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to product: $e');
      if (context.mounted) {
        Navigator.pop(context); // Hide loading dialog
        await navigateToNotifications(); // Fallback to notifications
      }
    }
  }

  /// Navigate to home screen
  static Future<void> navigateToHome() async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null) {
      // Navigate to home screen (dashboard)
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }

  /// Navigate to notifications screen
  // static Future<void> navigateToNotifications() async {
  //   final context = _instance.navigatorKey.currentContext;
  //   if (context != null) {
  //     await Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => NotificationsScreen()),
  //     );
  //   }
  // }
}

  /// Get the navigator key for use in MaterialApp
  // GlobalKey<NavigatorState> get globalNavigatorKey => navigatorKey;
