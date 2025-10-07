import 'package:flutter/material.dart';
import 'package:grocery_app/models/subscription_model.dart';
import 'package:grocery_app/screens/MySubscriptionPlan/subscription_plan_detail_single.dart';
import 'package:grocery_app/screens/dashboard/dashboard_screen.dart';
import 'package:grocery_app/screens/notifications/notifications_screen.dart';
import 'package:grocery_app/screens/order/order_detail_screen.dart';
import 'package:grocery_app/screens/product_details/product_details_screen.dart';
import 'package:grocery_app/screens/cart/cart_screen.dart';
import 'package:grocery_app/screens/account/account_screen_final.dart';
import 'package:grocery_app/models/order_model.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/services/subscription_service.dart';

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
    final context = _instance.navigatorKey.currentContext;
    if (context != null && orderId != null) {
      final OrderModel order = await OrderService().getOrderById(
        orderId as int,
      );
      // For now, navigate to notifications screen as order details require Order object
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(order: order as Order),
        ),
      );
    }
  }

  /// Navigate to product details
  static Future<void> navigateToSubscriptionDetails(
    String? subscriptionId,
  ) async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null && subscriptionId != null) {
      final result = await SubscriptionService().getSubscriptionDetails(
        int.parse(subscriptionId),
      );
      if (result['success'] == true && result['data'] != null) {
        final subscription = result['data'] as Subscription;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    SubscriptionPlanDetailScreen(subscription: subscription),
          ),
        );
      }
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

  /// Navigate to promo/offer details (placeholder)
  static Future<void> navigateToPromoDetails(String? promoId) async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null && promoId != null) {
      // For now, navigate to notifications screen as a fallback
      await navigateToNotifications();
    }
  }

  static Future<void> navigateToProductDetails(String? productId) async {
    final context = _instance.navigatorKey.currentContext;
    if (context != null && productId != null) {
      final result = await CategoryService.fetchProductById(
        int.parse(productId),
      );
      final product = result;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(product: product),
        ),
      );
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
