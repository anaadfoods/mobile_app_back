import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/models/category_model.dart';
import 'package:grocery_app/core/theme/theme.dart';

class CategoryCardWidget extends StatefulWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCardWidget({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  State<CategoryCardWidget> createState() => _CategoryCardWidgetState();
}

class _CategoryCardWidgetState extends State<CategoryCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = widget.category.isActive;

    return GestureDetector(
      onTapDown: isActive ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isActive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isActive ? () => setState(() => _isPressed = false) : null,
      onTap: isActive ? widget.onTap : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: AppColors.animFast),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppColors.animMedium),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppColors.radiusM),
            border: Border.all(
              color: isDark ? AppColors.charcoal87 : AppColors.parchment,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(
                  alpha: _isPressed ? 0.02 : AppColors.shadowOpacityLight,
                ),
                blurRadius: _isPressed ? 2 : 6,
                offset: Offset(0, _isPressed ? 1 : 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Opacity(
            opacity: isActive ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : AppColors.parchment,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.category.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: theme.disabledColor,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: theme.cardColor,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          widget.category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
}
