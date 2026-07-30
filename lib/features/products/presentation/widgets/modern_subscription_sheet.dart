import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/features/products/presentation/widgets/subscription_plan_card.dart';
import 'package:grocery_app/features/products/presentation/widgets/subscription_one_time_card.dart';
import 'package:grocery_app/models/product_model.dart';
import 'package:grocery_app/models/subscription_plan_model.dart';
import 'package:grocery_app/models/plan_Search_model.dart';
import 'package:grocery_app/services/plan_search_service.dart';

class ModernSubscriptionSheet extends StatefulWidget {
  final Product product;
  final List<SubscriptionPlan> allPlans;
  final List<PlanSearchResult> availablePlansForProduct;
  final int selectedIndex;
  final int quantity;
  final int paymentOption;
  final ValueChanged<int> onPlanSelected;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<int> onPaymentOptionChanged;
  final VoidCallback onSubscribe;

  const ModernSubscriptionSheet({
    super.key,
    required this.product,
    required this.allPlans,
    required this.availablePlansForProduct,
    required this.selectedIndex,
    required this.quantity,
    required this.paymentOption,
    required this.onPlanSelected,
    required this.onQuantityChanged,
    required this.onPaymentOptionChanged,
    required this.onSubscribe,
  });

  @override
  _ModernSubscriptionSheetState createState() =>
      _ModernSubscriptionSheetState();
}

class _ModernSubscriptionSheetState extends State<ModernSubscriptionSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = AppColors.harvestAmber;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Bar
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.parchment.withValues(alpha: 0.15)
                      : AppColors.charcoal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Title Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Subscription',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.pureWhite : AppColors.charcoal,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.productName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildQuantitySelector(theme, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Scrollable Options List
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // One-Time Purchase option
                      SubscriptionOneTimeCard(
                        product: widget.product,
                        isSelected: widget.selectedIndex == -1,
                        quantity: widget.quantity,
                        onPlanSelected: widget.onPlanSelected,
                      ),
                      const SizedBox(height: 16),

                      // Subscription Plans list
                      ...widget.allPlans.mapIndexed((index, plan) {
                        final planData = widget.availablePlansForProduct.firstWhereOrNull(
                          (p) => p.planName == plan.name,
                        );
                        final isEnabled = planData != null;
                        final isSelected = widget.selectedIndex == index;

                        if (!isEnabled) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SubscriptionPlanCard(
                            plan: plan,
                            planData: planData,
                            isSelected: isSelected,
                            isEnabled: isEnabled,
                            index: index,
                            quantity: widget.quantity,
                            paymentOption: widget.paymentOption,
                            onPlanSelected: widget.onPlanSelected,
                            onPaymentOptionChanged: widget.onPaymentOptionChanged,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Subscribe / Continue Button
              _buildBottomButton(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.charcoal.withValues(alpha: 0.3)
            : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.parchment.withValues(alpha: 0.1) : AppColors.charcoal12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQtyButton(
            icon: Icons.remove,
            onPressed: widget.quantity > 1
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onQuantityChanged(widget.quantity - 1);
                  }
                : null,
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${widget.quantity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.pureWhite : AppColors.charcoal,
              ),
            ),
          ),
          _buildQtyButton(
            icon: Icons.add,
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onQuantityChanged(widget.quantity + 1);
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 16,
            color: onPressed == null
                ? Colors.grey
                : (isDark ? AppColors.pureWhite : AppColors.charcoal),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(ThemeData theme, bool isDark) {
    final isSelected = widget.selectedIndex != -2; // -2 would mean unselected
    final accentColor = AppColors.harvestAmber;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.parchment,
        border: Border.all(
          color: isDark ? AppColors.parchment.withValues(alpha: 0.05) : AppColors.charcoal12,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: _glowAnimation.value * 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: ElevatedButton(
            onPressed: isSelected ? widget.onSubscribe : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepSoilGreen,
              foregroundColor: AppColors.parchment,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              widget.selectedIndex == -1 ? 'Proceed to Order' : 'Subscribe Now',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
