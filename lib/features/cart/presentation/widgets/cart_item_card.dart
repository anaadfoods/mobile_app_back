import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/models/cart_model.dart';

class CartItemCard extends StatefulWidget {
  final CartItem item;
  final VoidCallback onTap;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.parchment,
              width: _isPressed ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(
                  alpha: _isPressed ? 0.12 : 0.06,
                ),
                blurRadius: _isPressed ? 16 : 8,
                offset: Offset(0, _isPressed ? 6 : 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Image
              Hero(
                tag: 'cart_product_${item.productVariant.id}',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: item.productVariant.productImages.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.productVariant.productImages.first.image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported_rounded,
                              color: theme.disabledColor,
                            ),
                          )
                        : Icon(
                            Icons.shopping_bag_outlined,
                            color: theme.disabledColor,
                            size: 32,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productVariant.productName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.productVariant.weight} ${item.productVariant.weightUnit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price
                        FittedBox(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '₹${item.productVariant.finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.harvestAmber,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Quantity Controls
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FittedBox(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildQuantityButton(
                                  theme,
                                  Icons.remove,
                                  () => widget.onQuantityChanged(
                                    item.quantity - 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _buildQuantityButton(
                                  theme,
                                  Icons.add,
                                  () => widget.onQuantityChanged(
                                    item.quantity + 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button
              Material(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _showRemoveDialog(context, theme),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton(
    ThemeData theme,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: theme.colorScheme.secondary),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Remove Item'),
        content: const Text(
          'Are you sure you want to remove this item from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onRemove();
              Navigator.pop(context);
              SnackBarHelper.showSuccess(context, 'Item removed from cart');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: AppColors.parchment,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
