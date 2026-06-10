import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class SimilarProductsSection extends StatelessWidget {
  final Product product;
  final bool isLoadingSimilarProduct;
  final List<Product> similarProducts;
  final Function(BuildContext, Product) onProductClicked;

  const SimilarProductsSection({
    super.key,
    required this.product,
    required this.isLoadingSimilarProduct,
    required this.similarProducts,
    required this.onProductClicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoadingSimilarProduct) {
      return _buildSimilarProductsSkeleton();
    }

    if (similarProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    final int currentId = product.id;
    final filtered = similarProducts.where((p) => p.id != currentId).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Similar Products",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.parchment : AppColors.charcoal,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  AnimatedTransitions.slideFromRight(
                    CategoryItemsScreen(
                      name: product.productCategory,
                      allProducts: filtered,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    "See All",
                    style: TextStyle(
                      color: isDark ? AppColors.parchment : AppColors.pureBlack,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: isDark ? AppColors.parchment : AppColors.pureBlack,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),

        ListView.builder(
          itemCount: filtered.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final productItem = filtered[index];
            return Opacity(
              opacity: productItem.isActive ? (productItem.isInStock ? 1.0 : 0.5) : 1.0,
              child: GroceryItemCardWidget(
                item: productItem,
                heroSuffix: "similar_products",
                onTap:
                    (productItem.isInStock && productItem.isActive)
                        ? () => onProductClicked(context, productItem)
                        : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSimilarProductsSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.rawEarth12,
      highlightColor: AppColors.parchment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.rawEarth12,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.rawEarth12,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
