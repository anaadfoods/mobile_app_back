import 'package:collection/collection.dart';
import 'package:grocery_app/common_widgets/global_import.dart';


class ProductBottomActionBar extends StatelessWidget {
  final Product product;
  final List<SubscriptionPlan> allPlans;
  final List<PlanSearchResult> availablePlansForProduct;
  final Function(int qty) onQuantityChanged;
  final Function(int initialPlanIndex, int initialPlanId) onShowSubscriptionSelectionSheet;

  const ProductBottomActionBar({
    super.key,
    required this.product,
    required this.allPlans,
    required this.availablePlansForProduct,
    required this.onQuantityChanged,
    required this.onShowSubscriptionSelectionSheet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        bottomPadding > 0 ? bottomPadding : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 55,
        child: !product.isActive || !product.isInStock
            ? _buildDisabledActionBar(isDark)
            : BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  int cartQuantity = 0;
                  if (state is CartSuccess) {
                    final cartItem = state.cart.items.firstWhereOrNull(
                      (item) => item.productVariant.id == product.id,
                    );
                    cartQuantity = cartItem?.quantity ?? 0;
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      final slideAnimation = Tween<Offset>(
                        begin: const Offset(0.0, 0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOutCubic,
                        ),
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: cartQuantity == 0
                        ? _buildAddToCartBar(context, key: const ValueKey('addToCartBar'))
                        : _buildQuantitySelectorBar(
                            context,
                            key: const ValueKey('quantitySelectorBar'),
                            quantity: cartQuantity,
                          ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDisabledActionBar(bool isDark) {
    final label = !product.isActive ? 'Currently Unavailable' : 'Out of Stock';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: isDark
              ? AppColors.pureWhite.withValues(alpha: 0.08)
              : AppColors.charcoal.withValues(alpha: 0.08),
          disabledForegroundColor: isDark
              ? AppColors.parchment.withValues(alpha: 0.3)
              : AppColors.charcoal.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAddToCartBar(BuildContext context, {required Key key}) {
    return Row(
      key: key,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is Unauthenticated) {
                GuestAuthHelper.showGuestLoginBottomSheet(
                  context,
                  title: 'Login Required',
                  subtitle: 'Please log in to add items to your cart.',
                );
                return;
              }
              onQuantityChanged(1);
            },
            icon: const Icon(Icons.shopping_cart_outlined, size: 20),
            label: const Text(
              "Add to Cart",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.harvestAmber,
              side: const BorderSide(color: AppColors.harvestAmber),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is Unauthenticated) {
                GuestAuthHelper.showGuestLoginBottomSheet(
                  context,
                  title: 'Login Required',
                  subtitle: 'Please log in to purchase items.',
                );
                return;
              }
              bool hasSubscriptions = availablePlansForProduct.isNotEmpty;
              if (hasSubscriptions && allPlans.isNotEmpty) {
                int maxDurationIndex = -1;
                int maxDuration = -1;

                for (int i = 0; i < allPlans.length; i++) {
                  final isAvailable = availablePlansForProduct.any(
                    (p) => p.planName == allPlans[i].name,
                  );
                  if (isAvailable && allPlans[i].durationMonths > maxDuration) {
                    maxDuration = allPlans[i].durationMonths;
                    maxDurationIndex = i;
                  }
                }

                if (maxDurationIndex != -1) {
                  onShowSubscriptionSelectionSheet(maxDurationIndex, allPlans[maxDurationIndex].id);
                } else {
                  onShowSubscriptionSelectionSheet(-1, -1);
                }
              } else {
                onShowSubscriptionSelectionSheet(-1, -1);
              }
            },
            icon: const Icon(
              Icons.shopping_bag_rounded,
              size: 20,
              color: AppColors.pureWhite,
            ),
            label: const Text(
              "Commit & Save",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.pureWhite,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.harvestAmber,
              shadowColor: AppColors.harvestAmber.withValues(alpha: 0.4),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelectorBar(BuildContext context, {required Key key, required int quantity}) {
    final theme = Theme.of(context);
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () {
              context.go('/cart');
            },
            icon: const Icon(Icons.shopping_cart_checkout, size: 20),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "View Cart",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              side: const BorderSide(color: AppColors.harvestAmber),
              foregroundColor: AppColors.harvestAmber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: theme.colorScheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onQuantityChanged(0),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ModernQuantitySelector(
          quantity: quantity,
          onChanged: onQuantityChanged,
          minQuantity: 0,
        ),
      ],
    );
  }
}
