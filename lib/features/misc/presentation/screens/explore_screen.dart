import 'dart:math' as math;
import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/out_of_stock_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  // --- CACHING ---
  static List<Category>? _cachedCategories;

  // --- LOCAL STATE ---
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  List<Product> _bestsellers = [];
  bool _isLoading = true;
  bool _isLoadingBestsellers = true;
  String? _error;
  String _searchQuery = '';

  // --- ANIMATION CONTROLLERS ---
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _pulseController;

  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _headerSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
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
    HapticFeedback.mediumImpact();
    _cachedCategories = null;
    await _loadData();
  }

  void _filterCategories(String query) {
    HapticFeedback.selectionClick();
    setState(() {
      _searchQuery = query;
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Animated Header with Gradient
            _buildAnimatedHeader(theme, isDark),

            // Search Bar
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - _contentFade.value)),
                    child: Opacity(opacity: _contentFade.value, child: child),
                  );
                },
                child: _buildSearchBar(theme, isDark),
              ),
            ),

            // Content
            if (_isLoading)
              SliverToBoxAdapter(child: _buildSkeletonLoader(theme))
            else if (_error != null)
              SliverToBoxAdapter(
                child: ErrorStateWidget(
                  title: "Couldn't load categories right now",
                  subtitle: 'Check your connection and try again 📶',
                  icon: Icons.explore_off_outlined,
                  errorType: ErrorType.network,
                  onRetry: _handleRefresh,
                ),
              )
            else ...[
              // Categories Section
              SliverToBoxAdapter(child: _buildCategoriesSection(theme, isDark)),

              // Trending Products Section
              SliverToBoxAdapter(child: _buildTrendingSection(theme, isDark)),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final screenHeight = mediaQuery.size.height;

    // Dynamic header height based on status bar and content
    final headerHeight = (statusBarHeight + 180).clamp(
      200.0,
      math.max(200.0, screenHeight * 0.30).toDouble(),
    );

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlide.value),
            child: Opacity(opacity: _headerFade.value, child: child),
          );
        },
        child: Container(
          constraints: BoxConstraints(minHeight: headerHeight),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
                isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.6)
                    : AppColors.deepSoilGreen,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Explore icon with light white background
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.parchment.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.parchment,
                    size: 28,
                  ),
                ),
              ),
              // Header Content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row with Back Button and Refresh
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (Navigator.canPop(context))
                            GlassmorphicIconButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                            )
                          else
                            const SizedBox.shrink(),
                          // GlassmorphicIconButton(
                          //   icon: Icons.refresh_rounded,
                          //   onTap: _handleRefresh,
                          // ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Row(
                        children: [
                          // Icon(
                          //   Icons.grid_view_rounded,
                          //   color: AppColors.parchment,
                          //   size: 32,
                          // ),
                          Expanded(
                            child: Text(
                              "Farm Offerings",
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppColors.parchment,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Explore what your farmers are growing for you.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.parchment.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stats Row - scrollable to prevent overflow
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatChip(
                              Icons.category_rounded,
                              '${_categories.length}',
                              'Categories',
                            ),
                            const SizedBox(width: 16),
                            _buildStatChip(
                              Icons.local_fire_department_rounded,
                              '${_bestsellers.length}',
                              'Trending',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildFloatingParticle and _buildIconButton replaced by FloatingParticle and GlassmorphicIconButton widgets

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.parchment, size: 16),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(
              color: AppColors.parchment,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: _filterCategories,
          decoration: InputDecoration(
            hintText: 'Search categories...',
            filled: false,
            hintStyle: TextStyle(
              color:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.5)
                      : theme.hintColor.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary,
            ),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      onPressed: () {
                        _filterCategories('');
                      },
                      icon: Icon(Icons.close_rounded, color: theme.hintColor),
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Shop by Category',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_filteredCategories.isEmpty)
          EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: 'No matching categories found',
            animated: false,
          )
        else
          _buildCategoryGrid(theme, isDark),
      ],
    );
  }

  Widget _buildCategoryGrid(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          return _AnimatedCategoryCard(
            category: category,
            index: index,
            onTap: () => _onCategoryItemClicked(context, category),
            contentAnimation: _contentController,
          );
        },
      ),
    );
  }

  Widget _buildTrendingSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.harvestAmber, AppColors.rawEarth],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Trending Products',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.2),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.harvestAmber,
                      size: 24,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingBestsellers)
          _buildBestsellerListSkeleton(theme)
        else if (_bestsellers.isEmpty)
          EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: 'No trending products available',
            animated: false,
          )
        else
          ListView.builder(
            itemCount: _bestsellers.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = _bestsellers[index];
              return _AnimatedProductCard(
                product: item,
                index: index,
                onTap: () => _onProductClicked(item),
                contentAnimation: _contentController,
              );
            },
          ),
      ],
    );
  }

  // _buildEmptyState and _buildErrorState replaced by EmptyStateWidget and ErrorStateWidget

  void _onProductClicked(Product item) {
    HapticFeedback.lightImpact();
    context.pushNamed(
      AppRoute.productDetails.name,
      pathParameters: {'id': item.id.toString()},
    );
  }

  void _onCategoryItemClicked(BuildContext context, Category category) async {
    if (!category.isActive) return;
    HapticFeedback.lightImpact();

    final products = await CategoryService.fetchProductsByCategory(
      category.name,
    );
    if (!mounted) return;

    context.push(
      '/category-items',
      extra: {'name': category.name, 'products': products},
    );
  }

  Widget _buildSkeletonLoader(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface.withValues(alpha: 0.5),
      highlightColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonContainer(width: 150, height: 24, borderRadius: 8),
            const SizedBox(height: 16),
            _buildCategoryGridSkeleton(theme),
            const SizedBox(height: 24),
            _buildSkeletonContainer(width: 200, height: 24, borderRadius: 8),
            const SizedBox(height: 16),
            _buildBestsellerListSkeleton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGridSkeleton(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Widget _buildBestsellerListSkeleton(ThemeData theme) {
    return ListView.builder(
      itemCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _buildSkeletonContainer(width: 80, height: 80, borderRadius: 12),
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
    double borderRadius = 0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Animated Category Card Widget
class _AnimatedCategoryCard extends StatefulWidget {
  final Category category;
  final int index;
  final VoidCallback onTap;
  final AnimationController contentAnimation;

  const _AnimatedCategoryCard({
    required this.category,
    required this.index,
    required this.onTap,
    required this.contentAnimation,
  });

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 8, end: 2).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = widget.category.isActive;

    // Staggered animation delay based on index
    final delay = widget.index * 100;

    return AnimatedBuilder(
      animation: widget.contentAnimation,
      builder: (context, child) {
        final progress = Curves.easeOutBack.transform(
          ((widget.contentAnimation.value * 1000) - delay).clamp(0, 400) / 400,
        );
        return Transform.translate(
          offset: Offset(0, 30 * (1 - progress)),
          child: Transform.scale(
            scale: 0.8 + (0.2 * progress),
            child: Opacity(opacity: progress.clamp(0, 1), child: child),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: GestureDetector(
          onTapDown:
              isActive
                  ? (_) {
                    setState(() => _isPressed = true);
                    _hoverController.forward();
                  }
                  : null,
          onTapUp:
              isActive
                  ? (_) {
                    setState(() => _isPressed = false);
                    _hoverController.reverse();
                  }
                  : null,
          onTapCancel:
              isActive
                  ? () {
                    setState(() => _isPressed = false);
                    _hoverController.reverse();
                  }
                  : null,
          onTap: isActive ? widget.onTap : null,
          child: AnimatedBuilder(
            animation: _elevationAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(
                        alpha: _isPressed ? 0.15 : 0.1,
                      ),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Opacity(
                opacity: isActive ? 1.0 : 0.5,
                child: Stack(
                  children: [
                    // Image
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: widget.category.image,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color:
                                  isDark
                                      ? AppColors.darkSurface
                                      : AppColors.parchment,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color:
                                  isDark
                                      ? AppColors.darkSurface
                                      : AppColors.parchment,
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: theme.disabledColor,
                                size: 40,
                              ),
                            ),
                      ),
                    ),

                    // Gradient Overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.transparent,
                              AppColors.charcoal.withValues(alpha: 0.3),
                              AppColors.charcoal.withValues(alpha: 0.7),
                            ],
                            stops: const [0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.parchment,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: AppColors.charcoal.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.category.productsCount > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.category.productsCount} items',
                                style: const TextStyle(
                                  color: AppColors.parchment,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Inactive Badge
                    if (!isActive)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.charcoal60,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: AppColors.parchment,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Animated Product Card Widget
class _AnimatedProductCard extends StatefulWidget {
  final Product product;
  final int index;
  final VoidCallback onTap;
  final AnimationController contentAnimation;

  const _AnimatedProductCard({
    required this.product,
    required this.index,
    required this.onTap,
    required this.contentAnimation,
  });

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard> {
  bool _isPressed = false;

  Widget _buildCategoryCapsule(String category, ThemeData theme, bool isDark) {
    if (category.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.parchment.withValues(alpha: 0.1)
                : AppColors.harvestAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark
                  ? AppColors.parchment.withValues(alpha: 0.15)
                  : AppColors.harvestAmber.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color:
              isDark
                  ? AppColors.pureWhite.withValues(alpha: 0.9)
                  : AppColors.harvestAmber,
          fontWeight: FontWeight.bold,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantityTag(
    String weight,
    String unit,
    ThemeData theme,
    bool isDark,
  ) {
    if (weight.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.charcoal.withValues(alpha: 0.3)
                : AppColors.parchment,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isDark
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
    final isInStock = widget.product.isInStock;
    final isActive = widget.product.isActive;
    final hasDiscount = widget.product.discountPercentage > 0;

    // Staggered animation delay based on index
    final delay = 300 + (widget.index * 80);

    return AnimatedBuilder(
      animation: widget.contentAnimation,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(
          ((widget.contentAnimation.value * 1000) - delay).clamp(0, 300) / 300,
        );
        return Transform.translate(
          offset: Offset(30 * (1 - progress), 0),
          child: Opacity(opacity: progress.clamp(0, 1), child: child),
        );
      },
      child: GestureDetector(
        onTapDown:
            (isInStock && isActive)
                ? (_) => setState(() => _isPressed = true)
                : null,
        onTapUp:
            (isInStock && isActive)
                ? (_) => setState(() => _isPressed = false)
                : null,
        onTapCancel:
            (isInStock && isActive)
                ? () => setState(() => _isPressed = false)
                : null,
        onTap: (isInStock && isActive) ? widget.onTap : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        _isPressed
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.parchment,
                    width: _isPressed ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(
                        alpha: _isPressed ? 0.15 : 0.08,
                      ),
                      blurRadius: _isPressed ? 16 : 8,
                      offset: Offset(0, _isPressed ? 8 : 4),
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: isActive ? (isInStock ? 1.0 : 0.5) : 1.0,
                  child: Row(
                    children: [
                      // Product Image Stack
                      Stack(
                        children: [
                          Hero(
                            tag: 'product_${widget.product.id}_explore',
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color:
                                    isDark
                                        ? AppColors.darkSurface
                                        : AppColors.parchment,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    widget.product.productImages.isNotEmpty
                                        ? CachedNetworkImage(
                                          imageUrl:
                                              widget
                                                  .product
                                                  .productImages[0]
                                                  .image,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          theme
                                                              .colorScheme
                                                              .primary,
                                                    ),
                                              ),
                                          errorWidget:
                                              (context, url, error) => Icon(
                                                Icons
                                                    .image_not_supported_rounded,
                                                color: theme.disabledColor,
                                              ),
                                        )
                                        : Icon(
                                          Icons.image_not_supported_rounded,
                                          color: theme.disabledColor,
                                        ),
                              ),
                            ),
                          ),
                          if (hasDiscount)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.harvestAmber,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.harvestAmber.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${widget.product.discountPercentage.toInt()}% off',
                                  style: const TextStyle(
                                    color: AppColors.pureWhite,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
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
                            _buildCategoryCapsule(
                              widget.product.productCategory,
                              theme,
                              isDark,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.product.productName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _buildQuantityTag(
                              widget.product.weight,
                              widget.product.weightUnit,
                              theme,
                              isDark,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '₹${widget.product.finalPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: AppColors.getPriceColor(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (!isInStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.rawEarth,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Out of Stock',
                                      style: TextStyle(
                                        color: AppColors.parchment,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Arrow Icon
                      if (isInStock) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!isActive)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color:
                            isDark
                                ? Colors.black.withValues(alpha: 0.72)
                                : Colors.white.withValues(alpha: 0.72),
                        child: const ComingSoonOverlay(),
                      ),
                    ),
                  ),
                )
              else if (!isInStock)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color:
                            isDark
                                ? Colors.black.withValues(alpha: 0.72)
                                : Colors.white.withValues(alpha: 0.72),
                        child: const OutOfStockOverlay(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
