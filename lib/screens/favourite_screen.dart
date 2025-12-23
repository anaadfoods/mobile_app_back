import 'package:grocery_app/common_widgets/global_import.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  _FavouriteScreenState createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
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

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
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

  Future<void> _removeFromFavorites(FavoriteModel favorite) async {
    if (_processingItems.contains(favorite.productId)) return;

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

    return Scaffold(
      appBar: AppBar(title: const Text("My Wishlist")),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error != null
              ? _buildErrorState()
              : _favorites.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadFavorites,
                color: theme.colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppColors.spacingS,
                    horizontal: AppColors.spacingL,
                  ),
                  itemCount: _favorites.length,
                  itemBuilder:
                      (context, index) => _buildFavoriteCard(_favorites[index]),
                ),
              ),
    );
  }

  Widget _buildFavoriteCard(FavoriteModel favorite) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final quantity = _cartQuantities[favorite.productId] ?? 0;
    final isProcessing = _processingItems.contains(favorite.productId);
    final isBeingRemoved =
        isProcessing && !_cartQuantities.containsKey(favorite.productId);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppColors.spacingS),
      child: GestureDetector(
        onTap: () async {
          final product = await CategoryService.fetchProductById(
            favorite.productId,
          );
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: AppColors.animMedium),
          padding: const EdgeInsets.all(AppColors.spacingM),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppColors.radiusL),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(
                  AppColors.shadowOpacityLight,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppColors.radiusM),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppColors.radiusM),
                  child: CachedNetworkImage(
                    imageUrl: favorite.image,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => Container(
                          color:
                              isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade100,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          color:
                              isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade100,
                          child: Icon(
                            Icons.image_not_supported,
                            color: theme.disabledColor,
                            size: 32,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppColors.spacingM),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      favorite.name,
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppColors.spacingXS),
                    Text(
                      favorite.weight,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: AppColors.spacingS),
                    Text(
                      '₹${favorite.price}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppColors.spacingS),

              // Actions
              Column(
                children: [
                  // Remove Button
                  SizedBox(
                    height: 28,
                    width: 28,
                    child:
                        isBeingRemoved
                            ? Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                            : IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              icon: Icon(
                                Icons.favorite,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () => _removeFromFavorites(favorite),
                            ),
                  ),
                  const SizedBox(height: AppColors.spacingS),

                  // Cart Button
                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: AppColors.animMedium,
                    ),
                    child:
                        isProcessing && !isBeingRemoved
                            ? SizedBox(
                              width: 92,
                              height: 36,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            )
                            : quantity == 0
                            ? SizedBox(
                              width: 92,
                              height: 36,
                              child: ElevatedButton(
                                onPressed:
                                    () => _handleQuantityChanged(favorite, 1),
                                child: const Text('Add'),
                              ),
                            )
                            : SizedBox(
                              width: 92,
                              height: 36,
                              child: ItemCounterWidget(
                                amount: quantity,
                                onAmountChanged:
                                    (newAmount) => _handleQuantityChanged(
                                      favorite,
                                      newAmount,
                                    ),
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
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ShimmerLoading(
            isLoading: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(width: 70, height: 70, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 14, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 50, height: 16, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(width: 60, height: 36, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              _error ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  _error != null && _error!.toLowerCase().contains('login')
                      ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      )
                      : _loadFavorites,
              child: Text(
                _error != null && _error!.toLowerCase().contains('login')
                    ? 'Login'
                    : 'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: theme.disabledColor.withOpacity(0.5),
            ),
            const SizedBox(height: AppColors.spacingXL),
            Text(
              "Your Wishlist is Empty",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppColors.spacingM),
            Text(
              "Tap the heart on any product to save it here.",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
