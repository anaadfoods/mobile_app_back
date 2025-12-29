import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _particleController;
  late AnimationController _checkoutController;

  late Animation<double> _headerSlide;
  late Animation<double> _headerFade;
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

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _checkoutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _headerSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
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
    _particleController.dispose();
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
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Animated Header
                  _buildAnimatedHeader(theme, isDark, state),

                  // Content
                  if (state is CartLoading || state is CartInitial)
                    SliverFillRemaining(child: _buildLoadingState(theme))
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
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 180),
                      ),
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

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark, CartState state) {
    int itemCount = 0;
    if (state is CartSuccess) {
      itemCount = state.cart.totalItems;
    }

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _headerController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _headerSlide.value),
            child: Opacity(
              opacity: _headerFade.value,
              child: child,
            ),
          );
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.85),
                isDark
                    ? theme.colorScheme.primary.withOpacity(0.7)
                    : Colors.green.shade400,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
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
                top: -30,
                right: -30,
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
                left: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
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
                      // Top Row with Back Button and Clear
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildIconButton(
                            Icons.arrow_back_ios_new_rounded,
                            () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                          ),
                          if (state is CartSuccess &&
                              state.cart.items.isNotEmpty)
                            _buildIconButton(
                              Icons.delete_sweep_rounded,
                              () {
                                HapticFeedback.mediumImpact();
                                _showClearCartDialog(context);
                              },
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Title Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "My Cart",
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  itemCount > 0
                                      ? "$itemCount items ready for checkout"
                                      : "Your cart is empty",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 6;
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
              color: Colors.white.withOpacity(opacity.clamp(0.05, 0.25)),
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

  Widget _buildCartItemsList(ThemeData theme, bool isDark, CartModel cart) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = cart.items[index];
            return AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                final delay = index * 80;
                final progress = Curves.easeOutCubic.transform(
                  ((_contentController.value * 1000) - delay).clamp(0, 300) /
                      300,
                );
                return Transform.translate(
                  offset: Offset(30 * (1 - progress), 0),
                  child: Opacity(
                    opacity: progress.clamp(0, 1),
                    child: child,
                  ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailsScreen(product: product),
                      ),
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
                    context.read<CartCubit>().removeItem(
                          item.productVariant.id,
                        );
                  },
                ),
              ),
            );
          },
          childCount: cart.items.length,
        ),
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
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.15),
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
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
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
                          color: theme.colorScheme.primary.withOpacity(0.1),
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
                              color: theme.colorScheme.primary,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddressSelectionScreen(cart: cart),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
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
                              color: Colors.white.withOpacity(0.2),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
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
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.hintColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CartCubit>().clearCart();
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
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

  Widget _buildLoadingState(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surface.withOpacity(0.5),
      highlightColor: theme.colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<CartCubit>().loadCart();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Cart Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Cart is Empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Looks like you haven't added anything yet.\nStart shopping to fill it up!",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
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
              color: _isPressed
                  ? theme.colorScheme.primary.withOpacity(0.5)
                  : isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
              width: _isPressed ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(_isPressed ? 0.12 : 0.06),
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
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: item.productVariant.productImages.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl:
                                item.productVariant.productImages.first.image,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₹${item.productVariant.finalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Quantity Controls
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${item.quantity}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button
              Material(
                color: theme.colorScheme.error.withOpacity(0.1),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.hintColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onRemove();
              Navigator.pop(context);
              SnackBarHelper.showSuccess(context, 'Item removed from cart');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
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
