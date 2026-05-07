import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/core/theme/theme.dart';

class ChartItemWidget extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const ChartItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        border: Border.all(
          color: isDark ? AppColors.charcoal87 : AppColors.parchment,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(
              alpha: AppColors.shadowOpacityLight,
            ),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppColors.spacingM),
      child: Row(
        children: [
          // Product Image
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppColors.radiusM),
              color: isDark ? AppColors.charcoal : AppColors.parchment,
              border: Border.all(
                color: isDark ? AppColors.charcoal60 : AppColors.parchment,
                width: 1,
              ),
            ),
            child:
                item.productVariant.productImages.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppColors.radiusM),
                      child: Image.network(
                        item.productVariant.productImages.first.image,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.image_not_supported,
                              color: theme.disabledColor,
                            ),
                      ),
                    )
                    : Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.disabledColor,
                    ),
          ),
          const SizedBox(width: AppColors.spacingM),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: item.productVariant.productName,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppColors.spacingXS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '₹${item.productVariant.finalPrice.toStringAsFixed(0)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppColors.spacingS),
                    ItemCounterWidget(
                      onAmountChanged: onQuantityChanged,
                      amount: item.quantity,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppColors.spacingXS),
          // Remove Button
          Container(
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: 22,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusXL),
                      ),
                      title: const Text('Remove Item'),
                      content: const Text(
                        'Are you sure you want to remove this item from your cart?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: context.text.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            onRemove();
                            Navigator.of(context).pop();
                            SnackBarHelper.showSuccess(
                              context,
                              'Item removed from cart',
                            );
                          },
                          style: theme.elevatedButtonTheme.style,
                          child: const Text('Remove'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
