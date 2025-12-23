import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

// --- CUBIT & STATE IMPORTS (Ensure paths are correct) ---

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
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
  final PageController _pageController = PageController();
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

  @override
  void dispose() {
    _pageController.dispose();
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
    final backgroundImage =
        widget.product.productImages.isNotEmpty
            ? widget.product.productImages.first.image
            : 'https://via.placeholder.com/400';

    // No longer need a full-screen loader. The UI builds instantly.

    return Scaffold(
      backgroundColor: Colors.white,

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
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),

              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          ),

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

                            color: Colors.white,

                            child: Column(
                              children: [
                                const SizedBox(height: 12),

                                _buildSubscriptionPlansSection(),

                                const SizedBox(height: 10),

                                _buildSimilarProductsSection(),

                                const SizedBox(height: 12),
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

  Widget _buildTopNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            // 👇 This local loader works perfectly now
            child:
                _isLoadingFavorite
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFB9A06D),
                        ),
                      ),
                    )
                    : FavoriteToggleIcon(
                      favorite: isFavorite,
                      onToggle: () => handleFavoriteToggle(widget.product.id),
                    ),
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
    // You can add logic here to show this tag conditionally
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Bestseller',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProductTitle() {
    return Text(
      '${widget.product.productName} - ${widget.product.weight}',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRatingAndOrders() {
    // Replace with actual data from your product model if available
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 8),
        Text(
          '4.6 (1.2k reviews)',
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text('|', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          '8.5k orders',
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPriceAndSubscribe() {
    double discount =
        ((widget.product.price - widget.product.finalPrice) /
            widget.product.price) *
        100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "₹${widget.product.finalPrice.toStringAsFixed(0)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "₹${widget.product.price.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            if (discount > 0)
              Text(
                'Get ${discount.toStringAsFixed(0)}% OFF',
                style: const TextStyle(
                  color: Color(0xFF388E3C),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    final productImages = widget.product.productImages;
    if (productImages.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            "No Images Available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _pageController,
        itemCount: productImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: CachedNetworkImageProvider(productImages[index].image),
                fit: BoxFit.cover,
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: _currentPage == index ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: _currentPage == index ? Colors.white : Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  Widget _buildSubscriptionPlansSection() {
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
          const Text(
            "Subscription Plans",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
                              color: isSelected ? Colors.white : Colors.black,
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
                                      isSelected ? Colors.white : Colors.black,
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

  Widget _buildSimilarProductsSection() {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Similar Products",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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

  // PASTE THIS ENTIRE METHOD INTO YOUR _ProductDetailsScreenState CLASS

  void _showSubscriptionSelectionSheet({
    required int initialPlanIndex,
    required int initialPlanId,
  }) {
    int selectedIndex = initialPlanIndex;
    int quantity = 1;
    // 0 for "One Time", 1 for "Installments". This is the source of truth.
    int paymentOption = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // StatefulBuilder creates a local state for the modal sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(
                10,
                5,
                10,
                20,
              ), // Added bottom padding
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Select Subscription",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allPlans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plan = allPlans[index];
                      final planData = availablePlansForProduct.firstWhere(
                        (p) => p.planName == plan.name,
                        orElse:
                            () => PlanSearchResult(
                              planId: 0,
                              planName: '',
                              discountedPrice: 0,
                              discountPercentage: 0,
                            ),
                      );
                      final bool isEnabled = planData.discountedPrice > 0;
                      final bool isSelected = selectedIndex == index;

                      return GestureDetector(
                        onTap:
                            isEnabled
                                ? () =>
                                    setModalState(() => selectedIndex = index)
                                : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.buttonBackgroundColor
                                    : Colors.white,
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
                                          : Icons
                                              .check_box_outline_blank_rounded,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.withOpacity(0.9),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      plan.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "₹${planData.discountedPrice.toStringAsFixed(0)}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildPlanFeaturesRow(plan, isSelected),
                                    _buildPlanFeaturesRow2(plan, isSelected),
                                  ],
                                ),
                                if (isSelected)
                                  _buildExpandedPlanDetails(
                                    plan,
                                    planData,
                                    paymentOption, // Pass the current state
                                    (newOption) {
                                      // The callback from the child updates the state here
                                      setModalState(() {
                                        paymentOption = newOption;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Select your monthly requirements",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ItemCounterWidget(
                          amount: quantity,
                          onAmountChanged: (newAmount) {
                            setModalState(() => quantity = newAmount);
                          },
                          scale: 1.3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: () {
                            final String paymentType =
                                (paymentOption == 0)
                                    ? 'PAID_FULL'
                                    : 'INSTALLMENT';
                            Navigator.pop(context);
                            _navigateToAddressScreen(
                              isSubscription: true,
                              selectedPlanIndex: selectedIndex,
                              quantity: quantity,
                              paymentType: paymentType,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.buttonBackgroundColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Subscribe",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
