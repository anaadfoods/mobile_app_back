import 'rfp_vegetable.dart';
import 'rfp_plan_pricing.dart';

/// A subscription tier for a farming batch.
class RfpPlan {
  final String id;
  final String name;
  final String tier; // 'standard', 'premium'
  final String description;
  final double totalPrice;
  final double? originalPrice;
  final double bookingAmount;
  final double remainingAmount;
  final double? discountPercent;
  final String? badge; // e.g. 'Best Value'
  final List<String> features;
  final String? code;
  final int selectionLimit;
  final List<RfpVegetable> availableVegetables;
  final List<RfpPlanPricing> pricings;
  final String? imageUrl;
  final int maxDeselectableCount;
  final int maxFamilies;
  final int bookedFamilyCount;
  final int slotsRemaining;
  final bool isFull;
  final String planStatus; // 'AVAILABLE', 'FULL'

  const RfpPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    required this.totalPrice,
    this.originalPrice,
    required this.bookingAmount,
    required this.remainingAmount,
    this.discountPercent,
    this.badge,
    required this.features,
    this.code,
    this.selectionLimit = 0,
    this.availableVegetables = const [],
    this.pricings = const [],
    this.imageUrl,
    this.maxDeselectableCount = 0,
    this.maxFamilies = 50,
    this.bookedFamilyCount = 0,
    this.slotsRemaining = 50,
    this.isFull = false,
    this.planStatus = 'AVAILABLE',
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > totalPrice;
  double get discountAmount => hasDiscount ? originalPrice! - totalPrice : 0;

  bool get isCuratedFixed => maxDeselectableCount <= 0;

  Set<String> get defaultVegetableIds {
    final defaults =
        availableVegetables
            .where((v) => v.isDefaultSelected)
            .map((v) => v.id)
            .toSet();
    if (defaults.isNotEmpty) return defaults;
    final limit =
        selectionLimit > 0 ? selectionLimit : availableVegetables.length;
    return availableVegetables.take(limit).map((v) => v.id).toSet();
  }

  int getDeselectedDefaultCount(Set<String> currentSelectedIds) {
    return defaultVegetableIds
        .where((id) => !currentSelectedIds.contains(id))
        .length;
  }

  int getRemainingDeselects(Set<String> currentSelectedIds) {
    if (isCuratedFixed) return 0;
    final used = getDeselectedDefaultCount(currentSelectedIds);
    final remaining = maxDeselectableCount - used;
    return remaining < 0 ? 0 : remaining;
  }

  bool canDeselectVegetable(
    String vegetableId,
    Set<String> currentSelectedIds,
  ) {
    if (!currentSelectedIds.contains(vegetableId)) return false;
    // Alternative items can always be deselected
    if (!defaultVegetableIds.contains(vegetableId)) return true;
    if (isCuratedFixed) return false;
    return getRemainingDeselects(currentSelectedIds) > 0;
  }
}
