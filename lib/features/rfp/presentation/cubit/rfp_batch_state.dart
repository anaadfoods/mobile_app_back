import 'package:equatable/equatable.dart';
import '../../domain/entities/rfp_batch.dart';
import '../../domain/entities/rfp_plan.dart';
import '../../domain/entities/rfp_patch.dart';
import '../../domain/entities/rfp_patch_config.dart';
import '../../domain/entities/rfp_pricing.dart';
import '../../domain/entities/rfp_plan_pricing.dart';

/// Configuration for an individually selected plan within a batch.
class RfpPlanConfig extends Equatable {
  final String planId;
  final RfpPlanPricing? selectedPricing;
  final Set<String> selectedVegetableIds;
  final int selectedFrequency;
  final Set<int> selectedDeliveryDays;
  final bool isConfigured;

  const RfpPlanConfig({
    required this.planId,
    this.selectedPricing,
    this.selectedVegetableIds = const {},
    this.selectedFrequency = 1,
    this.selectedDeliveryDays = const {},
    this.isConfigured = false,
  });

  RfpPlanConfig copyWith({
    String? planId,
    RfpPlanPricing? selectedPricing,
    Set<String>? selectedVegetableIds,
    int? selectedFrequency,
    Set<int>? selectedDeliveryDays,
    bool? isConfigured,
  }) {
    return RfpPlanConfig(
      planId: planId ?? this.planId,
      selectedPricing: selectedPricing ?? this.selectedPricing,
      selectedVegetableIds: selectedVegetableIds ?? this.selectedVegetableIds,
      selectedFrequency: selectedFrequency ?? this.selectedFrequency,
      selectedDeliveryDays: selectedDeliveryDays ?? this.selectedDeliveryDays,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  @override
  List<Object?> get props => [
    planId,
    selectedPricing,
    selectedVegetableIds,
    selectedFrequency,
    selectedDeliveryDays,
    isConfigured,
  ];
}

/// State for the RFP Batch Storefront & Plan Configurator.
class RfpBatchState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<RfpBatch> batches;
  final RfpBatch? selectedBatch;
  final List<RfpPlan> plans;
  final RfpPlan? selectedPlan;
  final List<RfpPatch> patches;
  final Set<String> selectedPatchIds;
  final Map<String, RfpPatchConfig> patchConfigs;
  final RfpPricing? pricing;
  final String selectedLocationId;
  final String selectedCityName;

  // ─── Multi-Plan Selection & Configurator Fields ─────────────────────────
  /// Set of all plan IDs selected by user via tick/checkbox.
  final Set<String> selectedPlanIds;

  /// Per-plan configuration (selected variant, vegetables, delivery days).
  final Map<String, RfpPlanConfig> planConfigurations;

  /// Vegetable IDs currently selected for the active modal plan.
  final Set<String> selectedVegetableIds;

  /// The pricing variant chosen in modal.
  final RfpPlanPricing? selectedPricingVariant;

  /// Delivery frequency: 1 or 2 per week.
  final int selectedFrequency;

  /// Selected delivery day indices (0=Mon, 6=Sun).
  final Set<int> selectedDeliveryDays;

  /// Whether the active plan has been explicitly configured via modal.
  final bool isPlanConfigured;

  /// Warning message when deselection limit is reached or blocked.
  final String? deselectionWarning;

  /// Whether backend /calculate/ pricing is actively in-flight.
  final bool isPricingLoading;

  /// Error message if backend /calculate/ pricing fails.
  final String? pricingError;

  const RfpBatchState({
    this.isLoading = false,
    this.error,
    this.batches = const [],
    this.selectedBatch,
    this.plans = const [],
    this.selectedPlan,
    this.patches = const [],
    this.selectedPatchIds = const {},
    this.patchConfigs = const {},
    this.pricing,
    this.selectedLocationId = 'loc_01',
    this.selectedCityName = 'Valley Sector 4',
    this.selectedPlanIds = const {},
    this.planConfigurations = const {},
    this.selectedVegetableIds = const {},
    this.selectedPricingVariant,
    this.selectedFrequency = 1,
    this.selectedDeliveryDays = const {},
    this.isPlanConfigured = false,
    this.deselectionWarning,
    this.isPricingLoading = false,
    this.pricingError,
  });

  RfpBatchState copyWith({
    bool? isLoading,
    String? error,
    List<RfpBatch>? batches,
    RfpBatch? selectedBatch,
    List<RfpPlan>? plans,
    RfpPlan? selectedPlan,
    List<RfpPatch>? patches,
    Set<String>? selectedPatchIds,
    Map<String, RfpPatchConfig>? patchConfigs,
    RfpPricing? pricing,
    String? selectedLocationId,
    String? selectedCityName,
    Set<String>? selectedPlanIds,
    Map<String, RfpPlanConfig>? planConfigurations,
    Set<String>? selectedVegetableIds,
    RfpPlanPricing? selectedPricingVariant,
    int? selectedFrequency,
    Set<int>? selectedDeliveryDays,
    bool? isPlanConfigured,
    String? deselectionWarning,
    bool clearWarning = false,
    bool? isPricingLoading,
    String? pricingError,
    bool clearPricingError = false,
  }) {
    return RfpBatchState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      batches: batches ?? this.batches,
      selectedBatch: selectedBatch ?? this.selectedBatch,
      plans: plans ?? this.plans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      patches: patches ?? this.patches,
      selectedPatchIds: selectedPatchIds ?? this.selectedPatchIds,
      patchConfigs: patchConfigs ?? this.patchConfigs,
      pricing: pricing ?? this.pricing,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      selectedCityName: selectedCityName ?? this.selectedCityName,
      selectedPlanIds: selectedPlanIds ?? this.selectedPlanIds,
      planConfigurations: planConfigurations ?? this.planConfigurations,
      selectedVegetableIds: selectedVegetableIds ?? this.selectedVegetableIds,
      selectedPricingVariant:
          selectedPricingVariant ?? this.selectedPricingVariant,
      selectedFrequency: selectedFrequency ?? this.selectedFrequency,
      selectedDeliveryDays: selectedDeliveryDays ?? this.selectedDeliveryDays,
      isPlanConfigured: isPlanConfigured ?? this.isPlanConfigured,
      deselectionWarning:
          clearWarning ? null : (deselectionWarning ?? this.deselectionWarning),
      isPricingLoading: isPricingLoading ?? this.isPricingLoading,
      pricingError:
          clearPricingError ? null : (pricingError ?? this.pricingError),
    );
  }

