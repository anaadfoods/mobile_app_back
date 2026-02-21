import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/utils/subscription_navigation_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/routes/app_routes.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key, this.products});
  final List<Product>? products;

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  // Keeping original loading logic
  final CategoryService _productService = CategoryService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  // New UI state variables
  String _sortBy = 'featured';
  bool _isGridView =
      false; // Default to list view as requested for FeaturedProductsScreen previously, keeping consistent

  @override
  void initState() {
    super.initState();
    _loadProducts(widget.products ?? []);
  }

  Future<void> _loadProducts(List<Product> products) async {
    try {
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
          // In a real scenario we might re-fetch or keep original order.
          // For now, if we don't have the original order stored, we just leave it.
          // Or we could store original list in initState.
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Categories')),
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Categories')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppColors.spacingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppColors.spacingL),
                Text(
                  _error!,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Categories')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppColors.spacingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: theme.disabledColor.withOpacity(0.5),
                ),
                const SizedBox(height: AppColors.spacingL),
                Text(
                  'No products available',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppColors.spacingS),
                Text(
                  'Check back later for new products',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF1A1A1A) : AppColors.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                            : [
                              AppColors.primaryColor,
                              AppColors.primaryColor.withOpacity(0.8),
                            ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(60, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Product Categories',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_products.length} products available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
              color: Colors.white,
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    size: 20,
                  ),
                ),
                color: Colors.white,
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
                    _buildSortChip(
                      'Featured',
                      'featured',
                      Icons.star_rounded,
                      isDark,
                    ),
                    _buildSortChip(
                      'Price: Low',
                      'price_low',
                      Icons.arrow_downward,
                      isDark,
                    ),
                    _buildSortChip(
                      'Price: High',
                      'price_high',
                      Icons.arrow_upward,
                      isDark,
                    ),
                    _buildSortChip(
                      'Best Deals',
                      'discount',
                      Icons.local_offer_rounded,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Products grid/list
          _isGridView
              ? _buildGridView(theme, isDark)
              : _buildListView(theme, isDark),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSortChip(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _sortProducts(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primaryColor
                    : (isDark ? Colors.grey[850] : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
            ),
            boxShadow:
                isSelected
                    ? null
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                color:
                    isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
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
          (context, index) => _FeaturedProductCard(
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
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GroceryItemCardWidget(
              item: _products[index],
              heroSuffix: 'all_products_list_$index',
              onTap: () => _onProductTap(_products[index]),
            ),
          ),
          childCount: _products.length,
        ),
      ),
    );
  }

  void _onProductTap(Product product) {
    if (!product.isInStock) return;
    HapticFeedback.lightImpact();
    context.pushNamed(
      AppRoute.productDetails.name,
      pathParameters: {'id': product.id.toString()},
      extra: product,
    );
  }
}

// Grid card for products (Copied from FeaturedProductsScreen)
class _FeaturedProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final VoidCallback onTap;

  const _FeaturedProductCard({
    required this.product,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDiscount = product.discountPercentage > 0;

    return GestureDetector(
      onTap: product.isInStock ? onTap : null,
      child: Opacity(
        opacity: product.isInStock ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                        gradient: _getDummyGradient(index),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: _buildProductImage(product, index),
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
                    // Favorite button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: isDark ? Colors.black54 : Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Details section
              Padding(
                padding: const EdgeInsets.all(12),
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
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.hintColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _AddToCartButton(product: product),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getDummyGradient(int index) {
    final gradients = [
      [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)], // Orange light
      [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)], // Green light
      [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)], // Pink light
      [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)], // Blue light
      [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)], // Purple light
      [const Color(0xFFFFFDE7), const Color(0xFFFFF9C4)], // Yellow light
    ];
    final colors = gradients[index % gradients.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  Widget _buildProductImage(Product product, int index) {
    if (product.productImages.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: product.productImages[0].image,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildDummyFoodImage(index),
        errorWidget: (_, __, ___) => _buildDummyFoodImage(index),
      );
    }
    return _buildDummyFoodImage(index);
  }

  Widget _buildDummyFoodImage(int index) {
    final icons = [
      Icons.bakery_dining_rounded,
      Icons.rice_bowl_rounded,
      Icons.local_pizza_rounded,
      Icons.icecream_rounded,
      Icons.egg_alt_rounded,
      Icons.breakfast_dining_rounded,
    ];
    final colors = [
      const Color(0xFFE65100),
      const Color(0xFF2E7D32),
      const Color(0xFFD32F2F),
      const Color(0xFF7B1FA2),
      const Color(0xFFF9A825),
      const Color(0xFF795548),
    ];
    return Center(
      child: Icon(
        icons[index % icons.length],
        size: 56,
        color: colors[index % colors.length].withOpacity(0.6),
      ),
    );
  }
}

// Add to cart button (Copied from FeaturedProductsScreen)
class _AddToCartButton extends StatelessWidget {
  final Product product;

  const _AddToCartButton({required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final cartCubit = context.read<CartCubit>();
        int quantity = 0;

        if (state is CartSuccess) {
          final item = state.cart.items.cast<CartItem?>().firstWhere(
            (item) => item?.productVariant.id == product.id,
            orElse: () => null,
          );
          quantity = item?.quantity ?? 0;
        }

        if (quantity > 0) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => cartCubit.removeItem(product.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => cartCubit.addItem(product, 1),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            // Redirect to product details with auto-open subscription
            SubscriptionNavigationHelper.navigateToProductDetails(
              context,
              product,
            );
            // Commented out existing logic:
            // cartCubit.addItem(product, 1);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, size: 18, color: Colors.white),
          ),
        );
      },
    );
  }
}
