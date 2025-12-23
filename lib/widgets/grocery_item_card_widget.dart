import 'package:collection/collection.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class GroceryItemCardWidget extends StatefulWidget {
  final Product item;
  final String? heroSuffix;
  final VoidCallback? onTap;

  const GroceryItemCardWidget({
    super.key,
    required this.item,
    this.heroSuffix,
    this.onTap,
  });

  @override
  State<GroceryItemCardWidget> createState() => _GroceryItemCardWidgetState();
}

class _GroceryItemCardWidgetState extends State<GroceryItemCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: AppColors.animFast),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppColors.animMedium),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppColors.radiusL),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(
                  _isPressed ? 0.02 : AppColors.shadowOpacityLight,
                ),
                blurRadius: _isPressed ? 4 : 8,
                offset: Offset(0, _isPressed ? 1 : 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radiusL),
            child: Row(
              children: [
                // Product Image Container
                Container(
                  margin: const EdgeInsets.all(AppColors.spacingS),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppColors.radiusM),
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppColors.radiusM),
                    child: Hero(
                      tag: '${widget.item.id}-${widget.heroSuffix ?? ''}',
                      child: _buildImageWidget(theme),
                    ),
                  ),
                ),
                // Product Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.spacingM,
                      vertical: AppColors.spacingM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: widget.item.productName,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          text: widget.item.productCategory,
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Rating stars
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.orderPlaced,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AppText(
                              text:
                                  "₹${widget.item.finalPrice.toStringAsFixed(0)}",
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.item.price > widget.item.finalPrice)
                              AppText(
                                text:
                                    "₹${widget.item.price.toStringAsFixed(0)}",
                                style: textTheme.bodySmall?.copyWith(
                                  color: theme.disabledColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            const Spacer(),
                            _buildActionWidget(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(ThemeData theme) {
    if (widget.item.productImages.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.item.productImages[0].image,
        fit: BoxFit.cover,
        placeholder:
            (context, url) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget:
            (context, url, error) =>
                Icon(Icons.broken_image, size: 40, color: theme.disabledColor),
      );
    } else {
      return Icon(
        Icons.image_not_supported,
        size: 40,
        color: theme.disabledColor,
      );
    }
  }

  Widget _buildActionWidget(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) {
        final prevQty = _getItemQuantity(previous, widget.item.id);
        final currQty = _getItemQuantity(current, widget.item.id);
        return prevQty != currQty;
      },
      builder: (context, state) {
        final cartCubit = context.read<CartCubit>();
        final quantity = _getItemQuantity(state, widget.item.id);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder:
              (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
          child:
              quantity > 0
                  ? ItemCounterWidget(
                    key: ValueKey('counter_${widget.item.id}'),
                    amount: quantity,
                    onAmountChanged: (newQty) {
                      if (newQty == 0) {
                        cartCubit.removeItem(widget.item.id);
                      } else {
                        cartCubit.updateItem(widget.item.id, newQty);
                      }
                    },
                  )
                  : ElevatedButton(
                    key: const ValueKey('addButton'),
                    onPressed: () {
                      cartCubit.addItem(widget.item, 1);
                    },
                    child: const Text("Add"),
                  ),
        );
      },
    );
  }

  int _getItemQuantity(CartState state, int productId) {
    if (state is CartSuccess) {
      final cartItem = state.cart.items.firstWhereOrNull(
        (item) => item.productVariant.id == productId,
      );
      return cartItem?.quantity ?? 0;
    }
    return 0;
  }
}
