import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/animated_screen_header.dart';
import 'package:grocery_app/common_widgets/error_state_widget.dart';
import 'package:grocery_app/common_widgets/guest_login_prompt.dart';
import 'package:grocery_app/common_widgets/loading_state_widget.dart';
import 'package:grocery_app/common_widgets/glassmorphic_icon_button.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/models/cart_model.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/services/product_service.dart';

import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_checkout_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with TickerProviderStateMixin {
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
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Unauthenticated) {
            return const GuestEmptyStateWidget(
              title: 'Login to View Cart',
              subtitle: 'Please log in or sign up to see your cart and complete checkout.',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return BlocConsumer<CartCubit, CartState>(
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
                      SliverToBoxAdapter(
                        child: AnimatedScreenHeader(
                          title: "My Cart",
                          subtitle: state is CartSuccess
                              ? "${state.cart.totalItems} items ready for checkout"
                              : "Want toxin‑free food?",
                          showBack: true,
                          hasParticles: true,
                          animationController: _headerController,
                          actions: [
                            const Icon(
                              Icons.shopping_cart_rounded,
                              color: AppColors.parchment,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
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

                      if (state is CartLoading || state is CartInitial)
                        const SliverFillRemaining(child: LoadingStateWidget())
                      else if (state is CartError)
                        SliverFillRemaining(
                          child: _buildErrorState(theme, state.message),
                        )
                      else if (state is CartSuccess) ...[
                        if (state.cart.items.isEmpty)
                          SliverFillRemaining(child: _buildEmptyState(theme))
                        else ...[
                          _buildCartItemsList(theme, isDark, state.cart),
                          SliverPadding(
                            padding: EdgeInsets.only(
                              bottom: 168.0 + MediaQuery.paddingOf(context).bottom,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),

                  if (state is CartSuccess && state.cart.items.isNotEmpty)
                    CartCheckoutBar(cart: state.cart, slideAnimation: _checkoutSlide),
                ],
              );
            },
          );
        },
      ),
    );
  }

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
              child: CartItemCard(
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
                      ? context.read<CartCubit>().removeItem(item.productVariant.id)
                      : context.read<CartCubit>().updateItem(item.productVariant.id, newQty);
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
                  "Want toxin‑free food?",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 20 : 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Subscribe to it now, because it’s the clearest way\nto signal demand to your farmer.",
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
                    context.go('/products');
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
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
