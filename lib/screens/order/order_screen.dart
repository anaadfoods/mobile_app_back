import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/service_locator.dart';
import 'dart:math' as math;

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = getIt<OrderService>();
  List<Order> orders = [];
  bool isLoading = true;
  String? error;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fetchOrders();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        error = null;
      });
      final fetchedOrders = await _orderService.getOrders();
      if (!mounted) return;
      setState(() {
        orders = fetchedOrders;
        isLoading = false;
      });
      _staggerController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  // Unused methods - commented out to suppress warning
  // String _formatDate(DateTime date) {
  //   return DateFormat('MMM d, yyyy').format(date);
  // }

  // String _formatShortDate(DateTime date) {
  //   return DateFormat('MMM d').format(date);
  // }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.goNamed(AppRoute.home.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffold = Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Premium Header
            _buildAnimatedHeader(theme, isDark),
            // Content
            if (isLoading)
              const SliverFillRemaining(child: _LoadingState())
            else if (error != null)
              SliverFillRemaining(
                child: _ErrorState(error: error!, onRetry: _fetchOrders),
              )
            else if (orders.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == orders.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _buildHelpCard(theme, isDark),
                      );
                    }
                    final order = orders[index];
                    return _AnimatedOrderCard(
                      order: order,
                      index: index,
                      staggerController: _staggerController,
                      totalItems: orders.length,
                      onTap: () => _navigateToDetails(order),
                    );
                  }, childCount: orders.length + 1),
                ),
              ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goNamed(AppRoute.home.name);
      },
      child: scaffold,
    );
  }

  Widget _buildAnimatedHeader(ThemeData theme, bool isDark) {
    final activeOrders =
        orders
            .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
            .length;
    final completedOrders = orders.where((o) => o.status == 'DELIVERED').length;
    final cancelledOrders = orders.where((o) => o.status == 'CANCELLED').length;
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;

    // Calculate dynamic header height based on screen size and content
    final screenHeight = mediaQuery.size.height;
    final hasStats = !isLoading && orders.isNotEmpty;
    // Base height accounts for: status bar + back button + title + subtitle + padding
    final baseHeight = statusBarHeight + 140;
    final statsHeight = hasStats ? 44.0 : 0.0;
    final headerHeight = (baseHeight + statsHeight).clamp(
      180.0,
      math.max(180.0, screenHeight * 0.28).toDouble(),
    );

    return SliverToBoxAdapter(
      child: Container(
        constraints: BoxConstraints(minHeight: headerHeight),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [
                      AppColors.deepSoilGreen,
                      AppColors.deepSoilGreen.withValues(alpha: 0.8),
                    ]
                    : [
                      AppColors.deepSoilGreen,
                      AppColors.deepSoilGreen.withValues(alpha: 0.8),
                    ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.parchment.withValues(alpha: 0.1),
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
                  color: AppColors.parchment.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Animated Icon - position dynamically
            Positioned(
              top: statusBarHeight + 16,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.parchment.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  color: AppColors.harvestAmber,
                  size: 28,
                ),
              ),
            ),

            // Header Content
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.parchment,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleBack(context),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "My Orders",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orders.isEmpty
                          ? "Your orders will appear here"
                          : "${orders.length} order${orders.length != 1 ? 's' : ''} total",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.parchment.withValues(alpha: 0.9),
                      ),
                    ),
                    // Stats Row - scrollable to prevent overflow
                    if (hasStats) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatChip(
                              icon: Icons.local_shipping_outlined,
                              label: 'Active',
                              count: activeOrders,
                              color: AppColors.harvestAmber,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              icon: Icons.check_circle_outline,
                              label: 'Completed',
                              count: completedOrders,
                              color: AppColors.deepSoilGreen,
                            ),
                            const SizedBox(width: 8),

                            _buildStatChip(
                              icon: Icons.cancel_outlined,
                              label: 'Cancelled',
                              count: cancelledOrders,
                              color: AppColors.deepSoilGreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.parchment.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: const TextStyle(
              color: AppColors.parchment,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [
                    AppColors.deepSoilGreen.withValues(alpha: 0.2),
                    AppColors.deepSoilGreen.withValues(alpha: 0.1),
                  ]
                  : [
                    AppColors.deepSoilGreen.withValues(alpha: 0.08),
                    AppColors.deepSoilGreen.withValues(alpha: 0.04),
                  ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.deepSoilGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.deepSoilGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.deepSoilGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contact our support team for any order issues',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HelpScreen()),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.deepSoilGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: AppColors.parchment,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDetails(Order order) async {
    HapticFeedback.lightImpact();
    try {
      final orderDetails = await _orderService.getOrderById(order.id);
      if (!mounted) return;
      final result = await context.pushNamed<bool>(
        AppRoute.orderDetails.name,
        pathParameters: {'id': order.id.toString()},
        extra: orderDetails, // Passing down cached details if needed
      );
      if (result == true) {
        await _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        // Fallback: Navigate with just the ID, allowing the detail screen to fetch details with its own error boundaries.
        final result = await context.pushNamed<bool>(
          AppRoute.orderDetails.name,
          pathParameters: {'id': order.id.toString()},
        );
        if (result == true) {
          await _fetchOrders();
        }
      }
    }
  }
}

// Animated Order Card with stagger effect
class _AnimatedOrderCard extends StatelessWidget {
  final Order order;
  final int index;
  final AnimationController staggerController;
  final int totalItems;
  final VoidCallback onTap;

  const _AnimatedOrderCard({
    required this.order,
    required this.index,
    required this.staggerController,
    required this.totalItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startInterval = (index / totalItems) * 0.6;
    final endInterval = startInterval + 0.4;

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: staggerController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: staggerController,
        curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: staggerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            _ModernOrderCard(order: order, onTap: onTap),
            if (index < totalItems - 1) ...[
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Modern Order Card Design
class _ModernOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _ModernOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = _getStatusInfo(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? AppColors.charcoal.withValues(alpha: 0.3)
                      : AppColors.deepSoilGreen.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Status icon with animation
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(status.icon, color: status.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${order.orderNumber}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order.total.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.harvestAmber,
                        ),
                      ),
                      Text(
                        '${order.items.length} items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Products preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProductsPreview(context, isDark),
                  const SizedBox(height: 16),
                  // Bottom row with date and action
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(order.expectedDeliveryDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Details',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.harvestAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppColors.harvestAmber,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsPreview(BuildContext context, bool isDark) {
    final items = order.items;
    final displayItems = items.take(3).toList();
    final remainingCount = items.length - 3;

    return Row(
      children: [
        // Product images stack
        SizedBox(
          width: 80 + (displayItems.length - 1) * 20.0,
          height: 50,
          child: Stack(
            children: List.generate(displayItems.length, (index) {
              final item = displayItems[index];
              final imageUrl =
                  item.productDetails.productImages.isNotEmpty
                      ? item.productDetails.productImages[0].image
                      : null;
              return Positioned(
                left: index * 20.0,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.parchment,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.charcoal.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        imageUrl != null
                            ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    color:
                                        isDark
                                            ? AppColors.darkSurfaceElevated
                                            : AppColors.parchment,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) =>
                                      _buildPlaceholder(isDark),
                            )
                            : _buildPlaceholder(isDark),
                  ),
                ),
              );
            }),
          ),
        ),
        if (remainingCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.parchment70 : AppColors.charcoal60,
              ),
            ),
          ),
        ],
        const Spacer(),
        // First product name
        Expanded(
          flex: 2,
          child: Text(
            items.first.productDetails.productName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.parchment24 : AppColors.rawEarth26,
        size: 20,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  ({Color color, IconData icon, String label}) _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return (
          color: AppColors.deepSoilGreen,
          icon: Icons.check_circle_rounded,
          label: 'Delivered',
        );
      case 'CANCELLED':
        return (
          color: AppColors.rawEarth,
          icon: Icons.cancel_rounded,
          label: 'Cancelled',
        );
      case 'SHIPPED':
        return (
          color: AppColors.harvestAmber,
          icon: Icons.local_shipping_rounded,
          label: 'Shipped',
        );
      case 'OUT_FOR_DELIVERY':
        return (
          color: AppColors.harvestAmber,
          icon: Icons.delivery_dining_rounded,
          label: 'Out for Delivery',
        );
      case 'PLACED':
      default:
        return (
          color: AppColors.harvestAmber,
          icon: Icons.pending_rounded,
          label: 'Order Placed',
        );
    }
  }
}

// Loading State
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoading(
            isLoading: true,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.parchment,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Error State - using centralized ErrorStateWidget
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      title: 'Failed to Load Orders',
      subtitle: error,
      errorType: ErrorType.server,
      onRetry: onRetry,
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600;
        final iconSize = isSmallScreen ? 48.0 : 64.0;
        final paddingContainer = isSmallScreen ? 20.0 : 32.0;
        final paddingScreen = isSmallScreen ? 24.0 : 32.0;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(paddingScreen),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(paddingContainer),
                  decoration: BoxDecoration(
                    color: AppColors.deepSoilGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: iconSize,
                    color: AppColors.deepSoilGreen.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: paddingScreen),
                Text(
                  'The Kitchen is Empty',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 20 : 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your journey to toxin-free living begins with ICBN Food.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    height: 1.5,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),
                ElevatedButton.icon(
                  onPressed: () => context.goNamed(AppRoute.categories.name),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Start Your Journey'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: isSmallScreen ? 12 : 16,
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
