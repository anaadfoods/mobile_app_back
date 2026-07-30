import 'package:grocery_app/common_widgets/global_import.dart';

class ProductHeader extends StatelessWidget {
  final Product product;

  const ProductHeader({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    double discount = ((product.price - product.finalPrice) / product.price) * 100;
    final String weightDisplay = '${product.weight} ${product.weightUnit}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.productCategory.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.parchment.withValues(alpha: 0.12)
                  : AppColors.deepSoilGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.parchment.withValues(alpha: 0.2)
                    : AppColors.deepSoilGreen.withValues(alpha: 0.15),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 12,
                  color: isDark ? AppColors.pureWhite.withValues(alpha: 0.9) : AppColors.deepSoilGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  product.productCategory.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.pureWhite.withValues(alpha: 0.9) : AppColors.deepSoilGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${product.productName}\n',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.parchment : AppColors.charcoal,
                  height: 1.3,
                ),
              ),
              if (weightDisplay.isNotEmpty)
                TextSpan(
                  text: weightDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.parchment.withValues(alpha: 0.7)
                        : AppColors.rawEarth54,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${product.finalPrice.toStringAsFixed(0)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.harvestAmber,
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: isDark
                      ? AppColors.parchment.withValues(alpha: 0.5)
                      : AppColors.rawEarth54,
                ),
              ),
            ),
            const Spacer(),
            if (discount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.harvestAmber),
                ),
                child: Text(
                  '${discount.toStringAsFixed(0)}% OFF',
                  style: const TextStyle(
                    color: AppColors.harvestAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
