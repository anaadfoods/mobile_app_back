import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  _FavouriteScreenState createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FavoriteStateService _favoriteStateService = FavoriteStateService();
  final CartService _cartService = CartService();

  List<FavoriteModel> _favorites = [];
  Map<int, int> _cartQuantities = {};
  final Set<int> _processingItems = {};
  bool _isLoading = true;
  String? _error;
  bool _isUpdatingInternally = false;

  StreamSubscription? _authSubscription;
  StreamSubscription? _favoriteSubscription;

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _particleController;
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

    _authSubscription = AuthService.authStateChanges.listen((isLoggedIn) {
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

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

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
    _particleController.dispose();
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
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Please login to view favorites';
          });
        }
        return;
      }

      final results = await Future.wait([
        _authService.getFavorites(),
        _cartService.getCart(),
      ]);

      if (!mounted) return;

      final favResult = results[0] as Map<String, dynamic>;
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

      final cart = results[1] as CartModel?;
      if (cart != null) {
        setState(() {
          _cartQuantities = {
            for (var i in cart.items) i.productVariant.id: i.quantity,
          };
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromFavorites(FavoriteModel favorite, int index) async {
    if (_processingItems.contains(favorite.productId)) return;

    HapticFeedback.mediumImpact();

    final originalIndex = _favorites.indexWhere((f) => f.id == favorite.id);
    if (originalIndex == -1) return;

    setState(() {
      _processingItems.add(favorite.productId);
      _isUpdatingInternally = true;
      _favorites.removeAt(originalIndex);
    });

    try {
      final result = await _authService.toggleFavorite(favorite.productId);
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

  Future<void> _handleQuantityChanged(
    FavoriteModel favorite,
    int newQuantity,
  ) async {
    if (_processingItems.contains(favorite.productId)) return;
    
    HapticFeedback.selectionClick();
    setState(() => _processingItems.add(favorite.productId));

    final oldQuantity = _cartQuantities[favorite.productId] ?? 0;
    setState(() => _cartQuantities[favorite.productId] = newQuantity);

    try {
      if (newQuantity > 0 && oldQuantity == 0) {
        await _cartService.addToCart(favorite.productId, newQuantity);
        if (mounted) {
          SnackBarHelper.showSuccess(context, '${favorite.name} added to cart');
        }
      } else if (newQuantity == 0 && oldQuantity > 0) {
        await _cartService.removeFromCart(favorite.productId);
        if (mounted) {
          SnackBarHelper.showInfo(
            context,
            '${favorite.name} removed from cart',
          );
        }
      } else if (newQuantity > 0) {
        await _cartService.addToCart(favorite.productId, newQuantity);
      }
    } catch (e) {
      setState(() => _cartQuantities[favorite.productId] = oldQuantity);

      final errorMessage = e.toString();
      final backendMessageMatch = RegExp(
        r'"message"\s*:\s*"([^"]+)"',
      ).firstMatch(errorMessage);
      final displayMessage =
          backendMessageMatch != null
              ? backendMessageMatch.group(1)
              : 'Failed to update cart. Please try again.';

      SnackBarHelper.showError(context, displayMessage!);
    } finally {
      if (mounted) setState(() => _processingItems.remove(favorite.productId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Animated Header
          _buildAnimatedHeader(theme, isDark),

          // Content
          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingState(theme, isDark))
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
                      _buildStatsRow(theme, isDark),
                      const SizedBox(height: 20),

                      // Favorites List
                      ...List.generate(_favorites.length, (index) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 400 + (index * 80)),
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
      ),
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
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
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink.shade400,
                Colors.pink.shade500,
                Colors.red.shade400,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Floating Particles
              ...List.generate(10, (index) => _buildFloatingParticle(index)),

              // Decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),

              // Animated Heart
              Positioned(
                top: 60,
                right: 30,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
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
                      // Back Button
                      _buildIconButton(
                        Icons.arrow_back_ios_new_rounded,
                        () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      // Title
                      Text(
                        "My Wishlist",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _favorites.isEmpty
                            ? "Start adding your favorites!"
                            : "${_favorites.length} item${_favorites.length != 1 ? 's' : ''} saved",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
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

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 8;
    final startX = random.nextDouble() * 400;
    final startY = random.nextDouble() * 200;
    final duration = 10 + random.nextInt(10);

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value * duration) % 1.0;
        final x = startX + math.sin(progress * math.pi * 2 + index) * 25;
        final y = startY + math.cos(progress * math.pi * 2 + index) * 15;
        final opacity = 0.1 + (math.sin(progress * math.pi * 2) * 0.15);

        return Positioned(
          left: x,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(opacity.clamp(0.05, 0.3)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    final inCart = _favorites.where((f) => (_cartQuantities[f.productId] ?? 0) > 0).length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            isDark,
            Icons.favorite_rounded,
            Colors.pink,
            '${_favorites.length}',
            'Saved Items',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme,
            isDark,
            Icons.shopping_cart_rounded,
            Colors.green,
            '$inCart',
            'In Cart',
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
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
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
              color: color.withOpacity(0.15),
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
    );
  }

  Widget _buildFavoriteCard(
    FavoriteModel favorite,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    final quantity = _cartQuantities[favorite.productId] ?? 0;
    final isProcessing = _processingItems.contains(favorite.productId);
    final isBeingRemoved =
        isProcessing && !_cartQuantities.containsKey(favorite.productId);

    return Dismissible(
      key: Key('favorite_${favorite.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeFromFavorites(favorite, index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
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
          Navigator.push(
            context,
            AnimatedTransitions.slideFromRight(
              ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
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
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: favorite.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
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
                          color: Colors.red.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: isBeingRemoved
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
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
                    Text(
                      favorite.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (favorite.weight.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          favorite.weight,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${favorite.price}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
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
                    child: isProcessing && !isBeingRemoved
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
              theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
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
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
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
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
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
          color: isDark ? Colors.grey.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerLoading(
              isLoading: true,
              child: Container(
                height: 112,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    final isLoginError = _error?.toLowerCase().contains('login') ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLoginError ? Icons.lock_outline_rounded : Icons.cloud_off_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isLoginError ? 'Login Required' : 'Oops!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoginError
                  ? () => Navigator.push(
                        context,
                        AnimatedTransitions.slideFromBottom(const LoginScreen()),
                      )
                  : _loadFavorites,
              icon: Icon(isLoginError ? Icons.login_rounded : Icons.refresh_rounded),
              label: Text(isLoginError ? 'Login' : 'Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.pink.withOpacity(0.15),
                      Colors.red.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 80,
                  color: Colors.pink.shade300,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Your Wishlist is Empty",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Browse products and tap the heart icon\nto save your favorites here!",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Products'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
