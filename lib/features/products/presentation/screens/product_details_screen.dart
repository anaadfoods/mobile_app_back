import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grocery_app/helpers/responsive_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/common_widgets/coming_soon_overlay.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_state.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_state.dart';
import 'package:grocery_app/features/products/presentation/widgets/product_top_nav_bar.dart';
import 'package:grocery_app/features/products/presentation/widgets/product_header.dart';
import 'package:grocery_app/features/products/presentation/widgets/product_image_carousel.dart';
import 'package:grocery_app/features/products/presentation/widgets/subscription_plans_section.dart';
import 'package:grocery_app/features/products/presentation/widgets/similar_products_section.dart';
import 'package:grocery_app/features/products/presentation/widgets/product_bottom_action_bar.dart';
import 'package:grocery_app/features/products/presentation/widgets/expandable_description.dart';
import 'package:grocery_app/features/products/presentation/widgets/modern_subscription_sheet.dart';
import 'package:grocery_app/service_locator.dart';
import 'package:grocery_app/services/plan_search_service.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_plans_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/entities/subscription_plan_entity.dart';

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

  final GetSubscriptionPlansUseCase _getSubscriptionPlansUseCase =
      getIt<GetSubscriptionPlansUseCase>();

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
      final favState = context.read<FavoritesCubit>().state;
      if (favState is FavoritesSuccess) {
        setState(() {
          isFavorite = favState.favoriteProductIds.contains(widget.product.id);
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
      final results = await Future.wait<dynamic>([
        PlanSearchService.fetchPlansForVariant(widget.product.id),
        _getSubscriptionPlansUseCase(),
      ]);

      if (!mounted) return;

      final productPlans = results[0] as List<PlanSearchResult>;
      final planEntities = results[1] as List<SubscriptionPlanEntity>;

      setState(() {
        availablePlansForProduct = productPlans;
        allPlans = planEntities
            .map((e) => SubscriptionPlan(
                  id: e.id,
                  name: e.name,
                  durationMonths: e.durationMonths,
                  discountPercentage: e.discountPercentage,
                  totalDiscountPercentage: e.totalDiscountPercentage,
                  tagline: e.tagline,
                  description: e.description,
                  isActive: e.isActive,
                  activationDate: e.activationDate,
                  isOneTimeOnly: e.isOneTimeOnly,
                  allowsInstallments: e.allowsInstallments,
                  installmentFrequencyMonths: e.installmentFrequencyMonths,
                  isAvailable: e.isAvailable,
                ))
            .toList();
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
              initialPlanId:
                  initialIndex != -1 ? allPlans[initialIndex].id : -1,
            );
          });
        }
      }
    }
  }

  void handleFavoriteToggle() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) {
      SnackBarHelper.showWarning(context, 'Please login to add favorites');
      context.push(AppRoute.login.path);
      return;
    }
    context.read<FavoritesCubit>().toggleFavorite(widget.product.id);
    setState(() => isFavorite = !isFavorite);
    SnackBarHelper.showSuccess(
      context,
      isFavorite ? 'Added to favorites' : 'Removed from favorites',
    );
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

    final authState = context.read<AuthCubit>().state;
    if (!mounted) return;
    if (authState is! Authenticated) {
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

  // String _rewriteDescription(String desc) {
  //   String text = desc;

  //   // Section 1 Body
  //   text = text.replaceAll(
  //     "This flour is made from indigenous Sona Moti wheat naturally grown and slowly ground on stone chakki using a cold-pressed method. Theres no blending, no artificial softness, and no nutrient loss from high-speed rollers. Just grain, tradition, and temperature-controlled truth.",
  //     "This flour is made from indigenous Sona Moti wheat — grown on our own farm and slowly ground on a stone chakki using a cold-pressed method.\n\nThere's no blending, no artificial softness, and no nutrient loss from high-speed rollers.\nJust grain, tradition, and temperature-controlled truth."
  //   );

  //   // Section 2 Body
  //   text = text.replaceAll(
  //     "Sona Moti wheat is known for its higher glutenin content, rich mineral profile, and longlasting energy. It supports better digestion, promotes strength, and is ideal for daily rotis that dont feel heavy post-meal.",
  //     "Sona Moti wheat has a higher glutenin content than most commercial varieties — which means better dough structure, richer flavour, and rotis that don't leave you feeling heavy.\n\nIt's also naturally higher in minerals and sustains energy longer than refined flour."
  //   );

  //   // Section 3 Sub-heading
  //   text = text.replaceAll(
  //     "What Youre Sold Instead",
  //     "What Most Store-Bought Flour Contains"
  //   );
  //   text = text.replaceAll(
  //     "What You're Sold Instead",
  //     "What Most Store-Bought Flour Contains"
  //   );

  //   // Section 3 Body
  //   text = text.replaceAll(
  //     "Most wheat flour sold today is bleached, refined, or made from hybrid grain varieties designed for yield, not health. Fast-milled at high RPM, these flours lose thermal-sensitive nutrients and are often mixed with maida. It looks soft but weakens your gut over time.",
  //     "Most wheat flour sold today is bleached, refined, or made from hybrid varieties selected for yield — not flavour or nutrition.\n\nAt high milling speeds, heat damages the grain's natural oils and micronutrients. Many commercial flours are also blended with maida to improve softness. The result looks fine in the packet but loses most of what made the grain worth eating."
  //   );

  //   // Generic fixes (fallback)
  //   text = text.replaceAll("Theres", "There's");
  //   text = text.replaceAll("dont", "don't");
  //   text = text.replaceAll("Youre", "You're");

  //   return text;
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom + 24.0;

    final backgroundImage =
        widget.product.productImages.isNotEmpty
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
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.0),
                              ProductHeader(product: widget.product),
                              SizedBox(height: 24.0),
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20.0),
                                    child: ColoredBox(
                                      color:
                                          isDark
                                              ? Colors.black.withValues(
                                                alpha: 0.72,
                                              )
                                              : Colors.white.withValues(
                                                alpha: 0.72,
                                              ),
                                      child: const ComingSoonOverlay(),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        if (widget.product.isActive &&
                            widget.product.isInStock &&
                            (_isLoadingPlans ||
                                (availablePlansForProduct.isNotEmpty &&
                                    allPlans.isNotEmpty)))
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: SubscriptionPlansSection(
                              product: widget.product,
                              isLoadingPlans: _isLoadingPlans,
                              allPlans: allPlans,
                              availablePlansForProduct:
                                  availablePlansForProduct,
                              selectedPlanId: _selectedPlanId,
                              onPlanSelected: (planId) {
                                setState(() {
                                  _selectedPlanId = planId;
                                });
                              },
                              onShowSubscriptionSelectionSheet: (
                                planId,
                                index,
                              ) {
                                _showSubscriptionSelectionSheet(
                                  initialPlanIndex: index,
                                  initialPlanId: planId,
                                );
                              },
                            ),
                          ),
                        SizedBox(height: 24.0),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Description",
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? AppColors.parchment
                                          : AppColors.charcoal,
                                ),
                              ),
                              SizedBox(height: 12.0),
                              ExpandableDescription(
                                text: widget.product.productDescription,
                              ),
                              if (widget.product.cropCycleId != null) ...[
                                SizedBox(height: 24.0),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final url = Uri.parse(
                                        'https://anaadfoods.com/traceability-journey?crop_id=${widget.product.cropCycleId}',
                                      );
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      } else {
                                        SnackBarHelper.showError(
                                          context,
                                          'Could not launch URL',
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16.0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Traceability Journey',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 24.0),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                        SizedBox(height: 24.0),
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