  List<RfpPatch> get selectedPatches =>
      patches.where((p) => selectedPatchIds.contains(p.id)).toList();

  /// All unique plans available across current batch, batches list, and loaded plans.
  List<RfpPlan> get allAvailablePlans {
    final map = <String, RfpPlan>{};
    if (selectedBatch != null) {
      for (final p in selectedBatch!.plans) {
        map[p.id] = p;
      }
    }
    for (final b in batches) {
      for (final p in b.plans) {
        map[p.id] = p;
      }
    }
    for (final p in plans) {
      map[p.id] = p;
    }
    if (selectedPlan != null) {
      map[selectedPlan!.id] = selectedPlan!;
    }
    return map.values.toList();
  }

  /// All selected Thalis/Plans for the harvest subscription order.
  List<RfpPlan> get selectedPlans {
    final available = {for (final p in allAvailablePlans) p.id: p};
    final allIds = <String>{
      ...selectedPlanIds,
      ...planConfigurations.keys,
      if (selectedPlan != null) selectedPlan!.id,
    };
    final result = <RfpPlan>[];
    for (final id in allIds) {
      if (available.containsKey(id)) {
        result.add(available[id]!);
      }
    }
    if (result.isEmpty && selectedPlan != null) {
      result.add(selectedPlan!);
    }
    return result;
  }

  bool isPlanSelected(String planId) => selectedPlanIds.contains(planId);

