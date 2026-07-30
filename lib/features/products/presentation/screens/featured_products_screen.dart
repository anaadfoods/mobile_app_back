import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/shimmer_loading.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/common_widgets/grocery_item_card_widget.dart';
import 'package:grocery_app/common_widgets/skeleton_widgets.dart';
import 'package:grocery_app/features/products/domain/entities/product_entity.dart';
import 'package:grocery_app/features/products/presentation/widgets/product_card.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/routes/app_router.dart';
import 'package:grocery_app/helpers/skelton.dart';
import 'package:grocery_app/routes/app_routes.dart';

class FeaturedProductsScreen extends StatefulWidget {
  final List<ProductEntity> products;

  const FeaturedProductsScreen({super.key, required this.products});

  @override
  State<FeaturedProductsScreen> createState() => _FeaturedProductsScreenState();
}

class _FeaturedProductsScreenState extends State<FeaturedProductsScreen> {
  late List<ProductEntity> _products;
  String _sortBy = 'featured';
  bool _isGridView = false;
  bool _showShimmer = true;

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.products);
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _showShimmer = false);
    });
  }

  void _sortProducts(String sortType) {
    setState(() {
      _sortBy = sortType;
      switch (sortType) {
        case 'price_low':
          _products.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
          break;
        case 'price_high':
          _products.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
          break;
        case 'discount':
          _products.sort(
            (a, b) => b.discountPercentage.compareTo(a.discountPercentage),
          );
          break;
        default:
          _products = List.from(widget.products);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.parchment,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            floating: false,
            centerTitle: false,
            titleSpacing: 0,
            toolbarHeight: 72.0,
            backgroundColor: AppColors.deepSoilGreen,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Newly Harvested',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_products.length} products available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.parchment.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.parchment),
              onPressed: () => Navigator.maybePop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    size: 20,
                  ),
                ),
                color: AppColors.parchment,
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Sort chips
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSortChip('Featured', 'featured', Icons.star_rounded, isDark),
                    _buildSortChip('Price: Low', 'price_low', Icons.arrow_downward, isDark),
                    _buildSortChip('Price: High', 'price_high', Icons.arrow_upward, isDark),
                    _buildSortChip('Best Deals', 'discount', Icons.local_offer_rounded, isDark),
                  ],
                ),
              ),
            ),
          ),

          // Products grid/list
          _showShimmer
              ? _buildShimmerSliver(isDark)
              : _isGridView
                  ? _buildGridView(theme, isDark)
                  : _buildListView(theme, isDark),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildShimmerSliver(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerLoading(
              isLoading: true,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.charcoal87 : AppColors.parchment,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Skeleton(width: double.infinity, height: 14),
                          const SizedBox(height: 8),
                          Skeleton(width: 120, height: 12),
                          const SizedBox(height: 10),
                          Skeleton(width: 80, height: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.charcoal60 : AppColors.parchment,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childCount: 8,
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon, bool isDark) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _sortProducts(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.deepSoilGreen
                : (isDark ? AppColors.charcoal87 : AppColors.parchment),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.deepSoilGreen : AppColors.transparent,
            ),
            boxShadow: isSelected
                ? null
                : [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.parchment
                    : (isDark ? AppColors.parchment70 : AppColors.charcoal54),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.parchment
                      : (isDark ? AppColors.parchment70 : AppColors.charcoal87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(ThemeData theme, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductCard(
            product: _products[index],
            index: index,
            onTap: () => _onProductTap(_products[index]),
          ),
          childCount: _products.length,
        ),
      ),
    );
  }

  Widget _buildListView(ThemeData theme, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _products[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: product.isActive ? (product.isInStock ? 1.0 : 0.5) : 1.0,
                child: GroceryItemCardWidget(
                  item: Product.fromEntity(product),
                  heroSuffix: 'featured_list_$index',
                  onTap: (product.isInStock && product.isActive)
                      ? () => _onProductTap(product)
                      : null,
                ),
              ),
            );
          },
          childCount: _products.length,
        ),
      ),
    );
  }

  void _onProductTap(ProductEntity product) {
    if (!product.isInStock) return;
    HapticFeedback.lightImpact();
    context.pushNamed(
      AppRoute.productDetails.name,
      pathParameters: {'id': product.id.toString()},
      extra: Product.fromEntity(product),
    );
  }
}
