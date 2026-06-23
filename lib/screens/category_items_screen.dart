import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String name;
  final List<Product> allProducts;

  const CategoryItemsScreen({
    super.key,
    required this.name,
    required this.allProducts,
  });

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  late List<Product> filteredProducts;
  bool _showShimmer = true;

  @override
  void initState() {
    super.initState();
    filteredProducts = List<Product>.from(widget.allProducts);
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _showShimmer = false);
    });
  }

  void _sortById() {
    setState(() {
      filteredProducts.sort((a, b) => a.id.compareTo(b.id));
    });
  }

  void _sortByPrice() {
    setState(() {
      filteredProducts.sort((a, b) => a.price.compareTo(b.price));
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
          // ── Green banner app bar ──────────────────────────────────────
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.parchment),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${filteredProducts.length} products available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.parchment.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sort_rounded,
                    color: AppColors.parchment,
                    size: 20,
                  ),
                ),
                onSelected: (value) {
                  if (value == 'price') _sortByPrice();
                },
                itemBuilder:
                    (_) => const [
                      PopupMenuItem(
                        value: 'price',
                        child: Text('Sort by Price'),
                      ),
                    ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Content: shimmer or real list ────────────────────────────
          if (_showShimmer)
            _buildShimmerSliver(isDark)
          else if (filteredProducts.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(AppColors.spacingL),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = filteredProducts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppColors.spacingM),
                    child: Opacity(
                      opacity:
                          product.isActive
                              ? (product.isInStock ? 1.0 : 0.5)
                              : 1.0,
                      child: GroceryItemCardWidget(
                        item: product,
                        heroSuffix: "home_screen",
                        onTap:
                            (product.isInStock && product.isActive)
                                ? () => _onProductClicked(product)
                                : null,
                      ),
                    ),
                  );
                }, childCount: filteredProducts.length),
              ),
            )
          else
            SliverFillRemaining(
              child: Center(
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
                        'No products found',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppColors.spacingS),
                      Text(
                        'Check back later for new items',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          final itemCount = cartState.cart?.items.length ?? 0;
          return FloatingActionButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.goNamed(AppRoute.home.name);
              context.goNamed(AppRoute.cart.name);
            },
            backgroundColor: theme.colorScheme.primary,
            child: Badge(
              isLabelVisible: itemCount > 0,
              label: Text(
                itemCount.toString(),
                style: const TextStyle(
                  color: AppColors.parchment,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Icon(
                Icons.shopping_cart_rounded,
                color: AppColors.parchment,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerSliver(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppColors.spacingL),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: AppColors.spacingM),
            child: ShimmerLoading(
              isLoading: true,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.parchment,
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

  void _onProductClicked(Product item) {
    context.pushNamed(
      AppRoute.productDetails.name,
      pathParameters: {'id': item.id.toString()},
    );
  }
}
