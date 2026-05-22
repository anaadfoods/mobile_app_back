import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/common_widgets/animated_screen_header.dart';
import 'package:grocery_app/routes/app_routes.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _checkoutController;

  late Animation<double> _contentFade;
  late Animation<double> _checkoutSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    context.read<CartCubit>().loadCart();
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

    _checkoutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _checkoutSlide = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(parent: _checkoutController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _headerController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _checkoutController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _checkoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state is CartError) {
            SnackBarHelper.showError(context, state.message);
          } else if (state is CartSuccess) {
            if (state.error != null && state.error!.isNotEmpty) {
              SnackBarHelper.showError(context, state.error!);
            } else if (state.message != null && state.message!.isNotEmpty) {
              SnackBarHelper.showSuccess(context, state.message!);
            }
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Animated Header
                  SliverToBoxAdapter(
                    child: AnimatedScreenHeader(
                      title: "My Cart",
                      subtitle:
                          state is CartSuccess
                              ? "${state.cart.totalItems} items ready for checkout"
                              : "Your cart is empty",
                      // icon: Icons.shopping_cart_rounded,
                      showBack: true,
                      hasParticles: true,
                      height: 200,
                      animationController: _headerController,
                      actions: [
                        if (state is CartSuccess && state.cart.items.isNotEmpty)
                          GlassmorphicIconButton(
                            icon: Icons.delete_sweep_rounded,
                            iconSize: 22,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _showClearCartDialog(context);
                            },
                          ),
                      ],
                    ),
                  ),

                  // Content
                  if (state is CartLoading || state is CartInitial)
                    SliverFillRemaining(child: const LoadingStateWidget())
                  else if (state is CartError)
                    SliverFillRemaining(
                      child: _buildErrorState(theme, state.message),
                    )
                  else if (state is CartSuccess) ...[
                    if (state.cart.items.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState(theme))
                    else ...[
                      // Cart Items
                      _buildCartItemsList(theme, isDark, state.cart),

                      // Bottom padding for checkout section
                      const SliverToBoxAdapter(child: SizedBox(height: 180)),
                    ],
                  ],
                ],
              ),

              // Checkout Section (fixed at bottom)
              if (state is CartSuccess && state.cart.items.isNotEmpty)
                _buildCheckoutSection(theme, isDark, state.cart),
            ],
          );
        },
      ),
    );
  }

  // _buildFloatingParticle replaced by FloatingParticle widget
  // _buildIconButton replaced by GlassmorphicIconButton widget
  // _buildLoadingState replaced by LoadingStateWidget

  Widget _buildCartItemsList(ThemeData theme, bool isDark, CartModel cart) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = cart.items[index];
          return AnimatedBuilder(
            animation: _contentController,
            builder: (context, child) {
              final delay = index * 80;
              final progress = Curves.easeOutCubic.transform(
                ((_contentController.value * 1000) - delay).clamp(0, 300) / 300,
              );
              return Transform.translate(
                offset: Offset(30 * (1 - progress), 0),
                child: Opacity(opacity: progress.clamp(0, 1), child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnimatedCartItem(
                item: item,
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final product = await CategoryService.fetchProductById(
                    item.productVariant.id,
                  );
                  if (!mounted) return;
                  context.pushNamed(
                    AppRoute.productDetails.name,
                    pathParameters: {'id': product.id.toString()},
                  );
                },
                onQuantityChanged: (newQty) {
                  HapticFeedback.selectionClick();
                  newQty == 0
                      ? context.read<CartCubit>().removeItem(
                        item.productVariant.id,
                      )
                      : context.read<CartCubit>().updateItem(
                        item.productVariant.id,
                        newQty,
                      );
                },
                onRemove: () {
                  HapticFeedback.mediumImpact();
                  context.read<CartCubit>().removeItem(item.productVariant.id);
                },
              ),
            ),
          );
        }, childCount: cart.items.length),
      ),
    );
  }

  Widget _buildCheckoutSection(ThemeData theme, bool isDark, CartModel cart) {
    final double totalAmount =
        double.tryParse(cart.totalPrice) ??
        cart.items.fold<double>(
          0.0,
          (sum, item) => sum + (item.productVariant.finalPrice * item.quantity),
        );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _checkoutController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _checkoutSlide.value),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : AppColors.parchment,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.charcoal60 : AppColors.rawEarth12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Summary Row
                  Row(
                    children: [
                      // Items count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${cart.totalItems} items',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Total
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Amount',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.harvestAmber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // We previously had AddressSelectionScreen but the route says checkout
                        // We will route to checkout per app_router definition, passing required params if necessary
                        context.pushNamed(
                          AppRoute.address.name,
                          extra: {'cart': cart},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: AppColors.parchment,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Proceed to Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.parchment.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
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
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_sweep_rounded,
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Clear Cart'),
              ],
            ),
            content: const Text(
              'Are you sure you want to remove all items from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<CartCubit>().clearCart();
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: AppColors.parchment,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return ErrorStateWidget(
      title: 'Failed to Load Cart',
      subtitle: message,
      errorType: ErrorType.server,
      onRetry: () {
        HapticFeedback.lightImpact();
        context.read<CartCubit>().loadCart();
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
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
                // Animated Cart Icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: iconSize,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                SizedBox(height: padding),
                Text(
                  'Your Cart is Empty',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 20 : 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Looks like you haven't added anything yet.\nStart shopping to fill it up!",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    height: 1.5,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 24 : 40),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Navigate to Categories tab (index 3) instead of popping
                    final dashboardState =
                        context.findAncestorStateOfType<DashboardScreenState>();
                    if (dashboardState != null) {
                      dashboardState.switchToTab(1); // Categories tab
                    }
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Start Shopping'),
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

// Animated Cart Item Widget
class _AnimatedCartItem extends StatefulWidget {
  final CartItem item;
  final VoidCallback onTap;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _AnimatedCartItem({
    required this.item,
    required this.onTap,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<_AnimatedCartItem> createState() => _AnimatedCartItemState();
}

class _AnimatedCartItemState extends State<_AnimatedCartItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
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
                  alpha: _isPressed ? 0.12 : 0.06,
                ),
                blurRadius: _isPressed ? 16 : 8,
                offset: Offset(0, _isPressed ? 6 : 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Product Image
              Hero(
                tag: 'cart_product_${item.productVariant.id}',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        item.productVariant.productImages.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl:
                                  item.productVariant.productImages.first.image,
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
                                  ),
                            )
                            : Icon(
                              Icons.shopping_bag_outlined,
                              color: theme.disabledColor,
                              size: 32,
                            ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productVariant.productName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.productVariant.weight} ${item.productVariant.weightUnit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price
                        FittedBox(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '₹${item.productVariant.finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.harvestAmber,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Quantity Controls
                        Container(
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.darkSurfaceElevated
                                    : AppColors.parchment,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FittedBox(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildQuantityButton(
                                  theme,
                                  Icons.remove,
                                  () => widget.onQuantityChanged(
                                    item.quantity - 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _buildQuantityButton(
                                  theme,
                                  Icons.add,
                                  () => widget.onQuantityChanged(
                                    item.quantity + 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button
              Material(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _showRemoveDialog(context, theme),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 22,
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

  Widget _buildQuantityButton(
    ThemeData theme,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Remove Item'),
            content: const Text(
              'Are you sure you want to remove this item from your cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onRemove();
                  Navigator.pop(context);
                  SnackBarHelper.showSuccess(context, 'Item removed from cart');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: AppColors.parchment,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}
