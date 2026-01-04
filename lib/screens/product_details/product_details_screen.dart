import 'dart:ui';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

// --- CUBIT & STATE IMPORTS (Ensure paths are correct) ---

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  // --- ANIMATION CONTROLLERS ---
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

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
    // Shimmer animation
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Float animation for particles
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- DATA FETCHING (Unchanged) ---
  Future<void> _loadCategoryProducts() async {
    try {
      final products = await CategoryService.fetchProductsByCategory(
        widget.product.productCategory,
      );
      if (products.isNotEmpty && mounted) {
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
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : Colors.white,
      body: Stack(
        children: [
          // Blurred Background with shimmer
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              return Container(
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
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    // Shimmer overlay
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.03),
                            Colors.transparent,
                          ],
                          stops: [
                            (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                            _shimmerAnimation.value.clamp(0.0, 1.0),
                            (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating particles
          _buildFloatingParticles(),

          // Main Content
          Column(
            children: [
              SafeArea(child: _buildTopNavBar()),

              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(35),
                  ),

                  child: Container(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                _buildBestsellerTag(),

                                const SizedBox(height: 12),

                                _buildProductTitle(),

                                const SizedBox(height: 8),

                                _buildRatingAndOrders(),

                                const SizedBox(height: 20),

                                _buildPriceAndSubscribe(),

                                const SizedBox(height: 20),

                                ExpandableDescription(
                                  text: widget.product.productDescription,
                                ),
                              ],
                            ),
                          ),

                          _buildImageCarousel(),
                          SizedBox(height: 10),

                          if (widget.product.productImages.length > 1)
                            _buildCarouselIndicators(),

                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),

                            width: double.infinity,

                            color:
                                isDark ? const Color(0xFF1A1A2E) : Colors.white,

                            child: Column(
                              children: [
                                const SizedBox(height: 8),

                                _buildSubscriptionPlansSection(isDark),

                                const SizedBox(height: 4),

                                _buildSimilarProductsSection(isDark),

                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      bottomNavigationBar: _buildBottomActionBar(),
    );
  }
  // --- UI BUILDER WIDGETS ---

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned(
              top: 80 + (_floatAnimation.value * 12),
              right: 30,
              child: _buildParticle(8, const Color(0xFFB9A06D)),
            ),
            Positioned(
              top: 180 + (_floatAnimation.value * -10),
              left: 25,
              child: _buildParticle(5, Colors.white),
            ),
            Positioned(
              top: 280 + (_floatAnimation.value * 8),
              right: 50,
              child: _buildParticle(6, const Color(0xFFB9A06D)),
            ),
            Positioned(
              bottom: 350 + (_floatAnimation.value * -6),
              left: 40,
              child: _buildParticle(4, Colors.white),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.4),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Glassmorphism back button
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: GestureDetector(
                onTap: () {
                  _triggerHaptic();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          // Actions row
          Row(
            children: [
              // Share button
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: GestureDetector(
                    onTap: () => _triggerHaptic(),
                    child: Container(
                      
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Favorite button
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child:
                        _isLoadingFavorite
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFB9A06D),
                                ),
                              ),
                            )
                            : GestureDetector(
                              onTap: () {
                                _triggerHaptic();
                                handleFavoriteToggle(widget.product.id);
                              },
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  key: ValueKey(isFavorite),
                                  color:
                                      isFavorite
                                          ? const Color(0xFFE53935)
                                          : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
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
      Navigator.push(
        context,

        AnimatedTransitions.slideFromRight(LoginScreen()),
      );
    } else {
      SnackBarHelper.showError(
        context,

        result['message'] ?? 'Failed to update favorite',
      );
    }

    setState(() => _isTogglingFavorite = false);
  }

  // ... (All other _build... widgets from _buildBestsellerTag to _buildProductCard remain the same)

  Widget _buildBestsellerTag() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB9A06D), Color(0xFFD4B98E)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB9A06D).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                const Text(
                  'Bestseller',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: Text(
              '${widget.product.productName} - ${widget.product.weight}',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingAndOrders() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '4.6',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '1.2k reviews',
                style: TextStyle(color: Colors.grey[300], fontSize: 13),
              ),
              const SizedBox(width: 12),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[500],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '8.5k orders',
                style: TextStyle(color: Colors.grey[300], fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceAndSubscribe() {
    double discount =
        ((widget.product.price - widget.product.finalPrice) /
            widget.product.price) *
        100;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${widget.product.finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '₹${widget.product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.product.isInStock)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'In Stock',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Discount badge
                    if (discount > 0)
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '${discount.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCarousel() {
    final productImages = widget.product.productImages;
    if (productImages.isEmpty) {
      return Container(
        height: 280,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, color: Colors.grey[400], size: 48),
              const SizedBox(height: 8),
              Text(
                'No Images Available',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pageController,
        itemCount: productImages.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = (_pageController.page! - index).abs();
                value = (1 - (value * 0.15)).clamp(0.85, 1.0);
              }
              return Center(
                child: Transform.scale(
                  scale: value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB9A06D).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: productImages[index].image,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey.withOpacity(0.2),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFB9A06D),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey.withOpacity(0.2),
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
                        colors: [Color(0xFFB9A06D), Color(0xFFD4B98E)],
                      )
                      : null,
              color: isActive ? null : Colors.grey[600],
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  isActive
                      ? [
                        BoxShadow(
                          color: const Color(0xFFB9A06D).withOpacity(0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
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
              color: isDark ? Colors.white : Colors.black,
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
                  child: Opacity(
                    opacity: isEnabled ? 1.0 : 0.4,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.buttonBackgroundColor
                                : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.grey.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.black),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                "₹${availablePlanData.discountedPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.grey.withOpacity(0.5)
                                          : Colors.grey.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "Save ${availablePlanData.discountPercentage.toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
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
      return _buildPlansSkeleton();
    }

    if (availablePlansForProduct.isEmpty ||
        allPlans.isEmpty ||
        similarProducts.isEmpty) {
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
                color: isDark ? Colors.white : Colors.black,
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
              child: const Row(
                children: [
                  Text("See All", style: TextStyle(color: Color(0xFFB9A06D))),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFB9A06D),
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
    Navigator.push(
      context,
      AnimatedTransitions.fadeScale(ProductDetailsScreen(product: item)),
    );
  }

  // --- NEW: Skeleton widget for the plans section ---
  Widget _buildPlansSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 180, height: 24, color: Colors.white),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
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

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ).copyWith(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
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
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.buttonBackgroundColor,
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
    return Row(
      key: key,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _handleBuyNow,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFFB9A06D)),
              foregroundColor: const Color(0xFFB9A06D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Buy Now",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            // Use the cubit's optimistic update, so local loading state is less needed.
            onPressed: () => _handleQuantityChanged(1),
            icon: const Icon(
              Icons.shopping_cart_outlined,
              size: 20,
              color: Colors.white,
            ),
            label: const Text(
              "Add to Cart",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.buttonBackgroundColor,
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
    return Row(
      key: key,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
            icon: const Icon(Icons.shopping_cart_checkout, size: 20),
            label: const Text(
              "View Cart",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.buttonBackgroundColor),
              foregroundColor: AppColors.buttonBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ItemCounterWidget(
            amount: quantity,
            onAmountChanged: (newAmount) => _handleQuantityChanged(newAmount),
            scale: 1.4,
          ),
        ),
      ],
    );
  }

  Future<void> _handleQuantityChanged(int newQuantity) async {
    // Login check remains the same
    final token = await _authService.getAccessToken();
    if (token == null) {
      SnackBarHelper.showWarning(context, 'Please login to modify your cart');
      Navigator.push(
        context,
        AnimatedTransitions.slideFromRight(const LoginScreen()),
      );
      return;
    }

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
  }

  Future<void> _handleBuyNow() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      SnackBarHelper.showWarning(context, 'Please login to proceed');
      Navigator.push(
        context,
        AnimatedTransitions.slideFromRight(LoginScreen()),
      );
      return;
    }
    print('Buy Now pressed, navigating to Address Selection Screen');
    _navigateToAddressScreen(isSubscription: false, quantity: 1);
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

    Navigator.push(
      context,
      AnimatedTransitions.slideFromBottom(
        AddressSelectionScreen(
          singleProduct: widget.product,
          quantity: quantity ?? 1,
          isSubscription: isSubscription,
          price: price,
          selectedPlan: selectedPlanId ?? 0,
          paymentType: paymentType, // Pass it to the next screen
        ),
      ),
    );
  }

  // PASTE THIS ENTIRE BLOCK INTO YOUR _ProductDetailsScreenState CLASS

  Widget _buildPlanFeaturesRow(SubscriptionPlan plan, bool isSelected) {
    Color textColor = isSelected ? Colors.white70 : Colors.black54;
    Color iconColor = isSelected ? Colors.white : const Color(0xFF388E3C);

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
    Color textColor = isSelected ? Colors.white70 : Colors.black54;
    Color iconColor = isSelected ? Colors.white : const Color(0xFF388E3C);

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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return _ModernSubscriptionSheet(
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
                final String paymentType =
                    (paymentOption == 0) ? 'PAID_FULL' : 'INSTALLMENT';
                Navigator.pop(context);
                _navigateToAddressScreen(
                  isSubscription: true,
                  selectedPlanIndex: selectedIndex,
                  quantity: quantity,
                  paymentType: paymentType,
                );
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
        color: isSelected ? AppColors.buttonBackgroundColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected
                  ? AppColors.buttonBackgroundColor
                  : Colors.grey.shade300,
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
                      isSelected ? Colors.white : Colors.grey.withOpacity(0.9),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  plan.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  "₹${planData.discountedPrice.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
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
          const Divider(color: Colors.white54),
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
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '₹${(planData.discountedPrice * plan.durationMonths).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                      style: TextStyle(color: Colors.white70),
                    ),
                    Row(
                      children: [
                        Text(
                          '₹${planData.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                  color: Colors.white,
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
              if (plan.allowsInstallments)
                _buildPaymentOptionRadio(
                  1,
                  'Installments',
                  currentPaymentOption,
                  onPaymentOptionChanged, // Pass the callback down
                ),
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
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
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
          Text(title, style: TextStyle(color: Colors.white)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: _isExpanded ? null : 2,
            overflow: TextOverflow.fade,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(
            _isExpanded ? "less" : "more",
            style: const TextStyle(
              color: Color(0xFFB9A06D),
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
    final accentColor = theme.colorScheme.primary;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
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
                              accentColor.withOpacity(
                                _glowAnimation.value * 0.3,
                              ),
                              accentColor.withOpacity(
                                _glowAnimation.value * 0.1,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Content
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                    accentColor.withOpacity(0.3),
                                    accentColor.withOpacity(0.6),
                                    accentColor.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(
                                      _glowAnimation.value * 0.5,
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

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withOpacity(0.2),
                                  accentColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.card_membership_rounded,
                              color: accentColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose Your Plan',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Subscribe & save with monthly deliveries',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

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

                      // Quantity Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monthly Quantity',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'How many do you need per month?',
                                    style: theme.textTheme.bodySmall?.copyWith(
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

                      const SizedBox(height: 24),

                      // Subscribe Button
                      ModernBottomSheetButton(
                        label: 'Subscribe Now',
                        icon: Icons.rocket_launch_rounded,
                        onTap: widget.onSubscribe,
                        color: accentColor,
                      ),
                    ],
                  ),
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
    final accentColor = theme.colorScheme.primary;

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
                    colors: [accentColor, accentColor.withOpacity(0.85)],
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark ? Colors.grey.shade900 : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? accentColor.withOpacity(0.5)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
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
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400),
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
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
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.durationMonths} months • ${planData.discountPercentage.toStringAsFixed(0)}% off',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isSelected
                                    ? Colors.white.withOpacity(0.8)
                                    : theme.hintColor,
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
                          color: isSelected ? Colors.white : accentColor,
                        ),
                      ),
                      Text(
                        '/month',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isSelected
                                  ? Colors.white.withOpacity(0.7)
                                  : theme.hintColor,
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildPriceRow(
                        'Total for ${plan.durationMonths} months',
                        '₹${(planData.discountedPrice * plan.durationMonths).toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'Monthly payment',
                        '₹${planData.discountedPrice.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Payment options
                Row(
                  children: [
                    const Text(
                      'Payment:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    _buildPaymentChip('One Time', 0),
                    const SizedBox(width: 8),
                    if (plan.allowsInstallments)
                      _buildPaymentChip('Installments', 1),
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
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
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
              isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.5 : 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