  /// Resolves all active plan configurations for pricing calculation and booking payload.
  List<RfpPatchConfig> get activePatchConfigs {
    if (patchConfigs.isNotEmpty) {
      return patchConfigs.values.toList();
    }
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final activeIds =
        selectedPlanIds.isNotEmpty
            ? <String>{...selectedPlanIds, ...planConfigurations.keys}
            : (selectedPlan != null
                ? {selectedPlan!.id}
                : (planConfigurations.isNotEmpty
                    ? planConfigurations.keys.toSet()
                    : <String>{}));
    final list = <RfpPatchConfig>[];
    for (final pId in activeIds) {
      final pConfig = planConfigurations[pId];
      final matchingPlans = allAvailablePlans.where((p) => p.id == pId);
      final plan = matchingPlans.isNotEmpty ? matchingPlans.first : null;
      final weight =
          pConfig?.selectedPricing?.weightKg ??
          (plan != null && plan.pricings.isNotEmpty
              ? plan.pricings.first.weightKg
              : 2.5);
      final freq =
          (pConfig?.selectedFrequency ?? 1) == 2
              ? 'twice_a_week'
              : 'once_a_week';
      final excluded = <String>[];
      final selectedVegs = pConfig?.selectedVegetableIds;
      if (plan != null && selectedVegs != null && selectedVegs.isNotEmpty) {
        for (final v in plan.availableVegetables) {
          if (!selectedVegs.contains(v.id)) {
            excluded.add(v.id);
          }
        }
      }
      List<String>? days;
      if (pConfig != null && pConfig.selectedDeliveryDays.isNotEmpty) {
        final sorted = pConfig.selectedDeliveryDays.toList()..sort();
        final neededCount = (pConfig.selectedFrequency == 2) ? 2 : 1;
        days = sorted.map((d) => dayNames[d % 7]).take(neededCount).toList();
      }
      final resolvedPricingId =
          pConfig?.selectedPricing?.id ??
          (plan != null && plan.pricings.isNotEmpty
              ? plan.pricings.first.id
              : null);
      list.add(
        RfpPatchConfig(
          patchId: pId,
          patchLabel: plan?.code ?? pId,
          excludedVegetableIds: excluded,
          selectedWeight: weight,
          deliveryFrequency: freq,
          planPricingId: resolvedPricingId,
          selectedVegetableIds: selectedVegs?.toList(),
          deliveryDays: days,
        ),
      );
    }
    return list;
  }

  bool get canContinueToCheckout {
    if (selectedBatch == null) return false;
    if (selectedPlanIds.isNotEmpty) return true;
    if (selectedPlan != null) {
      return isPlanConfigured && selectedVegetableIds.isNotEmpty;
    }
    return false;
  }

  /// Dynamic multi-plan discount percentage from backend calculation or tiers.
  double get discountPercentage => pricing?.discountPercentage ?? 0.0;

  bool get hasDiscount => discountPercentage > 0;

  /// Computed total price per week across all selected plans.
  double get totalWeeklyPrice {
    if (pricing != null && pricing!.perDelivery > 0) {
      return pricing!.perDelivery;
    }
    double sum = 0;
    for (final plan in selectedPlans) {
      final config = planConfigurations[plan.id];
      final variant =
          config?.selectedPricing ??
          (plan.pricings.isNotEmpty ? plan.pricings.first : null);
      if (variant != null) {
        sum += variant.pricePerDelivery * (config?.selectedFrequency ?? 1);
      }
    }
    return sum;
  }

  /// Price per week for the active plan.
  double get pricePerWeek {
    if (selectedPricingVariant == null) return 0;
    return selectedPricingVariant!.pricePerDelivery * selectedFrequency;
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    batches,
    selectedBatch,
    plans,
    selectedPlan,
    patches,
    selectedPatchIds,
    patchConfigs,
    pricing,
    selectedLocationId,
    selectedCityName,
    selectedPlanIds,
    planConfigurations,
    selectedVegetableIds,
    selectedPricingVariant,
    selectedFrequency,
    selectedDeliveryDays,
    isPlanConfigured,
    deselectionWarning,
    isPricingLoading,
    pricingError,
  ];
}
