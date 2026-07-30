import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/out_of_stock_overlay.dart';
import 'package:grocery_app/common_widgets/guest_login_prompt.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/features/products/presentation/widgets/add_to_cart_button.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final int index;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.onTap,
  });

  Widget _buildCategoryCapsule(String category, ThemeData theme, bool isDark) {
    if (category.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.parchment.withValues(alpha: 0.1)
            : AppColors.harvestAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.parchment.withValues(alpha: 0.15)
              : AppColors.harvestAmber.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.pureWhite.withValues(alpha: 0.9) : AppColors.harvestAmber,
          fontWeight: FontWeight.bold,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantityTag(String weight, String unit, ThemeData theme, bool isDark) {
    if (weight.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.charcoal.withValues(alpha: 0.3)
            : AppColors.parchment,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? AppColors.parchment.withValues(alpha: 0.1)
              : theme.dividerColor.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        '$weight $unit',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDiscount = product.discountPercentage > 0;

    return GestureDetector(
      onTap: (product.isInStock && product.isActive) ? onTap : null,
      child: Opacity(
        opacity: (product.isInStock && product.isActive) ? 1.0 : 0.5,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.charcoal26
                        : AppColors.charcoal.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            gradient: isDark
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.darkCanvas,
                                      AppColors.darkCanvas,
                                    ],
                                  )
                                : _getDummyGradient(index),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: _buildProductImage(product, index),
                          ),
                        ),
                        // Discount badge
                        if (hasDiscount)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.harvestAmber,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.harvestAmber.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${product.discountPercentage.toInt()}% OFF',
                                style: const TextStyle(
                                  color: AppColors.pureWhite,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Favorite button (Functional & Dynamic)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: BlocBuilder<FavoritesCubit, FavoritesState>(
                            builder: (context, state) {
                              final isFavorite = state is FavoritesSuccess &&
                                  state.favorites.any((fav) => fav.productId == product.id);

                              return GestureDetector(
                                onTap: () {
                                  final authState = context.read<AuthCubit>().state;
                                  if (authState is Unauthenticated) {
                                    GuestAuthHelper.showGuestLoginBottomSheet(
                                      context,
                                      title: 'Login Required',
                                      subtitle: 'Please log in to add items to your favorites.',
                                      icon: Icons.favorite_border_rounded,
                                    );
                                    return;
                                  }
                                  HapticFeedback.lightImpact();
                                  context.read<FavoritesCubit>().toggleFavorite(product.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.parchment.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    size: 18,
                                    color: isFavorite
                                        ? AppColors.rawEarth
                                        : (isDark ? AppColors.charcoal54 : AppColors.charcoal45),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details section
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCategoryCapsule(product.productCategory, theme, isDark),
                        const SizedBox(height: 4),
                        Text(
                          product.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildQuantityTag(product.weight, product.weightUnit, theme, isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '₹${product.finalPrice.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getPriceColor(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.hintColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            AddToCartButton(product: product),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!product.isActive)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: isDark ? Colors.black.withValues(alpha: 0.72) : Colors.white.withValues(alpha: 0.72),
                    child: const ComingSoonOverlay(),
                  ),
                ),
              )
            else if (!product.isInStock)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: isDark ? Colors.black.withValues(alpha: 0.72) : Colors.white.withValues(alpha: 0.72),
                    child: const OutOfStockOverlay(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getDummyGradient(int index) {
    final gradients = [
      [AppColors.parchment, AppColors.parchment],
      [AppColors.parchment, AppColors.parchment],
      [AppColors.parchment, AppColors.parchment],
      [AppColors.parchment, AppColors.parchment],
      [AppColors.parchment, AppColors.parchment],
      [AppColors.parchment, AppColors.parchment],
    ];
    final colors = gradients[index % gradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  Widget _buildProductImage(ProductEntity product, int index) {
    if (product.productImages.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: product.productImages[0].image,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => _buildDummyFoodImage(index),
        placeholder: (context, url) => Container(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
      );
    }
    return _buildDummyFoodImage(index);
  }

  Widget _buildDummyFoodImage(int index) {
    final images = [
      'assets/images/placeholder_veg.png',
    ];
    final img = images[index % images.length];
    return Image.asset(
      img,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.harvestAmber.withValues(alpha: 0.1),
        child: const Icon(
          Icons.restaurant_menu_rounded,
          color: AppColors.harvestAmber,
          size: 40,
        ),
      ),
    );
  }
}

