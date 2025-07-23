import 'package:flutter/material.dart';
import 'package:grocery_app/screens/notifications/notifications_screen.dart';
import 'package:grocery_app/screens/order/order_detail_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/screens/cart/cart_screen.dart';
import 'package:grocery_app/screens/account/account_screen_final.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/models/product_model.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    final context = _instance.navigatorKey.currentContext;
    if (context != null && orderId != null) {
      // For now, navigate to notifications screen as order details require Order object
      await navigateToNotifications();
    }
  }

  /// Navigate to product details
  static Future<void> navigateToProductDetails(String? productId) async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null && productId != null) {
      // For now, navigate to notifications screen as product details require Product object
      await navigateToNotifications();
    }
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

  /// Navigate to subscription details
  static Future<void> navigateToSubscriptionDetails(
    String? subscriptionId,
  ) async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null && subscriptionId != null) {
      // For now, navigate to notifications screen as subscription details require specific parameters
      await navigateToNotifications();
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

  /// Get the navigator key for use in MaterialApp
  static GlobalKey<NavigatorState> get globalNavigatorKey =>
      _instance.navigatorKey;
}
