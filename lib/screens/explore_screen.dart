import 'package:grocery_app/common_widgets/global_import.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // --- CACHING (Categories only) ---
  static List<Category>? _cachedCategories;

  // --- LOCAL STATE ---
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  List<Product> _bestsellers = [];
  bool _isLoading = true;
  bool _isLoadingBestsellers = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_cachedCategories != null) {
      if (mounted) {
        setState(() {
          _categories = _cachedCategories!;
          _filteredCategories = _categories;
          _isLoading = false;
        });
      }
    } else {
      await _fetchCategories();
    }
    await _fetchBestsellers();
  }

  Future<void> _fetchCategories() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final categories = await CategoryService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _filteredCategories = categories;
          _cachedCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading categories: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchBestsellers() async {
    if (_isLoadingBestsellers && _bestsellers.isNotEmpty) return;
    if (mounted) {
      setState(() {
        _isLoadingBestsellers = true;
      });
    }
    try {
      final bestsellers = await CategoryService.fetchBestsellerProducts();
      if (mounted) {
        setState(() {
          _bestsellers = bestsellers;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingBestsellers = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    _cachedCategories = null;
    await _loadData();
  }

  void _filterCategories(String query) {
    setState(() {
      _filteredCategories =
          query.isEmpty
              ? _categories
              : _categories
                  .where(
                    (c) => c.name.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text("Category"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child:
              _isLoading
                  ? _buildSkeletonLoader(theme)
                  : _error != null
                  ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  )
                  : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppColors.spacingL,
                          vertical: AppColors.spacingS,
                        ),
                        child: SearchBarWidget(
                          hintText: 'Search Categories',
                          onChanged: _filterCategories,
                        ),
                      ),
                      Expanded(child: _buildBody(theme)),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.spacingL,
              AppColors.spacingL,
              AppColors.spacingL,
              AppColors.spacingS,
            ),
            child: Text(
              'Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_filteredCategories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppColors.spacingL),
                child: Text(
                  'No matching categories found',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            _buildCategoryGrid(theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppColors.spacingL,
              AppColors.spacingXL,
              AppColors.spacingL,
              AppColors.spacingM,
            ),
            child: Text(
              'Trending Products',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isLoadingBestsellers)
            _buildBestsellerListSkeleton(theme)
          else if (_bestsellers.isNotEmpty)
            ListView.builder(
              itemCount: _bestsellers.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = _bestsellers[index];
                return Opacity(
                  opacity: item.isInStock ? 1.0 : 0.5,
                  child: GroceryItemCardWidget(
                    item: item,
                    heroSuffix: "explore_screen",
                    onTap:
                        item.isInStock ? () => _onProductClicked(item) : null,
                  ),
                );
              },
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppColors.spacingL),
                child: Text("No trending products available right now."),
              ),
            ),
          const SizedBox(height: AppColors.spacingL),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spacingL,
        vertical: AppColors.spacingM,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppColors.spacingM,
          mainAxisSpacing: AppColors.spacingM,
          childAspectRatio: 0.9,
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          return GestureDetector(
            onTap:
                category.isActive
                    ? () => _onCategoryItemClicked(context, category)
                    : null,
            child: Opacity(
              opacity: category.isActive ? 1.0 : 0.5,
              child: _buildCachedCategoryCard(category, theme, isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCachedCategoryCard(
    Category category,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityLight),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                ),
                child: CachedNetworkImage(
                  imageUrl: category.image,
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
                        color: theme.disabledColor,
                        size: 32,
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppColors.spacingS,
                  vertical: AppColors.spacingXS,
                ),
                color: theme.cardColor,
                child: Center(
                  child: Text(
                    category.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onProductClicked(Product item) {
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
    );
  }

  void _onCategoryItemClicked(BuildContext context, Category category) async {
    final products = await CategoryService.fetchProductsByCategory(
      category.name,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      AnimatedTransitions.slideFromRight(
        CategoryItemsScreen(name: category.name, allProducts: products),
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface.withOpacity(0.5),
      highlightColor: theme.colorScheme.surface,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonContainer(
              height: 50,
              borderRadius: 8,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            _buildSkeletonContainer(
              width: 150,
              height: 24,
              borderRadius: 8,
              margin: const EdgeInsets.all(16),
            ),
            _buildCategoryGridSkeleton(theme),
            _buildSkeletonContainer(
              width: 200,
              height: 20,
              borderRadius: 8,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            _buildBestsellerListSkeleton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGridSkeleton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _buildSkeletonContainer(borderRadius: 8),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: _buildSkeletonContainer(borderRadius: 8),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBestsellerListSkeleton(ThemeData theme) {
    return ListView.builder(
      itemCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildSkeletonContainer(width: 80, height: 80, borderRadius: 8),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonContainer(height: 20, borderRadius: 4),
                    const SizedBox(height: 8),
                    _buildSkeletonContainer(
                      height: 16,
                      width: 100,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonContainer({
    double? width,
    double? height,
    EdgeInsetsGeometry? margin,
    double borderRadius = 0,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white, // This will be covered by the shimmer
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
