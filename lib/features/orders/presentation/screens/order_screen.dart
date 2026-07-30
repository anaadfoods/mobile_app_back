import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/routes/app_routes.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../widgets/order_card.dart';
import '../widgets/order_list_states.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
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
    await context.read<OrderCubit>().fetchOrders();
    if (mounted) {
      _staggerController.forward(from: 0);
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.goNamed(AppRoute.profile.name);
    }
  }

  Future<void> _navigateToDetails(int id) async {
    HapticFeedback.lightImpact();
    final result = await context.pushNamed<bool>(
      AppRoute.orderDetails.name,
      pathParameters: {'id': id.toString()},
    );
    if (result == true) {
      _fetchOrders();
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
        child: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            int activeOrders = 0;
            int completedOrders = 0;
            int cancelledOrders = 0;
            int totalCount = 0;

            if (state is OrderSuccess) {
              totalCount = state.orders.length;
              activeOrders = state.orders
                  .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
                  .length;
              completedOrders = state.orders.where((o) => o.status == 'DELIVERED').length;
              cancelledOrders = state.orders.where((o) => o.status == 'CANCELLED').length;
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildAnimatedHeader(
                  theme,
                  isDark,
                  totalCount,
                  activeOrders,
                  completedOrders,
                  cancelledOrders,
                  state is OrderLoading,
                ),
                if (state is OrderLoading)
                  const SliverFillRemaining(child: OrderListLoadingState())
                else if (state is OrderError)
                  SliverFillRemaining(
                    child: OrderListErrorState(
                      error: state.message,
                      onRetry: _fetchOrders,
                    ),
                  )
                else if (state is OrderSuccess && state.orders.isEmpty)
                  const SliverFillRemaining(child: OrderListEmptyState())
                else if (state is OrderSuccess)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == state.orders.length) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: OrderListHelpCard(),
                            );
                          }
                          final order = state.orders[index];
                          return AnimatedOrderCard(
                            order: order,
                            index: index,
                            staggerController: _staggerController,
                            totalItems: state.orders.length,
                            onTap: () => _navigateToDetails(order.id),
                          );
                        },
                        childCount: state.orders.length + 1,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.goNamed(AppRoute.profile.name);
      },
      child: scaffold,
    );
  }

  Widget _buildAnimatedHeader(
    ThemeData theme,
    bool isDark,
    int totalCount,
    int active,
    int completed,
    int cancelled,
    bool isLoading,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final screenHeight = mediaQuery.size.height;
    final hasStats = !isLoading && totalCount > 0;
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
            colors: [
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
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      isLoading
                          ? "Loading orders..."
                          : totalCount == 0
                              ? "Your orders will appear here"
                              : "$totalCount order${totalCount != 1 ? 's' : ''} total",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.parchment.withValues(alpha: 0.9),
                      ),
                    ),
                    if (hasStats) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            OrderListStatChip(
                              icon: Icons.local_shipping_outlined,
                              label: 'Active',
                              count: active,
                              color: AppColors.harvestAmber,
                            ),
                            const SizedBox(width: 8),
                            OrderListStatChip(
                              icon: Icons.check_circle_outline,
                              label: 'Completed',
                              count: completed,
                              color: AppColors.deepSoilGreen,
                            ),
                            const SizedBox(width: 8),
                            OrderListStatChip(
                              icon: Icons.cancel_outlined,
                              label: 'Cancelled',
                              count: cancelled,
                              color: AppColors.rawEarth,
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
}
