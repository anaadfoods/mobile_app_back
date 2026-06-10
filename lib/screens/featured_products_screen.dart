import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';

class FeaturedProductsScreen extends StatefulWidget {
  final List<Product> products;

  const FeaturedProductsScreen({super.key, required this.products});

  @override
  State<FeaturedProductsScreen> createState() => _FeaturedProductsScreenState();
}

class _FeaturedProductsScreenState extends State<FeaturedProductsScreen> {
  late List<Product> _products;
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
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.deepSoilGreen,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.deepSoilGreen,
                        AppColors.deepSoilGreen.withValues(alpha: 0.8),
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
                            'Featured Products',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.parchment,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_products.length} products available',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.parchment.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(4),
              child: const AnaadLogoMark(),
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
                        color:
                            isDark ? AppColors.charcoal87 : AppColors.parchment,
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
                          color:
                              isDark
                                  ? AppColors.charcoal60
                                  : AppColors.parchment,
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
                    ? AppColors.deepSoilGreen
                    : (isDark ? AppColors.charcoal87 : AppColors.parchment),
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
          (context, index) {
            final product = _products[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: product.isActive ? (product.isInStock ? 1.0 : 0.5) : 1.0,
                child: GroceryItemCardWidget(
                  item: product,
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

// Grid card for products
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
      onTap: (product.isInStock && product.isActive) ? onTap : null,
      child: Opacity(
        opacity: (product.isInStock && product.isActive) ? 1.0 : 0.5,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? AppColors.charcoal26
                            : AppColors.charcoal.withValues(alpha: 0.06),
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
                                : _getDummyGradient(index),
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
                                color: AppColors.harvestAmber,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.harvestAmber.withValues(alpha: 0.3),
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
                                      ? AppColors.charcoal54
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
              ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getDummyGradient(int index) {
    final gradients = [
      [AppColors.parchment, AppColors.parchment], // Orange light
      [AppColors.parchment, AppColors.parchment], // Green light
      [AppColors.parchment, AppColors.parchment], // Pink light
      [AppColors.parchment, AppColors.parchment], // Blue light
      [AppColors.parchment, AppColors.parchment], // Purple light
      [AppColors.parchment, AppColors.parchment], // Yellow light
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
      AppColors.parchment,
      AppColors.parchment,
      AppColors.parchment,
      AppColors.parchment,
      AppColors.parchment,
      AppColors.parchment,
    ];
    return Center(
      child: Icon(
        icons[index % icons.length],
        size: 56,
        color: colors[index % colors.length].withValues(alpha: 0.6),
      ),
    );
  }
}

// Add to cart button
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
            final authState = context.read<AuthCubit>().state;
            if (authState is Unauthenticated) {
              GuestAuthHelper.showGuestLoginBottomSheet(
                context,
                title: 'Login Required',
                subtitle: 'Please log in to add items to your cart.',
              );
              return;
            }
            HapticFeedback.lightImpact();
            cartCubit.addItem(product, 1);
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
