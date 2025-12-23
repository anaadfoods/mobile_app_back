import 'package:grocery_app/common_widgets/global_import.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CartCubit>().loadCart();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              if (state is CartSuccess && state.cart.items.isNotEmpty) {
                return IconButton(
                  onPressed: () => context.read<CartCubit>().clearCart(),
                  icon: const Icon(Icons.delete_outline),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CartCubit, CartState>(
        listener: (context, state) {
          if (state is CartError) {
            SnackBarHelper.showError(context, state.message);
          } else if (state is CartSuccess && state.message != null) {
            // SnackBarHelper.showSuccess(context, state.message!);
          }
        },
        builder: (context, state) {
          if (state is CartLoading || state is CartInitial) {
            return _buildLoadingState();
          }
          if (state is CartError) {
            return _buildErrorState(state.message);
          }
          if (state is CartSuccess) {
            if (state.cart.items.isEmpty) {
              return _buildEmptyState();
            }
            return _buildCartList(state.cart);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildCartList(CartModel cart) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => context.read<CartCubit>().loadCart(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () async {
                      final product = await CategoryService.fetchProductById(
                        item.productVariant.id,
                      );
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                    child: ChartItemWidget(
                      item: item,
                      onQuantityChanged: (newQty) {
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
                        context.read<CartCubit>().removeItem(
                          item.productVariant.id,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (cart.items.isNotEmpty) _buildCheckoutSection(cart),
      ],
    );
  }

  Widget _buildCheckoutSection(CartModel cart) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final double totalAmount =
        double.tryParse(cart.totalPrice) ??
        cart.items.fold(
          0.0,
          (sum, item) => sum + (item.productVariant.finalPrice * item.quantity),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: AppColors.animMedium),
      padding: const EdgeInsets.all(AppColors.spacingXL),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppColors.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(AppColors.shadowOpacityMedium),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Divider handle for visual hint
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppColors.spacingL),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items:',
                  style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.totalItems}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppColors.spacingM),
            Container(
              padding: const EdgeInsets.all(AppColors.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    colorScheme.primary.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppColors.radiusM),
                border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount:', style: textTheme.titleMedium),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddressSelectionScreen(cart: cart),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Proceed to Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: 5,
      itemBuilder:
          (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ShimmerLoading(
              isLoading: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppColors.radiusM),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: theme.splashColor,
                        borderRadius: BorderRadius.circular(AppColors.radiusS),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 20,
                            color: theme.splashColor,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 16,
                            color: theme.splashColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppColors.spacingXL),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: AppColors.spacingXL),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: AppColors.spacingS),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppColors.spacingXXL),
            ElevatedButton.icon(
              onPressed: () => context.read<CartCubit>().loadCart(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppColors.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppColors.spacingXXL),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 72,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppColors.spacingXL),
            Text('Your Cart is Empty', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppColors.spacingS),
            Text(
              "Looks like you haven't added anything yet.\nStart shopping to fill it up!",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppColors.spacingXXL),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Start Shopping'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
