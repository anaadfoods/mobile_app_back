import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/common_widgets/guest_login_prompt.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/core/analytics/analytics_service.dart';

class AddToCartButton extends StatelessWidget {
  final ProductEntity product;

  const AddToCartButton({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final cartCubit = context.read<CartCubit>();
        int quantity = 0;

        if (state is CartSuccess) {
          final item = state.cart.items.cast<CartItem?>().firstWhere(
            (item) => item?.productVariant.id == product.id,
            orElse: () => null,
          );
          quantity = item?.quantity ?? 0;
        }

        if (quantity > 0) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is Unauthenticated) {
                      GuestAuthHelper.showGuestLoginBottomSheet(
                        context,
                        title: 'Login Required',
                        subtitle: 'Please log in to manage your cart.',
                      );
                      return;
                    }
                    AnalyticsService().trackClick(
                      elementText: 'Decrease Cart: ${product.name}',
                      componentName: 'cart_decrease_btn',
                      properties: {
                        'product_id': product.id,
                        'product_name': product.name,
                        'previous_quantity': quantity,
                      },
                    );
                    cartCubit.removeItem(product.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: AppColors.deepSoilGreen,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepSoilGreen,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is Unauthenticated) {
                      GuestAuthHelper.showGuestLoginBottomSheet(
                        context,
                        title: 'Login Required',
                        subtitle: 'Please log in to manage your cart.',
                      );
                      return;
                    }
                    AnalyticsService().trackClick(
                      elementText: 'Increase Cart: ${product.name}',
                      componentName: 'cart_increase_btn',
                      properties: {
                        'product_id': product.id,
                        'product_name': product.name,
                        'previous_quantity': quantity,
                      },
                    );
                    cartCubit.addItem(Product.fromEntity(product), 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.deepSoilGreen,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            final authState = context.read<AuthCubit>().state;
            if (authState is Unauthenticated) {
              GuestAuthHelper.showGuestLoginBottomSheet(
                context,
                title: 'Login Required',
                subtitle: 'Please log in to add items to your cart.',
              );
              return;
            }
            HapticFeedback.lightImpact();
            AnalyticsService().trackClick(
              elementText: 'Add to Cart: ${product.name}',
              componentName: 'add_to_cart_btn',
              properties: {
                'product_id': product.id,
                'product_name': product.name,
              },
            );
            cartCubit.addItem(Product.fromEntity(product), 1);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, size: 18, color: AppColors.parchment),
          ),
        );
      },
    );
  }
}
