import 'package:grocery_app/common_widgets/global_import.dart';

/// Centralized navigation service using a global navigatorKey.
///
/// CRITICAL: All notification-based navigation MUST go through this service
/// to ensure reliable navigation across all app states (foreground, background, terminated).
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Global navigator key - MUST be wired to MaterialApp
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the navigator state safely
  NavigatorState? get _navigator => navigatorKey.currentState;

  /// Check if navigator is ready for navigation
  bool get isReady => _navigator != null;

  // ============================================================================
  // LIFECYCLE-SAFE NAVIGATION WRAPPER
  // ============================================================================

  /// Ensures navigation happens after the UI is ready.
  /// CRITICAL: Use this for all notification-triggered navigation.
  static void safeNavigate(VoidCallback navigationAction) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationAction();
    });
  }

  // ============================================================================
  // NAVIGATION METHODS - Use navigatorKey.currentState directly
  // ============================================================================

  /// Navigate to notifications screen
  static Future<void> navigateToNotifications() async {
    final navigator = _instance._navigator;
    if (navigator == null) {
      debugPrint(
        'NavigationService: Navigator not ready for navigateToNotifications',
      );
      return;
    }

    await navigator.push(
      MaterialPageRoute(builder: (context) => NotificationsScreen()),
    );
  }

  /// Navigate to order details
  static Future<void> navigateToOrderDetails(String? orderId) async {
    final navigator = _instance._navigator;
    if (navigator == null) {
      debugPrint(
        'NavigationService: Navigator not ready for navigateToOrderDetails',
      );
      return;
    }

    if (orderId == null || orderId.isEmpty) {
      debugPrint(
        'NavigationService: orderId is null or empty, falling back to notifications',
      );
      await navigateToNotifications();
      return;
    }

    debugPrint(
      'NavigationService: Navigating to order details for id: $orderId',
    );
    navigator.push(
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: orderId),
      ),
    );
  }

  /// Navigate to subscription details
  static Future<void> navigateToSubscriptionDetails(
    String? subscriptionId,
  ) async {
    final navigator = _instance._navigator;
    if (navigator == null) {
      debugPrint(
        'NavigationService: Navigator not ready for navigateToSubscriptionDetails',
      );
      return;
    }

    if (subscriptionId == null || subscriptionId.isEmpty) {
      debugPrint(
        'NavigationService: subscriptionId is null or empty, falling back to notifications',
      );
      await navigateToNotifications();
      return;
    }

    debugPrint(
      'NavigationService: Navigating to subscription details for id: $subscriptionId',
    );
    navigator.push(
      MaterialPageRoute(
        builder:
            (context) =>
                SubscriptionPlanDetailScreen(subscriptionId: subscriptionId),
      ),
    );
  }

  /// Navigate to cart
  static Future<void> navigateToCart() async {
    final navigator = _instance._navigator;
    if (navigator == null) {
      debugPrint('NavigationService: Navigator not ready for navigateToCart');
      return;
    }

    await navigator.push(MaterialPageRoute(builder: (context) => CartScreen()));
  }

  /// Navigate to account/profile
  static Future<void> navigateToAccount() async {
    final navigator = _instance._navigator;
    if (navigator == null) {
      debugPrint(
        'NavigationService: Navigator not ready for navigateToAccount',
      );
      return;
    }

    await navigator.push(
      MaterialPageRoute(builder: (context) => AccountScreenFinal()),
    );
  }

  /// Navigate to promo/offer details (placeholder)
  static Future<void> navigateToPromoDetails(String? promoId) async {
    if (promoId != null) {
      // For now, navigate to notifications screen as a fallback
      await navigateToNotifications();
    }
  }

  /// Navigate to product details
  static Future<void> navigateToProductDetails(String? productId) async {
    final navigator = _instance._navigator;
    if (navigator == null) {
      debugPrint(
        'NavigationService: Navigator not ready for navigateToProductDetails',
      );
      return;
    }

    if (productId == null || productId.isEmpty) {
      debugPrint(
        'NavigationService: productId is null or empty, falling back to notifications',
      );
      await navigateToNotifications();
      return;
    }

    debugPrint(
      'NavigationService: Navigating to product details for: $productId',
    );

    try {
      // Parse productId from String to int
      final int parsedProductId = int.parse(productId);

      // Get context from navigator for dialogs
      final context = navigator.context;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final product = await CategoryService.fetchProductById(parsedProductId);

      // Hide loading
      navigator.pop();

      navigator.push(
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(product: product),
        ),
      );
    } catch (e) {
      debugPrint('NavigationService: Error navigating to product: $e');
      // Try to pop loading dialog if it's still showing
      try {
        navigator.pop();
      } catch (_) {}
      await navigateToNotifications(); // Fallback to notifications
    }
  }

  /// Navigate to home screen
  static Future<void> navigateToHome() async {
    final navigator = _instance._navigator;
    if (navigator == null) {
      debugPrint('NavigationService: Navigator not ready for navigateToHome');
      return;
    }

    // Navigate to home screen (dashboard) and clear stack
    await navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => DashboardScreen()),
      (route) => false, // Remove all previous routes
    );
  }
}
