import 'package:flutter/material.dart';
import 'package:grocery_app/routes/app_router.dart';
import 'package:grocery_app/routes/app_routes.dart';

import 'package:grocery_app/service_locator.dart';

/// Centralized navigation service using AppRouter.
class NavigationService {
  factory NavigationService() => getIt<NavigationService>();
  NavigationService._internal();
  static NavigationService create() => NavigationService._internal();

  /// Get the navigator state safely from AppRouter
  NavigatorState? get _navigator =>
      AppRouter().router.routerDelegate.navigatorKey.currentState;

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
    AppRouter().router.goNamed(AppRoute.notifications.name);
  }

  static Future<void> navigateToProductDetails(String? productId) async {
    if (productId != null && productId.isNotEmpty) {
      AppRouter().router.goNamed(
        AppRoute.productDetails.name,
        pathParameters: {'id': productId},
      );
    }
  }

  static Future<void> navigateToOrderDetails(String? orderId) async {
    if (orderId != null && orderId.isNotEmpty) {
      AppRouter().router.goNamed(
        AppRoute.orderDetails.name,
        pathParameters: {'id': orderId},
      );
    }
  }

  static Future<void> navigateToSubscriptionDetails(
    String? subscriptionId,
  ) async {
    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      AppRouter().router.goNamed(
        AppRoute.subscriptionDetails.name,
        pathParameters: {'id': subscriptionId},
      );
    }
  }

  static Future<void> navigateToCart() async {
    AppRouter().router.goNamed(AppRoute.cart.name);
  }

  static Future<void> navigateToAllProducts() async {
    AppRouter().router.goNamed(AppRoute.allProducts.name);
  }

  static Future<void> navigateToOrderList() async {
    AppRouter().router.goNamed(AppRoute.orderList.name);
  }

  static Future<void> navigateToSubscriptionList() async {
    AppRouter().router.goNamed(AppRoute.subscriptionList.name);
  }

  static Future<void> navigateToPanchang() async {
    AppRouter().router.goNamed(AppRoute.panchang.name);
  }

  static Future<void> navigateToWishlist() async {
    AppRouter().router.goNamed(AppRoute.wishlist.name);
  }

  static Future<void> navigateToCheckout() async {
    AppRouter().router.goNamed(AppRoute.checkout.name);
  }

  static Future<void> navigateToAccount() async {
    AppRouter().router.goNamed(AppRoute.profile.name);
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
