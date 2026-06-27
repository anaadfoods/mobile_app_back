import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:grocery_app/models/product_image_model.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';

import 'package:grocery_app/service_locator.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  _FavouriteScreenState createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen>
    with TickerProviderStateMixin {
  final TokenService _tokenService = getIt<TokenService>();
  final ProfileService _profileService = getIt<ProfileService>();
  final FavoriteStateService _favoriteStateService =
      getIt<FavoriteStateService>();

  List<FavoriteModel> _favorites = [];
  final Set<int> _processingItems = {};
  bool _isLoading = true;
  String? _error;
  bool _isUpdatingInternally = false;

  StreamSubscription? _authSubscription;
  StreamSubscription? _favoriteSubscription;

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _pulseController;

  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<double> _contentFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadFavorites();

    _authSubscription = TokenService.authStateChanges.listen((isLoggedIn) {
      if (!mounted) return;
      if (isLoggedIn) {
        _loadFavorites();
      } else {
        setState(() {
          _favorites = [];
          _error = 'Please login to view favorites';
        });
      }
    });

    _favoriteSubscription = _favoriteStateService.onFavoriteChanged.listen((_) {
      if (mounted && !_isUpdatingInternally) _loadFavorites();
    });
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
      duration: const Duration(milliseconds: 1500),
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _authSubscription?.cancel();
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Please login to view favorites';
          });
        }
        return;
      }

      final favResult = await _profileService.getFavorites();

      if (!mounted) return;

      if (favResult['success']) {
        final favoriteList = favResult['data'] as List<FavoriteModel>;
        setState(() {
          _favorites = favoriteList;
        });
        // Start content animation after data loads
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _contentController.forward();
        });
      } else {
        setState(() {
          _error =
              favResult['message'] ?? 'Failed to load favorites. Please login.';
        });
      }

      // Ensure cart is loaded in Cubit
      context.read<CartCubit>().loadCart();
    } catch (e) {
      if (mounted) setState(() => _error = 'Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromFavorites(FavoriteModel favorite, int index) async {
    // Current removal logic is fine, keeping it.
    if (_processingItems.contains(favorite.productId)) return;
    HapticFeedback.mediumImpact();

    final originalIndex = _favorites.indexWhere((f) => f.id == favorite.id);
    if (originalIndex == -1) return;

    setState(() {
      _processingItems.add(favorite.productId);
      _isUpdatingInternally = false;
      _favorites.removeAt(originalIndex);
    });

    try {
      final result = await _profileService.toggleFavorite(favorite.productId);
      if (!mounted) return;

      final isSuccess =
          result['success'] == true ||
          (result['message'] as String?)?.toLowerCase().contains('removed') ==
              true;

      if (isSuccess) {
        SnackBarHelper.showSuccess(
          context,
          result['message'] ?? 'Removed from favorites',
        );
        _favoriteStateService.notifyFavoriteChanged();
      } else {
        setState(() {
          _favorites.insert(originalIndex, favorite);
        });
        SnackBarHelper.showError(
          context,
          result['message'] ?? 'Failed to remove favorite',
        );
      }
    } catch (e) {
      setState(() {
        _favorites.insert(originalIndex, favorite);
      });
      SnackBarHelper.showError(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _processingItems.remove(favorite.productId);
          _isUpdatingInternally = false;
        });
      }
    }
  }

  // Helper to convert FavoriteModel to Product for CartCubit
  Product _createProductFromFavorite(FavoriteModel favorite) {
    return Product(
      id: favorite.productId,
      sku: '',
      weight: favorite.weight,
      weightUnit: '',
      price: double.tryParse(favorite.price) ?? 0.0,
      discountPercentage: 0.0,
      finalPrice: double.tryParse(favorite.price) ?? 0.0,
      isInStock: true,
      isActive: true,
      productName: favorite.name,
      productDescription: '',
      productCategory: favorite.productCategory,
      productImages: [
        ProductImage(image: favorite.image, altText: favorite.name),
      ],
    );
  }

  void _handleQuantityChanged(FavoriteModel favorite, int newQuantity) {
    HapticFeedback.selectionClick();
    final cubit = context.read<CartCubit>();
    final currentQty = _getQuantity(favorite.productId);

    if (newQuantity > 0 && currentQty == 0) {
      // Add new item
      cubit.addItem(_createProductFromFavorite(favorite), newQuantity);
    } else if (newQuantity == 0) {
      // Remove item
      cubit.removeItem(favorite.productId);
    } else {
      // Update quantity
      cubit.updateItem(favorite.productId, newQuantity);
    }
  }

  int _getQuantity(int productId) {
    final state = context.read<CartCubit>().state;
    if (state is CartSuccess) {
      final item = state.cart.items.firstWhereOrNull(
        (item) => item.productVariant.id == productId,
      );
      return item?.quantity ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          CartModel? cart;
          if (cartState is CartSuccess) {
            cart = cartState.cart;
          }

          return CustomScrollView(
            slivers: [
              // Animated Header
              _buildAnimatedHeader(theme, isDark),

              // Content
              if (_isLoading)
                SliverFillRemaining(
                  child: const LoadingStateWidget(
                    itemHeight: 112,
                    borderRadius: 20,
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildErrorState(theme))
              else if (_favorites.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(theme, isDark))
              else
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - _contentFade.value)),
                        child: Opacity(
                          opacity: _contentFade.value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Row
                          _buildStatsRow(theme, isDark, cart),
                          const SizedBox(height: 20),

                          // Favorites List
                          ...List.generate(_favorites.length, (index) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(
                                milliseconds: 400 + (index * 80),
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildFavoriteCard(
                                  _favorites[index],
                                  index,
                                  theme,
                                  isDark,
                                  cart,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double appBarHeight = (statusBarHeight + 140).clamp(
      180.0,
      math.max(180.0, screenHeight * 0.28).toDouble(),
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
          height: appBarHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.harvestAmber,
                AppColors.harvestAmber,
                AppColors.rawEarth,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.harvestAmber.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Heart icon with light white background
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
                    Icons.favorite_rounded,
                    color: AppColors.parchment,
                    size: 28,
                  ),
                ),
              ),

              // Header Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      // Title
                      Text(
                        "My Wishlist",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _favorites.isEmpty
                            ? "Start adding your favorites!"
                            : "${_favorites.length} item${_favorites.length != 1 ? 's' : ''} saved",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.parchment.withValues(alpha: 0.9),
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

  // _buildFloatingParticle replaced by FloatingParticle widget
  // _buildIconButton replaced by GlassmorphicIconButton widget

  Widget _buildStatsRow(ThemeData theme, bool isDark, CartModel? cart) {
    final inCart =
        _favorites.where((f) {
          if (cart == null) return false;
          final item = cart.items.firstWhereOrNull(
            (i) => i.productVariant.id == f.productId,
          );
          // Assuming itemId is productVariant.id or similar mapping.
          // Actually checking equality with productId
          return (item?.quantity ?? 0) > 0;
        }).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            isDark,
            Icons.favorite_rounded,
            AppColors.harvestAmber,
            '${_favorites.length}',
            'Saved Items',
            onTap: () => _loadFavorites(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            isDark,
            Icons.shopping_cart_rounded,
            AppColors.deepSoilGreen,
            '$inCart',
            'In Cart',
            onTap: () => context.goNamed(AppRoute.cart.name),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    bool isDark,
    IconData icon,
    Color color,
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuantityTag(String weight, ThemeData theme, bool isDark) {
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
        weight,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(
    FavoriteModel favorite,
    int index,
    ThemeData theme,
    bool isDark,
    CartModel? cart,
  ) {
    int quantity = 0;
    if (cart != null) {
      final item = cart.items.firstWhereOrNull(
        (i) => i.productVariant.id == favorite.productId,
      );
      quantity = item?.quantity ?? 0;
    }

    final isProcessing = _processingItems.contains(favorite.productId);
    final isBeingRemoved =
        isProcessing && quantity == 0; // Simplified check for now

    return Dismissible(
      key: Key('favorite_${favorite.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeFromFavorites(favorite, index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.rawEarth,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: AppColors.parchment,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          final product = await CategoryService.fetchProductById(
            favorite.productId,
          );
          if (!mounted) return;
          context.pushNamed(
            AppRoute.productDetails.name,
            pathParameters: {'id': product.id.toString()},
            extra: product,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Image with Heart Overlay
              Stack(
                children: [
                  Hero(
                    tag: 'favorite_image_${favorite.productId}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.parchment,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: favorite.image,
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
                                Icons.image_not_supported_rounded,
                                color: theme.disabledColor,
                                size: 32,
                              ),
                        ),
                      ),
                    ),
                  ),
                  // Heart Badge
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => _removeFromFavorites(favorite, index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.rawEarth,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.rawEarth.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child:
                            isBeingRemoved
                                ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.parchment,
                                  ),
                                )
                                : const Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.parchment,
                                  size: 12,
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
                      favorite.productCategory,
                      theme,
                      isDark,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      favorite.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildQuantityTag(favorite.weight, theme, isDark),
                    const SizedBox(height: 8),
                    Text(
                      '₹${favorite.price}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.harvestAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Cart Actions
              Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        isProcessing && !isBeingRemoved
                            ? Container(
                              width: 100,
                              height: 44,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            )
                            : quantity == 0
                            ? _buildAddToCartButton(theme, favorite)
                            : _buildQuantitySelector(
                              theme,
                              isDark,
                              favorite,
                              quantity,
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(ThemeData theme, FavoriteModel favorite) {
    return GestureDetector(
      onTap: () => _handleQuantityChanged(favorite, 1),
      child: Container(
        width: 100,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.amberWarnBg,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.amberWarnBg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(
    ThemeData theme,
    bool isDark,
    FavoriteModel favorite,
    int quantity,
  ) {
    return Container(
      width: 100,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuantityButton(
            Icons.remove_rounded,
            () => _handleQuantityChanged(favorite, quantity - 1),
            theme,
            isDark,
          ),
          Text(
            '$quantity',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildQuantityButton(
            Icons.add_rounded,
            () => _handleQuantityChanged(favorite, quantity + 1),
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.parchment,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.secondary),
      ),
    );
  }

  // _buildLoadingState replaced by LoadingStateWidget

  Widget _buildErrorState(ThemeData theme) {
    final isLoginError = _error?.toLowerCase().contains('login') ?? false;

    if (isLoginError) {
      return const GuestEmptyStateWidget(
        title: 'Login to View Favorites',
        subtitle: 'Log in to see and manage your saved items.',
        icon: Icons.favorite_border_rounded,
      );
    }

    return ErrorStateWidget(
      title: 'Failed to Load Favorites',
      subtitle: _error ?? 'An error occurred while loading your favorites.',
      errorType: ErrorType.server,
      onRetry: _loadFavorites,
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600;
        final iconSize = isSmallScreen ? 60.0 : 80.0;
        final padding = isSmallScreen ? 24.0 : 32.0;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated heart container
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.9 + (_pulseAnimation.value - 1) * 0.5,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.harvestAmber.withValues(alpha: 0.15),
                          AppColors.rawEarth.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: iconSize,
                      color: AppColors.harvestAmber,
                    ),
                  ),
                ),
                SizedBox(height: padding),
                Text(
                  "Want toxin‑free food?",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 20 : 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Subscribe to it now, because it’s the clearest way\n to signal demand to your farmer.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    height: 1.5,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Switch to Categories tab (index 3)
                    final dashboardState =
                        context.findAncestorStateOfType<DashboardScreenState>();
                    dashboardState?.switchToTab(1);
                  },
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Explore Offerings'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
