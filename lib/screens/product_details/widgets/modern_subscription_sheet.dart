import 'package:grocery_app/common_widgets/global_import.dart';

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
  State<ModernSubscriptionSheet> createState() =>
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
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                // Animated glow at top
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(
                                alpha: _glowAnimation.value * 0.3,
                              ),
                              accentColor.withValues(
                                alpha: _glowAnimation.value * 0.1,
                              ),
                              AppColors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- FIXED HEADER SECTION ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        children: [
                          // Handle bar with glow
                          Center(
                            child: AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  width: 48,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accentColor.withValues(alpha: 0.3),
                                        accentColor.withValues(alpha: 0.6),
                                        accentColor.withValues(alpha: 0.3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: _glowAnimation.value * 0.5,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Header Title
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.deepSoilGreen,
                                      AppColors.successGreen,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.deepSoilGreen.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.sell_rounded,
                                  color: AppColors.pureWhite,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choose Your Order',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'One-time buy or subscribe to save every month.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.hintColor,
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // --- SCROLLABLE MIDDLE SECTION ---
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // One-Time Purchase Option
                            _buildOneTimePurchaseCard(
                              context,
                              theme,
                              isDark,
                              widget.selectedIndex == -1,
                            ),
                            const SizedBox(height: 16),

                            // Styled separator
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.transparent,
                                          isDark
                                              ? AppColors.parchment.withValues(
                                                alpha: 0.12,
                                              )
                                              : AppColors.charcoal12,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 13,
                                        color: AppColors.harvestAmber,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'OR SUBSCRIBE & SAVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.harvestAmber,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 13,
                                        color: AppColors.harvestAmber,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          isDark
                                              ? AppColors.parchment.withValues(
                                                alpha: 0.12,
                                              )
                                              : AppColors.charcoal12,
                                          AppColors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Plan Cards
                            ...List.generate(widget.allPlans.length, (index) {
                              final plan = widget.allPlans[index];
                              final planData = widget.availablePlansForProduct
                                  .firstWhere(
                                    (p) => p.planName == plan.name,
                                    orElse:
                                        () => PlanSearchResult(
                                          planId: 0,
                                          planName: '',
                                          discountedPrice: 0,
                                          discountPercentage: 0,
                                        ),
                                  );
                              final isEnabled = planData.discountedPrice > 0;
                              final isSelected = widget.selectedIndex == index;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildModernPlanCard(
                                  context,
                                  theme,
                                  isDark,
                                  plan,
                                  planData,
                                  isSelected,
                                  isEnabled,
                                  index,
                                ),
                              );
                            }),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // --- FIXED FOOTER SECTION ---
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.darkSurface
                                : AppColors.parchment,
                        border: Border(
                          top: BorderSide(
                            color:
                                isDark
                                    ? AppColors.parchment.withValues(
                                      alpha: 0.08,
                                    )
                                    : AppColors.charcoal12,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Quantity Section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppColors.charcoal87
                                        : AppColors.pureWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? AppColors.rawEarth26
                                          : AppColors.charcoal12,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shopping_basket_rounded,
                                    color: accentColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Monthly Quantity',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          'How many do you need per month?',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ModernQuantitySelector(
                                    quantity: widget.quantity,
                                    onChanged: widget.onQuantityChanged,
                                    accentColor: accentColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Subscribe Button
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                            child: ModernBottomSheetButton(
                              label:
                                  widget.selectedIndex == -1
                                      ? 'Buy Now'
                                      : 'Subscribe Now',
                              icon:
                                  widget.selectedIndex == -1
                                      ? Icons.shopping_bag_rounded
                                      : Icons.rocket_launch_rounded,
                              onTap: widget.onSubscribe,
                              color: accentColor,
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
      ),
    );
  }

  Widget _buildModernPlanCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SubscriptionPlan plan,
    PlanSearchResult planData,
    bool isSelected,
    bool isEnabled,
    int index,
  ) {
    final accentColor = AppColors.harvestAmber;

    return GestureDetector(
      onTap:
          isEnabled
              ? () {
                HapticFeedback.selectionClick();
                widget.onPlanSelected(index);
              }
              : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withValues(alpha: 0.85)],
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark ? AppColors.darkMintGreen : AppColors.pureWhite),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? accentColor.withValues(alpha: 0.5)
                    : (isDark ? AppColors.rawEarth26 : AppColors.charcoal12),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
        ),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected
                              ? AppColors.pureWhite.withValues(alpha: 0.2)
                              : AppColors.transparent,
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.pureWhite
                                : (isDark
                                    ? AppColors.parchment54
                                    : AppColors.charcoal38),
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.pureWhite,
                            )
                            : null,
                  ),
                  const SizedBox(width: 14),

                  // Plan info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color:
                                isSelected
                                    ? AppColors.pureWhite
                                    : (isDark ? AppColors.pureWhite : null),
                            fontWeight:
                                (isDark && !isSelected)
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.durationMonths} months • ${planData.discountPercentage.toStringAsFixed(0)}% off',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isSelected
                                    ? AppColors.pureWhite.withValues(alpha: 0.7)
                                    : (isDark
                                        ? AppColors.parchment70
                                        : theme.hintColor),
                            fontWeight:
                                (isDark && !isSelected)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isEnabled ? '₹${planData.discountedPrice.toStringAsFixed(0)}' : 'Unavailable',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected
                                  ? AppColors.pureWhite
                                  : AppColors.harvestAmber,
                        ),
                      ),
                      if (isEnabled)
                        Text(
                          plan.durationMonths == 1 ? '/one month' : '/month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                isSelected
                                    ? AppColors.pureWhite.withValues(alpha: 0.6)
                                    : (isDark
                                        ? AppColors.parchment70
                                        : theme.hintColor),
                            fontWeight:
                                (isDark && !isSelected)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Expanded content when selected
              if (isSelected) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceRowWithQuantity(
                        'Total (${plan.durationMonths}mo × ${widget.quantity})',
                        planData.discountedPrice *
                            plan.durationMonths *
                            widget.quantity,
                      ),
                      const SizedBox(height: 8),
                      if (widget.paymentOption == 0)
                        _buildPriceRowWithQuantity(
                          'Pay Now',
                          planData.discountedPrice *
                              plan.durationMonths *
                              widget.quantity,
                        )
                      else
                        _buildPriceRowWithQuantity(
                          'Installment (${plan.installmentFrequencyMonths}mo)',
                          planData.discountedPrice *
                              plan.installmentFrequencyMonths *
                              widget.quantity,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Payment options
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Text(
                      'Payment:',
                      style: TextStyle(
                        color: AppColors.parchment70,
                        fontSize: 13,
                      ),
                    ),
                    _buildPaymentChip('One Time', 0),
                    if (plan.allowsInstallments)
                      _buildPaymentChip('Installment', 1),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRowWithQuantity(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.parchment70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppColors.amberWarnBg,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentChip(String label, int value) {
    final isSelected = widget.paymentOption == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onPaymentOptionChanged(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.pureWhite.withValues(alpha: 0.25)
                  : AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.pureWhite.withValues(
              alpha: isSelected ? 0.5 : 0.3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: AppColors.pureWhite,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneTimePurchaseCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    bool isSelected,
  ) {
    final accentColor = AppColors.harvestAmber;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onPlanSelected(-1); // -1 indicates One-Time Purchase
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accentColor, accentColor.withValues(alpha: 0.85)],
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.pureWhite),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? accentColor.withValues(alpha: 0.5)
                    : (isDark
                        ? AppColors.parchment.withValues(alpha: 0.1)
                        : AppColors.charcoal12),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: AppColors.charcoal.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected
                            ? AppColors.pureWhite.withValues(alpha: 0.2)
                            : AppColors.transparent,
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.pureWhite
                              : (isDark
                                  ? AppColors.parchment54
                                  : AppColors.charcoal38),
                      width: 2,
                    ),
                  ),
                  child:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.pureWhite,
                          )
                          : null,
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One-Time Purchase',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.pureWhite : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Single order, no commitment',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isSelected
                                  ? AppColors.pureWhite.withValues(alpha: 0.7)
                                  : theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Text(
                  '₹${widget.product.finalPrice.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected
                            ? AppColors.pureWhite
                            : AppColors.harvestAmber,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildPriceRowWithQuantity(
                  'Total (1 time × ${widget.quantity})',
                  widget.product.finalPrice * widget.quantity,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
