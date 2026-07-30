import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/features/products/presentation/widgets/modern_subscription_sheet.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/plan_Search_model.dart';
import 'package:grocery_app/services/plan_search_service.dart';

class ProductSubscriptionHelper {
  static void navigateToAddressScreen({
    required BuildContext context,
    required ProductEntity product,
    required List<SubscriptionPlan> allPlans,
    required List<PlanSearchResult> availablePlansForProduct,
    required bool isSubscription,
    int? selectedPlanIndex,
    required int quantity,
    String? paymentType,
  }) {
    double? price;
    int? selectedPlanId;

    if (isSubscription && selectedPlanIndex != null) {
      final selectedPlanName = allPlans[selectedPlanIndex].name;
      final selectedAvailablePlan = availablePlansForProduct.firstWhere(
        (p) => p.planName == selectedPlanName,
      );
      price = selectedAvailablePlan.discountedPrice;
      selectedPlanId = selectedAvailablePlan.planId;
    }

    context.pushNamed(
      AppRoute.address.name,
      extra: {
        'singleProduct': Product.fromEntity(product),
        'quantity': quantity,
        'isSubscription': isSubscription,
        'price': price,
        'selectedPlan': selectedPlanId ?? 0,
        'paymentType': paymentType,
      },
    );
  }

  static void showSubscriptionSelectionSheet({
    required BuildContext context,
    required ProductEntity product,
    required List<SubscriptionPlan> allPlans,
    required List<PlanSearchResult> availablePlansForProduct,
    required int initialPlanIndex,
    required int initialPlanId,
    required VoidCallback onTriggerHaptic,
  }) {
    int selectedIndex = initialPlanIndex;
    int quantity = 1;
    int paymentOption = 0;

    onTriggerHaptic();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return ModernSubscriptionSheet(
              product: Product.fromEntity(product),
              allPlans: allPlans,
              availablePlansForProduct: availablePlansForProduct,
              selectedIndex: selectedIndex,
              quantity: quantity,
              paymentOption: paymentOption,
              onPlanSelected:
                  (index) => setModalState(() => selectedIndex = index),
              onQuantityChanged:
                  (newQty) => setModalState(() => quantity = newQty),
              onPaymentOptionChanged:
                  (opt) => setModalState(() => paymentOption = opt),
              onSubscribe: () {
                Navigator.pop(context);
                final payType = paymentOption == 1 ? 'INSTALLMENT' : 'PAID_FULL';
                if (selectedIndex == -1) {
                  navigateToAddressScreen(
                    context: context,
                    product: product,
                    allPlans: allPlans,
                    availablePlansForProduct: availablePlansForProduct,
                    isSubscription: false,
                    quantity: quantity,
                    paymentType: 'PAID_FULL',
                  );
                } else {
                  navigateToAddressScreen(
                    context: context,
                    product: product,
                    allPlans: allPlans,
                    availablePlansForProduct: availablePlansForProduct,
                    isSubscription: true,
                    selectedPlanIndex: selectedIndex,
                    quantity: quantity,
                    paymentType: payType,
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
