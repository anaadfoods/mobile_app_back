import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:grocery_app/helpers/animated_transitions.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/models/favorite_model.dart';
import 'package:grocery_app/models/plan_Search_model.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/screens/auth/login_screen.dart';
import 'package:grocery_app/screens/address/address_selection_screen.dart';
import 'package:grocery_app/screens/product_details/favourite_toggle_icon_widget.dart';
import 'package:grocery_app/services/auth_service.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/favorite_state_service.dart';
import 'package:grocery_app/services/plan_search_service.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/widgets/item_counter_widget.dart';
import 'package:shimmer/shimmer.dart'; // Import shimmer

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // --- STATE VARIABLES ---
int? _selectedPlanId; 
  bool isFavorite = false;
  bool _isTogglingFavorite = false;
  bool _isProcessingCart = false;

  // 👇 NEW: Granular loading states
  bool _isLoadingFavorite = true;
  bool _isLoadingPlans = true;
  bool _isLoadingSimilarProduct = true;


  List<SubscriptionPlan> allPlans = [];
  List<PlanSearchResult> availablePlansForProduct = [];
  List<ProductVariant> similarProducts = [];


  final PageController _pageController = PageController();
  int _currentPage = 0;

  // --- SERVICES ---
  final FavoriteStateService _favoriteStateService = FavoriteStateService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AuthService _authService = AuthService();
  final _categoryService = CategoryService();
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    // 👇 Fire off background data fetches without waiting
    _loadFavoriteStatus();
    _loadSubscriptionPlans();

    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
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

  // --- NEW: Separate fetching functions ---

  /// Fetches only the favorite status in the background.
  Future<void> _loadFavoriteStatus() async {
    try {
      final favResult = await _authService.getFavorites();
      if (mounted && favResult['success']) {
        final favorites = favResult['data'] as List<FavoriteModel>;

        setState(() {
          isFavorite = favorites.any((fav) => fav.productId == widget.product.id);
        });
      }
    } catch (e) {
      log('Error fetching favorite status: $e');
      // Optionally show a message or just fail silently
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  /// Fetches all subscription and plan data in the background.
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


   Future<void> _loadingSimilarProducts() async {
    try {
      final results = await Future.wait([
        // _categoryService.(widget.product.id),
        _subscriptionService.getSubscriptionPlans(),
      ]);

      if (!mounted) return;

      final similarProduct = results[0] as List<PlanSearchResult>;

      setState(() {
           similarProducts = similarProducts;
       
      });
    } catch (e) {
      log('Error fetching Similar Products : $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSimilarProduct = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImage = widget.product.productImages.isNotEmpty
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
                             padding: const EdgeInsets.symmetric(vertical: 10 , horizontal: 10),
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
                          _buildImageCarousel(),                           SizedBox(height: 10,),

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
                                const SizedBox(height: 24),
                                _buildSimilarProductsSection(),
                                const SizedBox(height: 24),
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
            child: _isLoadingFavorite
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB9A06D)),
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
            children: List.generate(allPlans.length > 4 ? 4 : allPlans.length, (index) {
              final plan = allPlans[index];
              
              // Find the corresponding available plan to get its data (including planId)
              final availablePlanData = availablePlansForProduct.firstWhere(
                (p) => p.planName == plan.name,
                orElse: () => PlanSearchResult(planId: 0, planName: '', discountPercentage: 0.0, discountedPrice: 0.0),
              );

              final bool isEnabled = availablePlanData.planId != 0;
              // ✅ KEY CHANGE: Check if the current plan's ID matches the selected ID in state
              final bool isSelected = _selectedPlanId == availablePlanData.planId;

              return GestureDetector(
                onTap: isEnabled
                    ? () {
                        // ✅ KEY CHANGE: Update state with the planId, not the index
                        setState(() => _selectedPlanId = availablePlanData.planId);
                        // Pass the actual planId to the bottom sheet
                        _showSubscriptionSelectionSheet(initialPlanId: availablePlanData.planId , initialPlanIndex: index);
                      }
                    : null,
                child: Opacity(
                  opacity: isEnabled ? 1.0 : 0.4,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.bottonBackgroundColor : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? Colors.grey.withOpacity(0.5) : Colors.grey.withOpacity(0.5), width: 1.5),
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
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.grey.withOpacity(0.5) : Colors.grey.withOpacity(0.7),
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
    // This should be populated with actual data from a service
    if (!_isLoadingSimilarProduct) {
      return _buildPlansSkeleton();
    }
    // 👇 Once loaded, if no plans are available, show nothing
    if (availablePlansForProduct.isEmpty || allPlans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                  /* Navigate to all similar products */
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
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: 4, // Placeholder count
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder:
                (context, index) => _buildProductCard(), // Placeholder card
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    // This is a placeholder, populate with real data
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl:
                    widget.product.productImages.isNotEmpty
                        ? widget.product.productImages.first.image
                        : 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Natural Barnyard Millet",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "₹124",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      width: 70,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB9A06D),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text("Add"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
            Container(
              width: 180,
              height: 24,
              color: Colors.white,
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

  // ... (The rest of your code: _buildBottomActionBar, handleFavoriteToggle, _handleBuyNow, _handleAddToCart, _navigateToAddressScreen, _showSubscriptionSelectionSheet, and the ExpandableDescription class remain the same)
  
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
          )
        ],
      ),
      child: Row(
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
              onPressed: _isProcessingCart ? null : _handleAddToCart,
              icon: _isProcessingCart
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(
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
                backgroundColor: AppColors.bottonBackgroundColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

  Future<void> _handleAddToCart() async {
    setState(() => _isProcessingCart = true);
    final token = await _authService.getAccessToken();
    if (token == null) {
      SnackBarHelper.showWarning(context, 'Please login to add items to cart');
      Navigator.push(
        context,
        AnimatedTransitions.slideFromRight(LoginScreen()),
      );
      setState(() => _isProcessingCart = false);
      return;
    }
    try {
      await _cartService.addToCart(
        widget.product.id,
        1,
      ); // Assuming quantity is 1 for now
      SnackBarHelper.showSuccess(
        context,
        '${widget.product.productName} added to cart',
      );
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to add item to cart: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingCart = false);
      }
    }
  }

  Future<void> _navigateToAddressScreen({
    required bool isSubscription,
    int? selectedPlanIndex,
    int? quantity,
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
    print('Navigating to Address Screen with: isSubscription=$isSubscription, selectedPlanId=$selectedPlanId, quantity=$quantity, price=$price');
    Navigator.push(
      context,
      AnimatedTransitions.slideFromBottom(
        AddressSelectionScreen(
          singleProduct: widget.product,
          quantity: quantity ?? 1,
          isSubscription: isSubscription,
          price: price,
          selectedPlan: selectedPlanId ?? 0,
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
      _buildFeatureItem(iconColor, textColor, "Duration - ${plan.durationMonths} Months"),
      const SizedBox(height: 4),
      _buildFeatureItem(iconColor, textColor, "Savings - ${plan.discountPercentage.toString()}% Off"),
    ],
  );
}

Widget _buildPlanFeaturesRow2(SubscriptionPlan plan, bool isSelected) {
  Color textColor = isSelected ? Colors.white70 : Colors.black54;
  Color iconColor = isSelected ? Colors.white : const Color(0xFF388E3C);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildFeatureItem(iconColor, textColor,
          "One-Time Allowance - ${plan.isOneTimeOnly ? "Yes" : "No"}"),
      const SizedBox(height: 4),
      _buildFeatureItem(iconColor, textColor,
          "Installment Frequency - ${plan.installmentFrequencyMonths} Months"),
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
          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}









  void _showSubscriptionSelectionSheet({required int initialPlanIndex, required int initialPlanId}) {
    int selectedIndex = initialPlanIndex;
    int quantity = 1;
    int paymentOption = 0;
    
    int sentIndex = 0; // 0 for One Time, 1 for Installments

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
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
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      "Select Subscription",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                              discountPercentage: 0
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
                                    ? AppColors.bottonBackgroundColor
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.black
                                      : Colors.grey.shade300,
                              width: 1.0,
                            ),
                          ),
                          child: Opacity(
                            opacity: (planData.discountedPrice == 0)
                                    ? 0.2
                                    : 1,
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
                                        decoration: (planData.discountedPrice == 0)
                                            ? TextDecoration.lineThrough : null,
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [ 
                                   _buildPlanFeaturesRow(plan, isSelected),
                                  _buildPlanFeaturesRow2(plan, isSelected),
                                ]),
                                if (isSelected) ...[
                                 
                                  _buildExpandedPlanDetails(
                                    plan,
                                    planData,
                                    paymentOption,
                                    setModalState,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Select your monthly requirements",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.bottonBackgroundColor,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: ItemCounterWidget(
                          amount: quantity,
                          onAmountChanged: (newAmount) {
                            setModalState(() {
                              quantity = newAmount;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              
                            });
                            Navigator.pop(context); // Close the bottom sheet
                            _navigateToAddressScreen(
                              isSubscription: true,
                              selectedPlanIndex: selectedIndex,
                              quantity: quantity,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.bottonBackgroundColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: AppColors.bottonBackgroundColor,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              
                            ),
                          ),
                          child: const Text(
                            "Subscribe",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10,)
                ],
              ),
            );
          },
        );
      },
    );
  }

  // // New helper for the always-visible features row
  // Widget _buildPlanFeaturesRow(SubscriptionPlan plan, bool isSelected) {
  //   Color textColor = isSelected ? Colors.white70 : Colors.black54;
  //   Color iconColor = isSelected ? Colors.white : const Color(0xFF388E3C);

  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       _buildFeatureItem(
  //         iconColor,
  //         textColor,
  //         "Duration- ${plan.durationMonths} Months",
  //       ),
  //       SizedBox(width: 10),
  //        _buildFeatureItem(
  //         iconColor,
  //         textColor,
  //         "Savings- ${plan.discountPercentage}% Off",
  //       ),
        
  //     ],
  //   );
  // }

  // Widget _buildPlanFeaturesRow2(SubscriptionPlan plan, bool isSelected) {
  //   Color textColor = isSelected ? Colors.white70 : Colors.black54;
  //   Color iconColor = isSelected ? Colors.white : const Color(0xFF388E3C);

  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       _buildFeatureItem(
  //         iconColor,
  //         textColor,
  //         "One-time Allow- ${plan.isOneTimeOnly ? "Yes" : "No"}",
  //       ),
       
  //       SizedBox(width: 10),
  //       _buildFeatureItem(
  //         iconColor,
  //         textColor,
  //         "Frequency- ${plan.installmentFrequencyMonths} Months",
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildFeatureItem(Color iconColor, Color textColor, String text) {
  //   return Row(
  //     children: [
  //       Icon(Icons.check_circle, color: iconColor, size: 16),
  //       const SizedBox(width: 4),
  //       Text(text, style: TextStyle(color: textColor, fontSize: 11)),
  //     ],
  //   );
  // }

  // New helper for the expanded details section
  Widget _buildExpandedPlanDetails(
    SubscriptionPlan plan,
    PlanSearchResult planData,
    int currentPaymentOption,
    StateSetter setModalState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        children: [
          const Divider(color: Colors.white54),
          const SizedBox(height: 8),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '10% Savings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Payment Options',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildPaymentOptionRadio(
                0,
                'One Time',
                currentPaymentOption,
                setModalState,
              ),
              const SizedBox(width: 2),
              _buildPaymentOptionRadio(
                1,
                'Installments',
                currentPaymentOption,
                setModalState,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New helper for the radio buttons
  Widget _buildPaymentOptionRadio(
    int index,
    String text,
    int selectedOption,
    StateSetter setModalState,
  ) {
    return GestureDetector(
      onTap: () => setModalState(() => selectedOption = index),
      child: Row(
        children: [
          Radio<int>(
            value: index,
            groupValue: selectedOption,
            onChanged: (value) => setModalState(() => selectedOption = value!),
            activeColor: Colors.white,
            fillColor: MaterialStateProperty.all(Colors.white),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
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
  const ExpandableDescription({Key? key, required this.text}) : super(key: key);

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
