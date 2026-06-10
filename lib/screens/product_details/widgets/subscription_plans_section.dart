import 'package:grocery_app/common_widgets/global_import.dart';

class SubscriptionPlansSection extends StatelessWidget {
  final Product product;
  final bool isLoadingPlans;
  final List<SubscriptionPlan> allPlans;
  final List<PlanSearchResult> availablePlansForProduct;
  final int? selectedPlanId;
  final ValueChanged<int?> onPlanSelected;
  final Function(int initialPlanId, int initialPlanIndex) onShowSubscriptionSelectionSheet;

  const SubscriptionPlansSection({
    super.key,
    required this.product,
    required this.isLoadingPlans,
    required this.allPlans,
    required this.availablePlansForProduct,
    required this.selectedPlanId,
    required this.onPlanSelected,
    required this.onShowSubscriptionSelectionSheet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoadingPlans) {
      return _buildPlansSkeleton();
    }
    if (availablePlansForProduct.isEmpty || allPlans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Subscription Plans",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.parchment : AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(allPlans.length > 4 ? 4 : allPlans.length, (index) {
                final plan = allPlans[index];

                final availablePlanData = availablePlansForProduct.firstWhere(
                  (p) => p.planName == plan.name,
                  orElse: () => PlanSearchResult(
                    planId: 0,
                    planName: '',
                    discountPercentage: 0.0,
                    discountedPrice: 0.0,
                  ),
                );

                final bool isEnabled = availablePlanData.planId != 0;
                final bool isSelected = selectedPlanId == availablePlanData.planId;

                return GestureDetector(
                  onTap: isEnabled
                      ? () {
                          onPlanSelected(availablePlanData.planId);
                          onShowSubscriptionSelectionSheet(availablePlanData.planId, index);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.deepSoilGreen,
                                AppColors.successGreen,
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : (isDark
                              ? AppColors.darkMintGreen
                              : AppColors.pureWhite),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.deepSoilGreen
                            : (isDark
                                ? AppColors.parchment.withValues(alpha: 0.1)
                                : AppColors.charcoal12),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.deepSoilGreen.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Opacity(
                      opacity: isEnabled ? 1.0 : 0.4,
                      child: Column(
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.pureWhite
                                  : (isDark ? AppColors.pureWhite : AppColors.pureBlack),
                              fontWeight: (isDark && !isSelected)
                                  ? FontWeight.w900
                                  : FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                "₹${availablePlanData.discountedPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isSelected ? AppColors.pureWhite : AppColors.harvestAmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.pureWhite.withValues(alpha: 0.2)
                                      : AppColors.harvestAmber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Save ${availablePlanData.discountPercentage.toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? AppColors.pureWhite : AppColors.harvestAmber,
                                    fontWeight: FontWeight.bold,
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
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.rawEarth12,
      highlightColor: AppColors.parchment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.rawEarth12,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.rawEarth12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
