import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/screens/product_details/widgets/product_top_nav_bar.dart';
import 'package:grocery_app/screens/product_details/widgets/product_header.dart';
import 'package:grocery_app/screens/product_details/widgets/product_image_carousel.dart';
import 'package:grocery_app/screens/product_details/widgets/subscription_plans_section.dart';
import 'package:grocery_app/screens/product_details/widgets/similar_products_section.dart';
import 'package:grocery_app/screens/product_details/widgets/product_bottom_action_bar.dart';
import 'package:grocery_app/screens/product_details/widgets/expandable_description.dart';
import 'package:grocery_app/screens/product_details/widgets/modern_subscription_sheet.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/plan_search_service.dart';

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

  final FavoriteStateService _favoriteStateService = getIt<FavoriteStateService>();
  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();
  final TokenService _tokenService = getIt<TokenService>();
  final ProfileService _profileService = getIt<ProfileService>();

  Timer? _cartDebounceTimer;
  bool _isCartOperationPending = false;
  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _loadSubscriptionPlans();
    _loadCategoryProducts();

    _pageController.addListener(() {
      if (mounted && _pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
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
      final favResult = await _profileService.getFavorites();
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
        if (widget.autoOpenSubscription &&
            availablePlansForProduct.isNotEmpty &&
            allPlans.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            int initialIndex = -1;
            if (widget.initialPlanId != null) {
              final foundIndex = allPlans.indexWhere(
                (p) => p.id == widget.initialPlanId,
              );
              if (foundIndex != -1) {
                initialIndex = foundIndex;
              }
            }

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

  void handleFavoriteToggle() async {
    if (_isTogglingFavorite) return;
    setState(() => _isTogglingFavorite = true);

    final result = await _profileService.toggleFavorite(widget.product.id);
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

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isTogglingFavorite = false);
    }
  }

  Future<void> _handleQuantityChanged(int newQuantity) async {
    _cartDebounceTimer?.cancel();
    if (_isCartOperationPending) {
      _cartDebounceTimer = Timer(_debounceDuration, () {
        _executeCartOperation(newQuantity);
      });
      return;
    }
    await _executeCartOperation(newQuantity);
  }

  Future<void> _executeCartOperation(int newQuantity) async {
    if (_isCartOperationPending) return;

    final token = await _tokenService.getAccessToken();
    if (!mounted) return;
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

      if (newQuantity > 0 && currentQuantity == 0) {
        cartCubit.addItem(widget.product, newQuantity);
      } else if (newQuantity == 0 && currentQuantity > 0) {
        cartCubit.removeItem(widget.product.id);
      } else {
        cartCubit.updateItem(widget.product.id, newQuantity);
      }
    } finally {
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
    required int quantity,
    String? paymentType,
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

    AppLogger.instance.log(
      'Navigating to Address Screen with: isSubscription=$isSubscription, selectedPlanId=$selectedPlanId, quantity=$quantity, price=$price, paymentType=$paymentType',
    );

    context.pushNamed(
      AppRoute.address.name,
      extra: {
        'singleProduct': widget.product,
        'quantity': quantity,
        'isSubscription': isSubscription,
        'price': price,
        'selectedPlan': selectedPlanId ?? 0,
        'paymentType': paymentType,
      },
    );
  }

  void _showSubscriptionSelectionSheet({
    required int initialPlanIndex,
    required int initialPlanId,
  }) {
    int selectedIndex = initialPlanIndex;
    int quantity = 1;
    int paymentOption = 0;

    _triggerHaptic();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      barrierColor: AppColors.charcoal.withValues(alpha: 0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return ModernSubscriptionSheet(
              product: widget.product,
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
                  _navigateToAddressScreen(
                    isSubscription: false,
                    quantity: quantity,
                    paymentType: 'PAID_FULL',
                  );
                } else {
                  _navigateToAddressScreen(
                    isSubscription: true,
                    selectedPlanIndex: selectedIndex,
                    quantity: quantity,
                    paymentType: 'PAID_FULL',
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom + 180.0;

    final backgroundImage = widget.product.productImages.isNotEmpty
        ? widget.product.productImages.first.image
        : 'https://via.placeholder.com/400';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.parchment,
      body: Stack(
        children: [
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
                ProductTopNavBar(
                  product: widget.product,
                  isFavorite: isFavorite,
                  isLoadingFavorite: _isLoadingFavorite,
                  onFavoriteToggle: handleFavoriteToggle,
                  onTriggerHaptic: _triggerHaptic,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              ProductHeader(product: widget.product),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            ProductImageCarousel(
                              product: widget.product,
                              pageController: _pageController,
                              currentPage: _currentPage,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              onTriggerHaptic: _triggerHaptic,
                            ),
                            if (!widget.product.isActive)
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: ColoredBox(
                                      color: isDark
                                          ? Colors.black.withValues(alpha: 0.72)
                                          : Colors.white.withValues(alpha: 0.72),
                                      child: const ComingSoonOverlay(),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingPlans ||
                            (availablePlansForProduct.isNotEmpty &&
                                allPlans.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SubscriptionPlansSection(
                              product: widget.product,
                              isLoadingPlans: _isLoadingPlans,
                              allPlans: allPlans,
                              availablePlansForProduct: availablePlansForProduct,
                              selectedPlanId: _selectedPlanId,
                              onPlanSelected: (planId) {
                                setState(() {
                                  _selectedPlanId = planId;
                                });
                              },
                              onShowSubscriptionSelectionSheet: (planId, index) {
                                _showSubscriptionSelectionSheet(
                                  initialPlanIndex: index,
                                  initialPlanId: planId,
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
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
                                  color: isDark
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SimilarProductsSection(
                            product: widget.product,
                            isLoadingSimilarProduct: _isLoadingSimilarProduct,
                            similarProducts: similarProducts,
                            onProductClicked: (context, item) {
                              context.pushNamed(
                                AppRoute.productDetails.name,
                                pathParameters: {'id': item.id.toString()},
                                extra: item,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ProductBottomActionBar(
        product: widget.product,
        allPlans: allPlans,
        availablePlansForProduct: availablePlansForProduct,
        onQuantityChanged: _handleQuantityChanged,
        onShowSubscriptionSelectionSheet: (index, planId) {
          _showSubscriptionSelectionSheet(
            initialPlanIndex: index,
            initialPlanId: planId,
          );
        },
      ),
    );
  }
}
