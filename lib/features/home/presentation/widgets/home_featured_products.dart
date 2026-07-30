import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/out_of_stock_overlay.dart';
import 'package:grocery_app/models/product_model.dart';

class FeaturedProductsSkeleton extends StatelessWidget {
  const FeaturedProductsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 160, height: 22, color: Colors.grey.withValues(alpha: 0.2)),
              Container(width: 70, height: 22, color: Colors.grey.withValues(alpha: 0.2)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 165,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.charcoal : AppColors.parchment,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FeaturedProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final bool isDark;
  final VoidCallback? onTap;

  const FeaturedProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.isDark,
    this.onTap,
  });

  static const _gradients = [
    [AppColors.softCream, AppColors.parchment],
    [AppColors.lightGold, AppColors.parchment],
    [AppColors.softCream, AppColors.parchment],
    [AppColors.lightGold, AppColors.parchment],
    [AppColors.softCream, AppColors.parchment],
    [AppColors.lightGold, AppColors.parchment],
  ];

  static const _icons = [
    Icons.bakery_dining_rounded,
    Icons.rice_bowl_rounded,
    Icons.local_pizza_rounded,
    Icons.icecream_rounded,
    Icons.egg_alt_rounded,
    Icons.breakfast_dining_rounded,
  ];

  static const _iconColors = [
    AppColors.deepSoilGreen,
    AppColors.harvestAmber,
    AppColors.deepSoilGreen,
    AppColors.harvestAmber,
    AppColors.deepSoilGreen,
    AppColors.harvestAmber,
  ];

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
          color: isDark
              ? AppColors.pureWhite.withValues(alpha: 0.9)
              : AppColors.harvestAmber,
          fontWeight: FontWeight.bold,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantityTag(
      String weight, String unit, ThemeData theme, bool isDark) {
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
    final hasDiscount = product.discountPercentage > 0;

    return GestureDetector(
      onTap: (product.isInStock && product.isActive) ? onTap : null,
      child: Opacity(
        opacity: product.isActive ? (product.isInStock ? 1.0 : 0.5) : 1.0,
        child: Stack(
          children: [
            Container(
              width: 165,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoal : AppColors.parchment,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppColors.charcoal.withValues(alpha: 0.26)
                        : AppColors.charcoal.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [AppColors.charcoal, AppColors.charcoal]
                                  : _gradients[index % _gradients.length],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: product.productImages.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: product.productImages[0].image,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 300,
                                    memCacheHeight: 300,
                                    placeholder: (_, __) => Center(
                                      child: Icon(
                                        _icons[index % _icons.length],
                                        size: 48,
                                        color: _iconColors[index %
                                                _iconColors.length]
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Center(
                                      child: Icon(
                                        _icons[index % _icons.length],
                                        size: 48,
                                        color: _iconColors[index %
                                                _iconColors.length]
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      _icons[index % _icons.length],
                                      size: 48,
                                      color: _iconColors[
                                              index % _iconColors.length]
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                          ),
                        ),
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
                                    color: AppColors.harvestAmber
                                        .withValues(alpha: 0.3),
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
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCategoryCapsule(
                            product.productCategory, theme, isDark),
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
                        _buildQuantityTag(
                            product.weight, product.weightUnit, theme, isDark),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '\u20B9${product.finalPrice.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getPriceColor(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '\u20B9${product.price.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: theme.hintColor,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.72)
                        : Colors.white.withValues(alpha: 0.72),
                    child: const ComingSoonOverlay(),
                  ),
                ),
              )
            else if (!product.isInStock)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.72)
                        : Colors.white.withValues(alpha: 0.72),
                    child: const OutOfStockOverlay(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
