import 'package:flutter/material.dart';
import 'package:grocery_app/routes/app_router.dart';
import 'package:grocery_app/routes/app_routes.dart';

/// Centralized navigation service using AppRouter.
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Global navigator key - Wired to AppRouter
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the navigator state safely
  NavigatorState? get _navigator => navigatorKey.currentState;

  /// Check if navigator is ready for navigation
  bool get isReady => _navigator != null;

  // ============================================================================
  // LIFECYCLE-SAFE NAVIGATION WRAPPER
  // ============================================================================

  /// Ensures navigation happens after the office is ready.
  static void safeNavigate(VoidCallback navigationAction) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationAction();
    });
  }

  // ============================================================================
  // NAVIGATION METHODS - Delegating to AppRouter (GoRouter)
  // ============================================================================

  static Future<void> navigateToNotifications() async {
    AppRouter().router.pushNamed(AppRoute.notifications.name);
  }

  static Future<void> navigateToProductDetails(String? productId) async {
    if (productId != null && productId.isNotEmpty) {
      AppRouter().router.pushNamed(
        AppRoute.productDetails.name,
        pathParameters: {'id': productId},
      );
    }
  }

  static Future<void> navigateToOrderDetails(String? orderId) async {
    if (orderId != null && orderId.isNotEmpty) {
      AppRouter().router.pushNamed(
        AppRoute.orderDetails.name,
        pathParameters: {'id': orderId},
      );
    }
  }

  static Future<void> navigateToSubscriptionDetails(
    String? subscriptionId,
  ) async {
    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      AppRouter().router.pushNamed(
        AppRoute.subscriptionDetails.name,
        pathParameters: {'id': subscriptionId},
      );
    }
  }

  static Future<void> navigateToCart() async {
    AppRouter().router.pushNamed(AppRoute.cart.name);
  }

  static Future<void> navigateToAccount() async {
    AppRouter().router.pushNamed(AppRoute.profile.name);
  }

  static Future<void> navigateToHome() async {
    AppRouter().router.goNamed(AppRoute.home.name);
  }

  // Keep pop method if needed, but usually context.pop() is better in widgets.
  // This might be used by back buttons in non-context areas (rare).
  static void goBack() {
    if (AppRouter().router.canPop()) {
      AppRouter().router.pop();
    }
  }
}
