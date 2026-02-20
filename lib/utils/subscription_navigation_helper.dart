import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
// ignore: unused_import
import 'package:grocery_app/screens/product_details/product_details_screen.dart';

class SubscriptionNavigationHelper {
  static Future<void> navigateToProductDetails(
    BuildContext context,
    Product product,
  ) async {
    // Navigate to ProductDetailsScreen with autoOpenSubscription set to true.
    // The screen itself handles loading plans and selecting the default (max duration)
    // if no initialPlanId is provided.
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(
        ProductDetailsScreen(product: product, autoOpenSubscription: true),
      ),
    );
  }
}
