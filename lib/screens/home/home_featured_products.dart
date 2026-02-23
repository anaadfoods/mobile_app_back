import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

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
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
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
    [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
    [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
    [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
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
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFFD32F2F),
    Color(0xFF7B1FA2),
    Color(0xFFF9A825),
    Color(0xFF795548),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = product.discountPercentage > 0;

    return GestureDetector(
      onTap: (product.isInStock && product.tag) ? onTap : null,
      child: Opacity(
        opacity: (product.isInStock && product.tag) ? 1.0 : 0.5,
        child: Stack(
          children: [
            Container(
          width: 165,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black26
                        : Colors.black.withValues(alpha: 0.08),
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
                          colors: _gradients[index % _gradients.length],
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
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.discountPercentage.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
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
                              color: AppColors.primaryColor,
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
            if (!product.tag) const ComingSoonOverlay(),
          ],
        ),
      ),
    );
  }
}
