import 'dart:ui';
import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/out_of_stock_overlay.dart';

/// Skeleton loading placeholder for the featured products section.
///
/// Extracted from `home_screen.dart`.
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
              ShimmerLoading(
                isLoading: true,
                child: Skeleton(width: 160, height: 22),
              ),
              ShimmerLoading(
                isLoading: true,
                child: Skeleton(width: 70, height: 22),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return ShimmerLoading(
                isLoading: true,
                child: Container(
                  width: 165,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.charcoal87
                                    : AppColors.parchment,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(width: double.infinity, height: 16),
                              const SizedBox(height: 8),
                              Skeleton(width: 60, height: 12),
                              const Spacer(),
                              Skeleton(width: 80, height: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single featured product card shown in the horizontal list.
///
/// Extracted from `home_screen.dart`.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = product.discountPercentage > 0;

    return GestureDetector(
      onTap: (product.isInStock && product.isActive) ? onTap : null,
      child: Opacity(
        opacity: (product.isInStock && product.isActive) ? 1.0 : 0.5,
        child: Stack(
          children: [
            Container(
              width: 165,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? AppColors.charcoal26
                            : AppColors.charcoal.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [AppColors.darkCanvas, AppColors.darkCanvas]
                                  : _gradients[index % _gradients.length],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child:
                                product.productImages.isNotEmpty
                                    ? CachedNetworkImage(
                                      imageUrl: product.productImages[0].image,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 300,
                                      memCacheHeight: 300,
                                      placeholder:
                                          (_, __) => Center(
                                            child: Icon(
                                              _icons[index % _icons.length],
                                              size: 48,
                                              color: _iconColors[index %
                                                      _iconColors.length]
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                      errorWidget:
                                          (_, __, ___) => Center(
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
                                        color: _iconColors[index %
                                                _iconColors.length]
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
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
                      ],
                    ),
                  ),
                  // Details section
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.weight} ${product.weightUnit}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '₹${product.price.toStringAsFixed(0)}',
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
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: const ComingSoonOverlay(),
                  ),
                ),
              )
            else if (!product.isInStock)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
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
