import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/features/orders/domain/entities/order_entity.dart';
import 'package:grocery_app/features/products/presentation/screens/product_details_screen.dart';
import 'order_detail_card.dart';

class OrderProductsCard extends StatelessWidget {
  final List<OrderItemEntity> items;

  const OrderProductsCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OrderDetailCard(
      icon: Icons.shopping_basket_rounded,
      title: 'Items Ordered',
      color: AppColors.harvestAmber,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return _buildProductItem(context, theme, isDark, item, isLast);
        },
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    OrderItemEntity item,
    bool isLast,
  ) {
    final product = item.productDetails;
    final imageUrl = product.productImages.isNotEmpty
        ? product.productImages[0].image
        : null;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: Product.fromEntity(product)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.parchment.withValues(alpha: 0.05)
                  : AppColors.rawEarth54.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Product image
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.parchment,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.parchment,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildImagePlaceholder(isDark),
                          )
                        : _buildImagePlaceholder(isDark),
                  ),
                ),
                const SizedBox(width: 14),
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.harvestAmber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Qty: ${item.quantity}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.harvestAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '× ₹${product.finalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.total.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.harvestAmber,
                      ),
                    ),
                    if (product.discountPercentage > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.harvestAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.harvestAmber,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.parchment24 : AppColors.rawEarth26,
        size: 24,
      ),
    );
  }
}
