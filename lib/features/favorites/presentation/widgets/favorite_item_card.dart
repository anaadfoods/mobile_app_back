import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/features/favorites/domain/entities/favorite_entity.dart';
import 'package:grocery_app/styles/colors.dart';

class FavoriteItemCard extends StatelessWidget {
  final FavoriteEntity favorite;
  final int quantity;
  final bool isDark;
  final bool isProcessing;
  final bool isBeingRemoved;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  const FavoriteItemCard({
    super.key,
    required this.favorite,
    required this.quantity,
    required this.isDark,
    required this.isProcessing,
    required this.isBeingRemoved,
    required this.onRemove,
    required this.onTap,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('favorite_${favorite.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.rawEarth,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.parchment,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Image with Heart Overlay
              Stack(
                children: [
                  Hero(
                    tag: 'favorite_image_${favorite.productId}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.parchment,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: favorite.image,
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
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Heart Badge
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.rawEarth,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.rawEarth.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isBeingRemoved
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.parchment,
                                ),
                              )
                            : const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.parchment,
                                size: 12,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryCapsule(favorite.productCategory, theme, isDark),
                    const SizedBox(height: 4),
                    Text(
                      favorite.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildQuantityTag(favorite.weight, theme, isDark),
                    const SizedBox(height: 8),
                    Text(
                      '₹${favorite.price}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.harvestAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Cart Actions
              Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isProcessing && !isBeingRemoved
                        ? Container(
                            width: 100,
                            height: 44,
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                        : quantity == 0
                            ? _buildAddToCartButton(theme)
                            : _buildQuantitySelector(theme, isDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCapsule(String category, ThemeData theme, bool isDark) {
    if (category.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        category.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantityTag(String weight, ThemeData theme, bool isDark) {
    if (weight.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceElevated
            : theme.colorScheme.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? AppColors.darkSurface
              : theme.colorScheme.secondary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        weight,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(ThemeData theme) {
    return GestureDetector(
      onTap: () => onQuantityChanged(1),
      child: Container(
        width: 100,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.amberWarnBg,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.amberWarnBg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(ThemeData theme, bool isDark) {
    return Container(
      width: 100,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuantityButton(
            Icons.remove_rounded,
            () => onQuantityChanged(quantity - 1),
            theme,
            isDark,
          ),
          Text(
            '$quantity',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildQuantityButton(
            Icons.add_rounded,
            () => onQuantityChanged(quantity + 1),
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.parchment,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.secondary),
      ),
    );
  }
}
