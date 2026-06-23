import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/out_of_stock_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/utils/subscription_navigation_helper.dart';
import 'package:grocery_app/routes/app_routes.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key, this.products});
  final List<Product>? products;

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
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
                  color: theme.disabledColor.withValues(alpha: 0.5),
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
            backgroundColor:
                isDark ? AppColors.charcoal : AppColors.deepSoilGreen,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Product Categories',
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
                    _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
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
                (isDark ? AppColors.darkSurfaceElevated : AppColors.parchment),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.deepSoilGreen : AppColors.transparent,
            ),
            boxShadow:
                isSelected
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
                color:
                    isSelected
                        ? AppColors.parchment
                        : (isDark
                            ? AppColors.parchment70
                            : AppColors.charcoal54),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected
                          ? AppColors.parchment
                          : (isDark
                              ? AppColors.parchment70
                              : AppColors.charcoal87),
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
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
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
            child: Opacity(
              opacity: _products[index].isActive ? (_products[index].isInStock ? 1.0 : 0.5) : 1.0,
              child: GroceryItemCardWidget(
                item: _products[index],
                heroSuffix: 'all_products_list_$index',
                onTap: () => _onProductTap(_products[index]),
              ),
            ),
          ),
          childCount: _products.length,
        ),
      ),
    );
  }

  void _onProductTap(Product product) {
    if (!product.isInStock || !product.isActive) return;
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

  Widget _buildCategoryCapsule(String category, ThemeData theme, bool isDark) {
    if (category.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.parchment.withValues(alpha: 0.1)
            : AppColors.harvestAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.parchment.withValues(alpha: 0.15)
              : AppColors.harvestAmber.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? AppColors.pureWhite.withValues(alpha: 0.9) : AppColors.harvestAmber,
          fontWeight: FontWeight.bold,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantityTag(String weight, String unit, ThemeData theme, bool isDark) {
    if (weight.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.charcoal.withValues(alpha: 0.3)
            : AppColors.parchment,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? AppColors.parchment.withValues(alpha: 0.1)
              : theme.dividerColor.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        '$weight $unit',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDiscount = product.discountPercentage > 0;

    return GestureDetector(
      onTap: (product.isInStock && product.isActive) ? onTap : null,
      child: Opacity(
        opacity: product.isActive ? (product.isInStock ? 1.0 : 0.5) : 1.0,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.parchment,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? AppColors.charcoal26
                            : AppColors.charcoal.withValues(alpha: 0.08),
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
                            gradient: isDark
                                ? LinearGradient(
                                  colors: [
                                    AppColors.darkCanvas,
                                    AppColors.darkCanvas,
                                  ],
                                )
                                : LinearGradient(
                                  colors: [
                                    AppColors.parchment,
                                    AppColors.parchment,
                                  ],
                                ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child:
                                product.productImages.isNotEmpty
                                    ? CachedNetworkImage(
                                      imageUrl: product.productImages[0].image,
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
                                            Icons.image_not_supported_rounded,
                                            color: theme.disabledColor,
                                          ),
                                    )
                                    : Icon(
                                      Icons.image_not_supported_rounded,
                                      color: theme.disabledColor,
                                    ),
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
                                color: AppColors.harvestAmber,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.harvestAmber.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${product.discountPercentage.toInt()}% OFF',
                                style: const TextStyle(
                                  color: AppColors.pureWhite,
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
                              color: AppColors.parchment.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_border,
                              size: 18,
                              color:
                                  isDark
                                      ? AppColors.parchment54
                                      : AppColors.charcoal45,
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
                        _buildCategoryCapsule(product.productCategory, theme, isDark),
                        const SizedBox(height: 4),
                        Text(
                          product.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildQuantityTag(product.weight, product.weightUnit, theme, isDark),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '₹${product.finalPrice.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getPriceColor(context),
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
            if (!product.isActive)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: isDark ? Colors.black.withValues(alpha: 0.72) : Colors.white.withValues(alpha: 0.72),
                    child: const ComingSoonOverlay(),
                  ),
                ),
              )
            else if (!product.isInStock)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: isDark ? Colors.black.withValues(alpha: 0.72) : Colors.white.withValues(alpha: 0.72),
                    child: const OutOfStockOverlay(),
                  ),
                ),
              ),
          ],
        ),
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
              color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is Unauthenticated) {
                      GuestAuthHelper.showGuestLoginBottomSheet(
                        context,
                        title: 'Login Required',
                        subtitle: 'Please log in to manage your cart.',
                      );
                      return;
                    }
                    cartCubit.removeItem(product.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: AppColors.deepSoilGreen,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$quantity',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepSoilGreen,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is Unauthenticated) {
                      GuestAuthHelper.showGuestLoginBottomSheet(
                        context,
                        title: 'Login Required',
                        subtitle: 'Please log in to manage your cart.',
                      );
                      return;
                    }
                    cartCubit.addItem(product, 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.deepSoilGreen,
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
              color: AppColors.deepSoilGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, size: 18, color: AppColors.parchment),
          ),
        );
      },
    );
  }
}
