import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

import 'package:go_router/go_router.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:share_plus/share_plus.dart';

// --- CUBIT & STATE IMPORTS (Ensure paths are correct) ---

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final bool autoOpenSubscription;
  final int? initialPlanId;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.autoOpenSubscription = false,
    this.initialPlanId,
  });

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  // --- ANIMATION CONTROLLERS ---

  // --- NON-CART STATE VARIABLES (Remain unchanged) ---
  int? _selectedPlanId;
  bool isFavorite = false;
  bool _isTogglingFavorite = false;
  bool _isLoadingFavorite = true;
  bool _isLoadingPlans = true;
  bool _isLoadingSimilarProduct = true;
  List<SubscriptionPlan> allPlans = [];
  List<PlanSearchResult> availablePlansForProduct = [];
  List<Product> similarProducts = [];
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  // --- REMOVED CART-RELATED STATE ---
  // The CartCubit now manages all cart state.

  // --- SERVICES (CartService is no longer needed here) ---
  final FavoriteStateService _favoriteStateService = FavoriteStateService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AuthService _authService = AuthService();

  // --- DEBOUNCE STATE ---
  Timer? _cartDebounceTimer;
  bool _isCartOperationPending = false;
  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Fire off background data fetches
    _loadFavoriteStatus();
    _loadSubscriptionPlans();
    _loadCategoryProducts();
    // REMOVED: _loadCartStatus(); is no longer needed. The BlocBuilder will handle it.

    _pageController.addListener(() {
      if (mounted && _pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  void _initAnimations() {
    // Shimmer animation removed — no longer needed
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _cartDebounceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- DATA FETCHING (Unchanged) ---
  Future<void> _loadCategoryProducts() async {
    try {
      final products = await CategoryService.fetchProductsByCategory(
        widget.product.productCategory,
      );
      if (mounted) {
        setState(() {
          similarProducts = products;
          _isLoadingSimilarProduct = false;
        });
      }
    } catch (e) {
      log('Error fetching category products: $e');
      if (mounted) setState(() => _isLoadingSimilarProduct = false);
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favResult = await _authService.getFavorites();
      if (mounted && favResult['success']) {
        final favorites = favResult['data'] as List<FavoriteModel>;

        setState(() {
          isFavorite = favorites.any(
            (fav) => fav.productId == widget.product.id,
          );
        });
      }
    } catch (e) {
      log('Error fetching favorite status: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  Future<void> _loadSubscriptionPlans() async {
    try {
      final results = await Future.wait([
        PlanSearchService.fetchPlansForVariant(widget.product.id),
        _subscriptionService.getSubscriptionPlans(),
      ]);

      if (!mounted) return;

      final productPlans = results[0] as List<PlanSearchResult>;
      final allPlansResult = results[1] as Map<String, dynamic>;

      setState(() {
        availablePlansForProduct = productPlans;
        if (allPlansResult['success']) {
          allPlans = allPlansResult['data'] as List<SubscriptionPlan>;
        }
      });
    } catch (e) {
      log('Error fetching subscription plans: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlans = false);
        // Auto-open subscription sheet if requested (e.g. from category page "Add to Cart")
        if (widget.autoOpenSubscription &&
            availablePlansForProduct.isNotEmpty &&
            allPlans.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            // Determine initial plan index
            int initialIndex = -1;

            if (widget.initialPlanId != null) {
              final foundIndex = allPlans.indexWhere(
                (p) => p.id == widget.initialPlanId,
              );
              if (foundIndex != -1) {
                initialIndex = foundIndex;
              }
            }

            // If still -1, find the max duration among AVAILABLE plans
            if (initialIndex == -1) {
              int maxDur = -1;
              for (int i = 0; i < allPlans.length; i++) {
                final isAvailable = availablePlansForProduct.any(
                  (p) => p.planName == allPlans[i].name,
                );
                if (isAvailable && allPlans[i].durationMonths > maxDur) {
                  maxDur = allPlans[i].durationMonths;
                  initialIndex = i;
                }
              }
            }

            _showSubscriptionSelectionSheet(
              initialPlanIndex: initialIndex,
              initialPlanId: initialIndex != -1 ? allPlans[initialIndex].id : -1,
            );
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundImage =
        widget.product.productImages.isNotEmpty
            ? widget.product.productImages.first.image
            : 'https://via.placeholder.com/400';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.parchment,
      body: Stack(
        children: [
          // Blurred Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      // Ensure high contrast overlay for readability
                      isDark
                          ? AppColors.darkCanvas.withValues(alpha: 0.7)
                          : AppColors.parchment.withValues(alpha: 0.85),
                      isDark
                          ? AppColors.darkCanvas.withValues(alpha: 0.85)
                          : AppColors.parchment.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopNavBar(theme, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Header Group (Name, Reviews, Price)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              _buildProductTitle(theme),
                              const SizedBox(height: 16),
                              _buildPriceBox(theme),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),

                        // Landscape Image
                        _buildImageCarousel(),
                        const SizedBox(height: 16),
                        if (widget.product.productImages.length > 1) ...[
                          _buildCarouselIndicators(),
                          const SizedBox(height: 24),
                        ],

                        // Subscription Plans
                        if (_isLoadingPlans ||
                            (availablePlansForProduct.isNotEmpty &&
                                allPlans.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildSubscriptionPlansSection(isDark),
                          ),

                        const SizedBox(height: 24),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.parchment
                                          : AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ExpandableDescription(
                                text: widget.product.productDescription,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Similar Products
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildSimilarProductsSection(isDark),
                        ),

                        const SizedBox(height: 100), // Spacing for bottom bar
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // --- UI BUILDER WIDGETS ---

  Widget _buildTopNavBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ANAAD Logo
          AnaadLogoMark(onTap: () => context.pop()),

          // Actions
          Row(
            children: [
              // Share
              GestureDetector(
                onTap: () {
                  _triggerHaptic();
                  Share.share(
                    'Check out this product: https://anaadfoods.com/product/${widget.product.id}',
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.parchment,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    color: isDark ? AppColors.parchment : AppColors.pureBlack,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Favorite
              _isLoadingFavorite
                  ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                  : GestureDetector(
                    onTap: () {
                      _triggerHaptic();
                      handleFavoriteToggle(widget.product.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            isFavorite
                                ? AppColors.softRed.withValues(alpha: 0.1)
                                : (isDark
                                    ? AppColors.darkSurfaceElevated
                                    : AppColors.pureWhite),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isFavorite
                                  ? AppColors.softRed.withValues(alpha: 0.3)
                                  : AppColors.darkSurface.withValues(
                                    alpha: 0.08,
                                  ),
                        ),
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                            isFavorite
                                ? AppColors.softRed
                                : (isDark
                                    ? AppColors.parchment
                                    : AppColors.pureBlack),
                        size: 20,
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  void handleFavoriteToggle(int productId) async {
    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);

    final result = await _authService.toggleFavorite(productId);

    if (!mounted) return;

    if (result['success']) {
      setState(() => isFavorite = !isFavorite);

      _favoriteStateService.notifyFavoriteChanged();

      SnackBarHelper.showSuccess(context, result['message']);
    } else if (result['requiresLogin'] == true) {
      context.push(AppRoute.login.path);
    } else {
      SnackBarHelper.showError(
        context,

        result['message'] ?? 'Failed to update favorite',
      );
    }

    // Add a small cooldown delay before allowing next toggle
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isTogglingFavorite = false);
    }
  }

  // ... (All other _build... widgets from _buildBestsellerTag to _buildProductCard remain the same)

  Widget _buildProductTitle(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      '${widget.product.productName} - ${widget.product.weight}',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.parchment : AppColors.charcoal,
        height: 1.2,
      ),
    );
  }

  Widget _buildPriceBox(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    double discount =
        ((widget.product.price - widget.product.finalPrice) /
            widget.product.price) *
        100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${widget.product.finalPrice.toStringAsFixed(0)}',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.harvestAmber,
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '₹${widget.product.price.toStringAsFixed(0)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: TextDecoration.lineThrough,
              color:
                  isDark
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
    );
  }

  Widget _buildImageCarousel() {
    final productImages = widget.product.productImages;
    if (productImages.isEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.rawEarth54.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, color: AppColors.rawEarth26, size: 48),
              const SizedBox(height: 8),
              Text(
                'No Images Available',
                style: TextStyle(color: AppColors.rawEarth26, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        itemCount: productImages.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // Simple shadow for depth
              boxShadow: [
                BoxShadow(
                  color: AppColors.charcoal.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: productImages[index].image,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.rawEarth12!,
                      highlightColor: AppColors.parchment!,
                      child: Container(color: AppColors.rawEarth12),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: AppColors.parchment,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.rawEarth54,
                        size: 40,
                      ),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarouselIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.product.productImages.length, (index) {
        final isActive = _currentPage == index;
        return GestureDetector(
          onTap: () {
            _triggerHaptic();
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: 8.0,
            width: isActive ? 28.0 : 8.0,
            decoration: BoxDecoration(
              gradient:
                  isActive
                      ? const LinearGradient(
                        colors: [
                          AppColors.deepSoilGreen,
                          AppColors.deepSoilGreen,
                        ],
                      )
                      : null,
              color: isActive ? null : AppColors.rawEarth70,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubscriptionPlansSection(bool isDark) {
    if (_isLoadingPlans) {
      return _buildPlansSkeleton();
    }
    if (availablePlansForProduct.isEmpty || allPlans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Subscription Plans",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.parchment : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // We still build from allPlans to show disabled states correctly
              children: List.generate(allPlans.length > 4 ? 4 : allPlans.length, (
                index,
              ) {
                final plan = allPlans[index];

                // Find the corresponding available plan to get its data (including planId)
                final availablePlanData = availablePlansForProduct.firstWhere(
                  (p) => p.planName == plan.name,
                  orElse:
                      () => PlanSearchResult(
                        planId: 0,
                        planName: '',
                        discountPercentage: 0.0,
                        discountedPrice: 0.0,
                      ),
                );

                final bool isEnabled = availablePlanData.planId != 0;
                // ✅ KEY CHANGE: Check if the current plan's ID matches the selected ID in state
                final bool isSelected =
                    _selectedPlanId == availablePlanData.planId;

                return GestureDetector(
                  onTap:
                      isEnabled
                          ? () {
                            // ✅ KEY CHANGE: Update state with the planId, not the index
                            setState(
                              () => _selectedPlanId = availablePlanData.planId,
                            );
                            // Pass the actual planId to the bottom sheet
                            _showSubscriptionSelectionSheet(
                              initialPlanId: availablePlanData.planId,
                              initialPlanIndex: index,
                            );
                          }
                          : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.deepSoilGreen,
                                  AppColors.successGreen,
                                ],
                              )
                              : null,
                      color:
                          isSelected
                              ? null
                              : (isDark
                                  ? AppColors.darkMintGreen
                                  : AppColors.pureWhite),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.deepSoilGreen
                                : (isDark
                                    ? AppColors.parchment.withValues(alpha: 0.1)
                                    : AppColors.charcoal12),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: AppColors.deepSoilGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : null,
                    ),
                    child: Opacity(
                      opacity: isEnabled ? 1.0 : 0.4,
                      child: Column(
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isSelected
                                      ? AppColors.pureWhite
                                      : (isDark
                                          ? AppColors.pureWhite
                                          : AppColors.pureBlack),
                              fontWeight:
                                  (isDark && !isSelected)
                                      ? FontWeight.w900
                                      : FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                "₹${availablePlanData.discountedPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      isSelected
                                          ? AppColors.pureWhite
                                          : AppColors.harvestAmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.pureWhite.withValues(
                                            alpha: 0.2,
                                          )
                                          : AppColors.harvestAmber.withValues(
                                            alpha: 0.12,
                                          ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Save ${availablePlanData.discountPercentage.toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        isSelected
                                            ? AppColors.pureWhite
                                            : AppColors.harvestAmber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductsSection(bool isDark) {
    if (_isLoadingSimilarProduct) {
      return _buildSimilarProductsSkeleton();
    }

    if (similarProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Defensive: current product id to exclude
    final int? currentId = widget.product?.id;

    // Filter by product.id only
    final filtered =
        (currentId == null)
            ? List<Product>.from(
              similarProducts,
            ) // nothing to exclude if current id unknown
            : similarProducts.where((p) => p.id != currentId).toList();

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
                      name: widget.product.productCategory,
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
                      color:
                          isDark ? AppColors.parchment : AppColors.pureBlack,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color:
                        isDark ? AppColors.parchment : AppColors.pureBlack,
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
            final product = filtered[index];
            return Opacity(
              opacity: product.isInStock ? 1.0 : 0.5,
              child: GroceryItemCardWidget(
                item: product,
                heroSuffix:
                    "similar_products", // Updated suffix for better hero handling
                onTap:
                    product.isInStock
                        ? () => _onProductClicked(context, product)
                        : null,
              ),
            );
          },
        ),
      ],
    );
  }

  void _onProductClicked(BuildContext context, Product item) {
    context.pushNamed(
      AppRoute.productDetails.name,
      pathParameters: {'id': item.id.toString()},
      extra: item,
    );
  }

  // --- NEW: Skeleton widget for the plans section ---
  Widget _buildPlansSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.rawEarth12!,
      highlightColor: AppColors.parchment!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.rawEarth12,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.rawEarth12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarProductsSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.rawEarth12!,
      highlightColor: AppColors.parchment!,
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

  Widget _buildBottomActionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        bottomPadding > 0 ? bottomPadding : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 55, // Fixed height for smooth animation
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            int cartQuantity = 0;
            if (state is CartSuccess) {
              final cartItem = state.cart.items.firstWhereOrNull(
                (item) => item.productVariant.id == widget.product.id,
              );
              cartQuantity = cartItem?.quantity ?? 0;
            }

            // Show a loader if the cart is initially loading or being cleared.
            if (state is CartLoading || state is CartInitial) {
              return Center(
                child: ShimmerLoading(
                  isLoading: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.darkCanvas
                                    : AppColors.rawEarth54.withValues(
                                      alpha: 0.2,
                                    ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.darkCanvas
                                    : AppColors.rawEarth54.withValues(
                                      alpha: 0.2,
                                    ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                );
              },
              child:
                  cartQuantity == 0
                      ? _buildAddToCartBar(key: const ValueKey('addToCartBar'))
                      : _buildQuantitySelectorBar(
                        key: const ValueKey('quantitySelectorBar'),
                        quantity: cartQuantity,
                      ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddToCartBar({required Key key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      key: key,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleQuantityChanged(1),
            icon: const Icon(Icons.shopping_cart_outlined, size: 20),
            label: const Text(
              "Add to Cart",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor:
                  isDark ? AppColors.harvestAmber : AppColors.harvestAmber,
              side: BorderSide(
                color:
                    isDark ? AppColors.harvestAmber : AppColors.harvestAmber,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Open the subscription sheet
              // Check if there are actually available plans for THIS product
              bool hasSubscriptions = availablePlansForProduct.isNotEmpty;

              if (hasSubscriptions && allPlans.isNotEmpty) {
                // Find the plan with the maximum duration that is AVAILABLE for this product
                int maxDurationIndex = -1;
                int maxDuration = -1;

                for (int i = 0; i < allPlans.length; i++) {
                  final isAvailable = availablePlansForProduct.any(
                    (p) => p.planName == allPlans[i].name,
                  );
                  if (isAvailable && allPlans[i].durationMonths > maxDuration) {
                    maxDuration = allPlans[i].durationMonths;
                    maxDurationIndex = i;
                  }
                }

                if (maxDurationIndex != -1) {
                  _showSubscriptionSelectionSheet(
                    initialPlanIndex: maxDurationIndex,
                    initialPlanId: allPlans[maxDurationIndex].id,
                  );
                } else {
                  _showSubscriptionSelectionSheet(
                    initialPlanIndex: -1,
                    initialPlanId: -1,
                  );
                }
              } else {
                // Default to One-time purchase if no subscriptions available
                _showSubscriptionSelectionSheet(
                  initialPlanIndex: -1,
                  initialPlanId: -1,
                );
              }
            },
            icon: const Icon(
              Icons.shopping_bag_rounded,
              size: 20,
              color: AppColors.pureWhite,
            ),
            label: const Text(
              "Buy Now",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.pureWhite,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.harvestAmber,
              shadowColor: AppColors.harvestAmber.withValues(alpha: 0.4),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelectorBar({required Key key, required int quantity}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () {
              context.go('/cart');
            },

            icon: const Icon(Icons.shopping_cart_checkout, size: 20),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "View Cart",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              side: BorderSide(
                color:
                    isDark ? AppColors.harvestAmber : AppColors.harvestAmber,
              ),
              foregroundColor:
                  isDark ? AppColors.harvestAmber : AppColors.harvestAmber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Delete Button
        Material(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _handleQuantityChanged(0),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Quantity Selector - no Expanded, uses intrinsic width
        ModernQuantitySelector(
          quantity: quantity,
          onChanged: (newAmount) => _handleQuantityChanged(newAmount),
          minQuantity: 0,
        ),
      ],
    );
  }

  Future<void> _handleQuantityChanged(int newQuantity) async {
    // Cancel any pending debounce timer
    _cartDebounceTimer?.cancel();

    // If an operation is already in progress, debounce future calls
    if (_isCartOperationPending) {
      _cartDebounceTimer = Timer(_debounceDuration, () {
        _executeCartOperation(newQuantity);
      });
      return;
    }

    // Execute immediately for the first tap
    await _executeCartOperation(newQuantity);
  }

  Future<void> _executeCartOperation(int newQuantity) async {
    if (_isCartOperationPending) return;

    // Login check
    final token = await _authService.getAccessToken();
    if (token == null) {
      SnackBarHelper.showWarning(context, 'Please login to modify your cart');
      context.push(AppRoute.login.path);
      return;
    }

    setState(() => _isCartOperationPending = true);

    try {
      final cartCubit = context.read<CartCubit>();
      final currentState = cartCubit.state;
      int currentQuantity = 0;

      if (currentState is CartSuccess) {
        final cartItem = currentState.cart.items.firstWhereOrNull(
          (item) => item.productVariant.id == widget.product.id,
        );
        currentQuantity = cartItem?.quantity ?? 0;
      }

      // Now, call the correct cubit method based on the action
      if (newQuantity > 0 && currentQuantity == 0) {
        // This is an "Add to Cart" action
        cartCubit.addItem(widget.product, newQuantity);
      } else if (newQuantity == 0 && currentQuantity > 0) {
        // This is a "Remove" action
        cartCubit.removeItem(widget.product.id);
      } else {
        // This is a quantity "Update" action
        cartCubit.updateItem(widget.product.id, newQuantity);
      }
    } finally {
      // Reset the pending flag after a short delay to allow the operation to complete
      Future.delayed(_debounceDuration, () {
        if (mounted) {
          setState(() => _isCartOperationPending = false);
        }
      });
    }
  }

  Future<void> _navigateToAddressScreen({
    required bool isSubscription,
    int? selectedPlanIndex,
    int? quantity,
    String? paymentType, // New parameter
  }) async {
    double? price;
    int? selectedPlanId;

    if (isSubscription && selectedPlanIndex != null) {
      final selectedPlanName = allPlans[selectedPlanIndex].name;
      final selectedAvailablePlan = availablePlansForProduct.firstWhere(
        (p) => p.planName == selectedPlanName,
      );
      price = selectedAvailablePlan.discountedPrice;
      selectedPlanId = selectedAvailablePlan.planId;
    }

    print(
      'Navigating to Address Screen with: isSubscription=$isSubscription, selectedPlanId=$selectedPlanId, quantity=$quantity, price=$price, paymentType=$paymentType',
    );

    context.pushNamed(
      AppRoute.address.name,
      extra: {
        'singleProduct': widget.product,
        'quantity': quantity ?? 1,
        'isSubscription': isSubscription,
        'price': price,
        'selectedPlan': selectedPlanId ?? 0,
        'paymentType': paymentType,
      },
    );
  }

  // PASTE THIS ENTIRE BLOCK INTO YOUR _ProductDetailsScreenState CLASS

  Widget _buildPlanFeaturesRow(SubscriptionPlan plan, bool isSelected) {
    Color textColor = isSelected ? AppColors.parchment70 : AppColors.charcoal54;
    Color iconColor = isSelected ? AppColors.parchment : AppColors.parchment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem(
          iconColor,
          textColor,
          "Duration - ${plan.durationMonths} Months",
        ),
        const SizedBox(height: 4),
        _buildFeatureItem(
          iconColor,
          textColor,
          "Savings - ${plan.discountPercentage.toString()}% Off",
        ),
      ],
    );
  }

  Widget _buildPlanFeaturesRow2(SubscriptionPlan plan, bool isSelected) {
    Color textColor = isSelected ? AppColors.parchment70 : AppColors.charcoal54;
    Color iconColor = isSelected ? AppColors.parchment : AppColors.parchment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem(
          iconColor,
          textColor,
          "One-Time Only - ${plan.isOneTimeOnly ? "Yes" : "No"}",
        ),
        const SizedBox(height: 4),
        _buildFeatureItem(
          iconColor,
          textColor,
          "Installment Frequency - ${plan.installmentFrequencyMonths} Months",
        ),
      ],
    );
  }

  Widget _buildFeatureItem(Color iconColor, Color textColor, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: iconColor, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Modern Subscription Selection Sheet

  void _showSubscriptionSelectionSheet({
    required int initialPlanIndex,
    required int initialPlanId,
  }) {
    int selectedIndex = initialPlanIndex;
    int quantity = 1;
    int paymentOption = 0;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return _ModernSubscriptionSheet(
              product: widget.product, // Pass product
              allPlans: allPlans,
              availablePlansForProduct: availablePlansForProduct,
              selectedIndex: selectedIndex,
              quantity: quantity,
              paymentOption: paymentOption,
              onPlanSelected:
                  (index) => setModalState(() => selectedIndex = index),
              onQuantityChanged:
                  (newQty) => setModalState(() => quantity = newQty),
              onPaymentOptionChanged:
                  (opt) => setModalState(() => paymentOption = opt),
              onSubscribe: () {
                Navigator.pop(context);
                if (selectedIndex == -1) {
                  // One-time purchase
                  _navigateToAddressScreen(
                    isSubscription: false,
                    quantity: quantity,
                    paymentType: 'PAID_FULL', // One-time is always full payment
                  );
                } else {
                  // Subscription
                  // COD restriction: Force PAID_FULL payment type for subscriptions since installments are disabled.
                  // final String paymentType =
                  //     (paymentOption == 0) ? 'PAID_FULL' : 'INSTALLMENT';
                  final String paymentType = 'PAID_FULL';
                  _navigateToAddressScreen(
                    isSubscription: true,
                    selectedPlanIndex: selectedIndex,
                    quantity: quantity,
                    paymentType: paymentType,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  // Legacy plan card widgets (kept for compatibility)
  Widget _buildLegacyPlanCard(
    SubscriptionPlan plan,
    PlanSearchResult planData,
    bool isSelected,
    bool isEnabled,
    int paymentOption,
    ValueChanged<int> onPaymentOptionChanged,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.deepSoilGreen : AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.deepSoilGreen : AppColors.rawEarth12,
          width: 1.5,
        ),
      ),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color:
                      isSelected
                          ? AppColors.parchment
                          : AppColors.rawEarth54.withValues(alpha: 0.9),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  plan.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        isSelected ? AppColors.parchment : AppColors.charcoal,
                  ),
                ),
                const Spacer(),
                Text(
                  "₹${planData.discountedPrice.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? AppColors.parchment : AppColors.charcoal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CORRECTED: This widget now uses a callback to update state.
  Widget _buildExpandedPlanDetails(
    SubscriptionPlan plan,
    PlanSearchResult planData,
    int currentPaymentOption,
    ValueChanged<int> onPaymentOptionChanged, // The callback function
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          const Divider(color: AppColors.parchment54),
          const SizedBox(height: 8),
          // ... (The total/monthly price rows are unchanged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: AppColors.parchment70),
                    ),
                    Text(
                      '₹${(planData.discountedPrice * plan.durationMonths).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.parchment,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly',
                      style: TextStyle(color: AppColors.parchment70),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${planData.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.parchment,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Payment Options:',
                style: TextStyle(
                  color: AppColors.parchment,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              _buildPaymentOptionRadio(
                0,
                'One Time',
                currentPaymentOption,
                onPaymentOptionChanged, // Pass the callback down
              ),
              const SizedBox(width: 10),
              // COD restriction: Installments are disabled. Comment out the Installments option.
              // if (plan.allowsInstallments)
              //   _buildPaymentOptionRadio(
              //     1,
              //     'Installments',
              //     currentPaymentOption,
              //     onPaymentOptionChanged, // Pass the callback down
              //   ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ CORRECTED: This widget is now stateless and uses the callback.
  Widget _buildPaymentOptionRadio(
    int index,
    String text,
    int groupValue,
    ValueChanged<int> onChanged,
  ) {
    bool isSelected = index == groupValue;
    return GestureDetector(
      onTap:
          () => onChanged(
            index,
          ), // When tapped, call the function passed by the parent.
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.parchment.withValues(alpha: 0.2)
                  : AppColors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: AppColors.parchment,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(color: AppColors.parchment, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: AppColors.parchment)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.parchment,
            ),
          ),
        ],
      ),
    );
  }
}

// A helper widget for the expandable description text
class ExpandableDescription extends StatefulWidget {
  final String text;
  const ExpandableDescription({super.key, required this.text});

  @override
  _ExpandableDescriptionState createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.text.trim(),
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.parchment.withValues(alpha: 0.8)
                      : AppColors.charcoal87,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
            maxLines: _isExpanded ? null : 3,
            overflow:
                _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(
            _isExpanded ? "less" : "more",
            style: TextStyle(
              color: isDark ? AppColors.harvestAmber : AppColors.rawEarth,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// Modern Subscription Selection Sheet Widget
class _ModernSubscriptionSheet extends StatefulWidget {
  final Product product;
  final List<SubscriptionPlan> allPlans;
  final List<PlanSearchResult> availablePlansForProduct;
  final int selectedIndex;
  final int quantity;
  final int paymentOption;
  final ValueChanged<int> onPlanSelected;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<int> onPaymentOptionChanged;
  final VoidCallback onSubscribe;

  const _ModernSubscriptionSheet({
    required this.product,
    required this.allPlans,
    required this.availablePlansForProduct,
    required this.selectedIndex,
    required this.quantity,
    required this.paymentOption,
    required this.onPlanSelected,
    required this.onQuantityChanged,
    required this.onPaymentOptionChanged,
    required this.onSubscribe,
  });

  @override
  State<_ModernSubscriptionSheet> createState() =>
      _ModernSubscriptionSheetState();
}

class _ModernSubscriptionSheetState extends State<_ModernSubscriptionSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = AppColors.harvestAmber;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                // Animated glow at top
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(
                                alpha: _glowAnimation.value * 0.3,
                              ),
                              accentColor.withValues(
                                alpha: _glowAnimation.value * 0.1,
                              ),
                              AppColors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- FIXED HEADER SECTION ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        children: [
                          // Handle bar with glow
                          Center(
                            child: AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  width: 48,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accentColor.withValues(alpha: 0.3),
                                        accentColor.withValues(alpha: 0.6),
                                        accentColor.withValues(alpha: 0.3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: _glowAnimation.value * 0.5,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Header Title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.deepSoilGreen,
                                      AppColors.successGreen,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.deepSoilGreen.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.sell_rounded,
                                  color: AppColors.pureWhite,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choose Your Order',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'One-time buy or subscribe to save every month.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.hintColor,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // --- SCROLLABLE MIDDLE SECTION ---
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // One-Time Purchase Option
                            _buildOneTimePurchaseCard(
                              context,
                              theme,
                              isDark,
                              widget.selectedIndex == -1,
                            ),
                            const SizedBox(height: 16),

                            // Styled separator
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.transparent,
                                          isDark
                                              ? AppColors.parchment.withValues(
                                                alpha: 0.12,
                                              )
                                              : AppColors.charcoal12,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 13,
                                        color: AppColors.harvestAmber,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'OR SUBSCRIBE & SAVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.harvestAmber,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 13,
                                        color: AppColors.harvestAmber,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          isDark
                                              ? AppColors.parchment.withValues(
                                                alpha: 0.12,
                                              )
                                              : AppColors.charcoal12,
                                          AppColors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Plan Cards
                            ...List.generate(widget.allPlans.length, (index) {
                              final plan = widget.allPlans[index];
                              final planData = widget.availablePlansForProduct
                                  .firstWhere(
                                    (p) => p.planName == plan.name,
                                    orElse:
                                        () => PlanSearchResult(
                                          planId: 0,
                                          planName: '',
                                          discountedPrice: 0,
                                          discountPercentage: 0,
                                        ),
                                  );
                              final isEnabled = planData.discountedPrice > 0;
                              final isSelected = widget.selectedIndex == index;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildModernPlanCard(
                                  context,
                                  theme,
                                  isDark,
                                  plan,
                                  planData,
                                  isSelected,
                                  isEnabled,
                                  index,
                                ),
                              );
                            }),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // --- FIXED FOOTER SECTION ---
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.darkSurface
                                : AppColors.parchment,
                        border: Border(
                          top: BorderSide(
                            color:
                                isDark
                                    ? AppColors.parchment.withValues(
                                      alpha: 0.08,
                                    )
                                    : AppColors.charcoal12,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Quantity Section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppColors.charcoal87
                                        : AppColors.pureWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? AppColors.rawEarth26
                                          : AppColors.charcoal12,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shopping_basket_rounded,
                                    color: accentColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Monthly Quantity',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          'How many do you need per month?',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ModernQuantitySelector(
                                    quantity: widget.quantity,
                                    onChanged: widget.onQuantityChanged,
                                    accentColor: accentColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Subscribe Button
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: ModernBottomSheetButton(
                              label:
                                  widget.selectedIndex == -1
                                      ? 'Buy Now'
                                      : 'Subscribe Now',
                              icon:
                                  widget.selectedIndex == -1
                                      ? Icons.shopping_bag_rounded
                                      : Icons.rocket_launch_rounded,
                              onTap: widget.onSubscribe,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernPlanCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SubscriptionPlan plan,
    PlanSearchResult planData,
    bool isSelected,
    bool isEnabled,
    int index,
  ) {
    final accentColor = AppColors.harvestAmber;

    return GestureDetector(
      onTap:
          isEnabled
              ? () {
                HapticFeedback.selectionClick();
                widget.onPlanSelected(index);
              }
              : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withValues(alpha: 0.85)],
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark
                      ? AppColors.darkMintGreen
                      : AppColors.pureWhite),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? accentColor.withValues(alpha: 0.5)
                    : (isDark ? AppColors.rawEarth26 : AppColors.charcoal12),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected
                              ? AppColors.pureWhite.withValues(alpha: 0.2)
                              : AppColors.transparent,
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.pureWhite
                                : (isDark
                                    ? AppColors.parchment54
                                    : AppColors.charcoal38),
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.pureWhite,
                            )
                            : null,
                  ),
                  const SizedBox(width: 14),

                  // Plan info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isSelected
                                ? AppColors.pureWhite
                                : (isDark ? AppColors.pureWhite : null),
                            fontWeight:
                                (isDark && !isSelected)
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.durationMonths} months • ${planData.discountPercentage.toStringAsFixed(0)}% off',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isSelected
                                    ? AppColors.pureWhite.withValues(alpha: 0.7)
                                    : (isDark
                                        ? AppColors.parchment70
                                        : theme.hintColor),
                            fontWeight:
                                (isDark && !isSelected)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${planData.discountedPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected
                                  ? AppColors.pureWhite
                                  : AppColors.harvestAmber,
                        ),
                      ),
                      Text(
                        '/month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isSelected
                                  ? AppColors.pureWhite.withValues(alpha: 0.6)
                                  : (isDark
                                      ? AppColors.parchment70
                                      : theme.hintColor),
                          fontWeight:
                              (isDark && !isSelected)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Expanded content when selected
              if (isSelected) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceRowWithQuantity(
                        'Total (${plan.durationMonths}mo × ${widget.quantity})',
                        planData.discountedPrice *
                            plan.durationMonths *
                            widget.quantity,
                      ),
                      const SizedBox(height: 8),
                      if (widget.paymentOption == 0)
                        _buildPriceRowWithQuantity(
                          'Pay Now',
                          planData.discountedPrice *
                              plan.durationMonths *
                              widget.quantity,
                        )
                      else
                        _buildPriceRowWithQuantity(
                          'Installment (${plan.installmentFrequencyMonths}mo)',
                          planData.discountedPrice *
                              plan.installmentFrequencyMonths *
                              widget.quantity,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Payment options
                // Payment options
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'Payment:',
                      style: TextStyle(
                        color: AppColors.parchment70,
                        fontSize: 13,
                      ),
                    ),
                    _buildPaymentChip('One Time', 0),
                    // COD restriction: Installments are disabled. Comment out the Installments chip.
                    // if (plan.allowsInstallments)
                    //   _buildPaymentChip('Installments', 1),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.parchment70, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.harvestAmber,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRowWithQuantity(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.parchment70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppColors.harvestAmber,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentChip(String label, int value) {
    final isSelected = widget.paymentOption == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onPaymentOptionChanged(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.pureWhite.withValues(alpha: 0.25)
                  : AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.pureWhite.withValues(
              alpha: isSelected ? 0.5 : 0.3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: AppColors.pureWhite,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneTimePurchaseCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    bool isSelected,
  ) {
    final accentColor = AppColors.harvestAmber;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onPlanSelected(-1); // -1 indicates One-Time Purchase
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withValues(alpha: 0.85)],
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.pureWhite),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? accentColor.withValues(alpha: 0.5)
                    : (isDark
                        ? AppColors.parchment.withValues(alpha: 0.1)
                        : AppColors.charcoal12),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected
                            ? AppColors.pureWhite.withValues(alpha: 0.2)
                            : AppColors.transparent,
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.pureWhite
                              : (isDark
                                  ? AppColors.parchment54
                                  : AppColors.charcoal38),
                      width: 2,
                    ),
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.pureWhite,
                          )
                          : null,
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One-Time Purchase',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.pureWhite : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Single order, no commitment',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isSelected
                                  ? AppColors.pureWhite.withValues(alpha: 0.7)
                                  : theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Text(
                  '₹${widget.product.finalPrice.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected
                            ? AppColors.pureWhite
                            : AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildPriceRowWithQuantity(
                  'Total (1 time × ${widget.quantity})',
                  widget.product.finalPrice * widget.quantity,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
