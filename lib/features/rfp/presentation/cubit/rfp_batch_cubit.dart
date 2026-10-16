import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/rfp_batch.dart';
import '../../domain/entities/rfp_plan.dart';
import '../../domain/entities/rfp_patch_config.dart';
import '../../domain/entities/rfp_plan_pricing.dart';
import '../../domain/usecases/get_batches_use_case.dart';
import '../../domain/usecases/get_plans_use_case.dart';
import '../../domain/usecases/get_patches_use_case.dart';
import '../../domain/usecases/calculate_pricing_use_case.dart';
import 'rfp_batch_state.dart';

export 'rfp_batch_state.dart';

/// Cubit managing RFP Batches, Multi-Plan Selection, and Plan Configuration.
class RfpBatchCubit extends Cubit<RfpBatchState> {
  final GetBatchesUseCase _getBatches;
  final GetPlansUseCase _getPlans;
  final GetPatchesUseCase _getPatches;
  final CalculatePricingUseCase _calculatePricing;

  RfpBatchCubit({
    required GetBatchesUseCase getBatches,
    required GetPlansUseCase getPlans,
    required GetPatchesUseCase getPatches,
    required CalculatePricingUseCase calculatePricing,
  }) : _getBatches = getBatches,
       _getPlans = getPlans,
       _getPatches = getPatches,
       _calculatePricing = calculatePricing,
       super(const RfpBatchState());

  Future<void> loadBatchData() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final batches = await _getBatches(state.selectedLocationId);
      if (batches.isEmpty) {
        emit(state.copyWith(isLoading: false, batches: const []));
        return;
      }
      final matchingActive = batches.where((b) => b.isActive);
      final activeBatch =
          matchingActive.isNotEmpty ? matchingActive.first : batches.first;

      final plans = await _getPlans(activeBatch.id);
      final patches = await _getPatches(activeBatch.id);

      final matchingPremium = plans.where((p) => p.tier == 'premium');
      final defaultPlan =
          matchingPremium.isNotEmpty
              ? matchingPremium.first
              : (plans.isNotEmpty ? plans.first : null);

      final defaultPlanIds =
          defaultPlan != null ? {defaultPlan.id} : <String>{};
      final initialPlanConfigs = <String, RfpPlanConfig>{};
      if (defaultPlan != null) {
        final defaultPricing =
            defaultPlan.pricings.isNotEmpty ? defaultPlan.pricings.first : null;
        final defaultVegIds = <String>{};
        for (final v in defaultPlan.availableVegetables) {
          if (v.isDefaultSelected) defaultVegIds.add(v.id);
        }
        if (defaultVegIds.isEmpty) {
          final limit =
              defaultPlan.selectionLimit > 0
                  ? defaultPlan.selectionLimit
                  : defaultPlan.availableVegetables.length;
          defaultVegIds.addAll(
            defaultPlan.availableVegetables.take(limit).map((v) => v.id),
          );
        }

        initialPlanConfigs[defaultPlan.id] = RfpPlanConfig(
          planId: defaultPlan.id,
          selectedPricing: defaultPricing,
          selectedVegetableIds: defaultVegIds,
          selectedFrequency: defaultPricing?.frequencyPerWeek ?? 1,
          isConfigured: true,
        );
      }

      emit(
        state.copyWith(
          isLoading: false,
          batches: batches,
          selectedBatch: activeBatch,
          plans: plans,
          selectedPlan: defaultPlan,
          selectedPlanIds: defaultPlanIds,
          planConfigurations: initialPlanConfigs,
          patches: patches,
        ),
      );
      _recalculatePricing();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void selectBatch(RfpBatch batch) {
    emit(state.copyWith(selectedBatch: batch));
    loadPlansForBatch(batch.id);
  }

  Future<void> loadPlansForBatch(String batchId) async {
    try {
      final plans = await _getPlans(batchId);
      final defaultPlan = plans.isNotEmpty ? plans.first : null;
      final defaultPlanIds =
          defaultPlan != null ? {defaultPlan.id} : <String>{};

      emit(
        state.copyWith(
          plans: plans,
          selectedPlan: defaultPlan,
          selectedPlanIds: defaultPlanIds,
        ),
      );
      _recalculatePricing();
    } catch (_) {}
  }

  // ─── Multi-Plan Selection ────────────────────────────────────────────────

  /// Toggles selection of a plan via tick/checkbox.
  void togglePlanSelection(String planId) {
    final selectedIds = Set<String>.from(state.selectedPlanIds);
    final configs = Map<String, RfpPlanConfig>.from(state.planConfigurations);

    if (selectedIds.contains(planId)) {
      selectedIds.remove(planId);
    } else {
      selectedIds.add(planId);
      if (!configs.containsKey(planId)) {
        final matching = state.allAvailablePlans.where((p) => p.id == planId);
        if (matching.isNotEmpty) {
          final plan = matching.first;
          final defaultPricing =
              plan.pricings.isNotEmpty ? plan.pricings.first : null;
          final defaultVegIds = <String>{};
          for (final v in plan.availableVegetables) {
            if (v.isDefaultSelected) defaultVegIds.add(v.id);
          }
          if (defaultVegIds.isEmpty) {
            final limit =
                plan.selectionLimit > 0
                    ? plan.selectionLimit
                    : plan.availableVegetables.length;
            defaultVegIds.addAll(
              plan.availableVegetables.take(limit).map((v) => v.id),
            );
          }

          configs[planId] = RfpPlanConfig(
            planId: planId,
            selectedPricing: defaultPricing,
            selectedVegetableIds: defaultVegIds,
            selectedFrequency: defaultPricing?.frequencyPerWeek ?? 1,
            isConfigured: true,
          );
        }
      }
    }

    emit(
      state.copyWith(selectedPlanIds: selectedIds, planConfigurations: configs),
    );
    _recalculatePricing();
  }

  void selectPlan(RfpPlan plan) {
    emit(state.copyWith(selectedPlan: plan));
    initializeVegetablesForPlan(plan);
  }

  // ─── Plan Configurator Methods ───────────────────────────────────────────

  void toggleVegetable(String vegetableId) {
    final plan = state.selectedPlan;
    final ids = Set<String>.from(state.selectedVegetableIds);
    if (ids.contains(vegetableId)) {
      if (plan != null && !plan.canDeselectVegetable(vegetableId, ids)) {
        emit(
          state.copyWith(
            deselectionWarning:
                plan.isCuratedFixed
                    ? 'This plan has a fixed curated harvest. Items cannot be deselected.'
                    : 'Maximum swap limit (${plan.maxDeselectableCount}) reached for this plan.',
          ),
        );
        return;
      }
      ids.remove(vegetableId);
      emit(state.copyWith(selectedVegetableIds: ids, clearWarning: true));
    } else {
      final limit = plan?.selectionLimit ?? 0;
      if (limit > 0 && ids.length >= limit) return;
      ids.add(vegetableId);
      emit(state.copyWith(selectedVegetableIds: ids, clearWarning: true));
    }
  }

  void clearDeselectionWarning() {
    if (state.deselectionWarning != null) {
      emit(state.copyWith(clearWarning: true));
    }
  }

  void selectPricingVariant(RfpPlanPricing variant) {
    emit(
      state.copyWith(
        selectedPricingVariant: variant,
        selectedFrequency: variant.frequencyPerWeek,
      ),
    );
  }

  void setDeliveryFrequency(int frequency) {
    emit(state.copyWith(selectedFrequency: frequency));
    if (state.selectedPlan != null) {
      final matchingVariants = state.selectedPlan!.pricings.where(
        (p) =>
            p.frequencyPerWeek == frequency &&
            (state.selectedPricingVariant == null ||
                p.weightKg == state.selectedPricingVariant!.weightKg),
      );
      if (matchingVariants.isNotEmpty) {
        emit(state.copyWith(selectedPricingVariant: matchingVariants.first));
      }
    }
  }

  void toggleDeliveryDay(int dayIndex) {
    final days = Set<int>.from(state.selectedDeliveryDays);
    if (days.contains(dayIndex)) {
      days.remove(dayIndex);
    } else {
      if (days.length >= state.selectedFrequency) {
        if (days.isNotEmpty) days.remove(days.first);
      }
      days.add(dayIndex);
    }
    emit(state.copyWith(selectedDeliveryDays: days));
  }

  void confirmPlanConfiguration() {
    final plan =
        state.selectedPlan ??
        (state.plans.isNotEmpty ? state.plans.first : null);
    if (plan == null) {
      emit(state.copyWith(isPlanConfigured: true));
      return;
    }

    final selectedIds = Set<String>.from(state.selectedPlanIds)..add(plan.id);
    final configs = Map<String, RfpPlanConfig>.from(state.planConfigurations);

    configs[plan.id] = RfpPlanConfig(
      planId: plan.id,
      selectedPricing: state.selectedPricingVariant,
      selectedVegetableIds: state.selectedVegetableIds,
      selectedFrequency: state.selectedFrequency,
      selectedDeliveryDays: state.selectedDeliveryDays,
      isConfigured: true,
    );

    emit(
      state.copyWith(
        isPlanConfigured: true,
        selectedPlanIds: selectedIds,
        planConfigurations: configs,
      ),
    );
    _recalculatePricing();
  }

  void initializeVegetablesForPlan(RfpPlan plan) {
    final existingConfig = state.planConfigurations[plan.id];
    if (existingConfig != null) {
      emit(
        state.copyWith(
          selectedPlan: plan,
          selectedVegetableIds: existingConfig.selectedVegetableIds,
          selectedPricingVariant: existingConfig.selectedPricing,
          selectedFrequency: existingConfig.selectedFrequency,
          selectedDeliveryDays: existingConfig.selectedDeliveryDays,
          isPlanConfigured: existingConfig.isConfigured,
        ),
      );
      return;
    }

    final veggieIds = <String>{};
    for (final v in plan.availableVegetables) {
      if (v.isDefaultSelected) veggieIds.add(v.id);
    }
    if (veggieIds.isEmpty) {
      final limit =
          plan.selectionLimit > 0
              ? plan.selectionLimit
              : plan.availableVegetables.length;
      for (var i = 0; i < limit && i < plan.availableVegetables.length; i++) {
        veggieIds.add(plan.availableVegetables[i].id);
      }
    }
    final defaultPricing =
        plan.pricings.isNotEmpty ? plan.pricings.first : null;
    emit(
      state.copyWith(
        selectedPlan: plan,
        selectedVegetableIds: veggieIds,
        selectedPricingVariant: defaultPricing,
        selectedFrequency: defaultPricing?.frequencyPerWeek ?? 1,
        isPlanConfigured: false,
      ),
    );
  }

  void updatePatchConfig(String patchId, RfpPatchConfig config) {
    final updated = Map<String, RfpPatchConfig>.from(state.patchConfigs);
    updated[patchId] = config;
    emit(state.copyWith(patchConfigs: updated));
    _recalculatePricing();
  }

  void setLocation(String locationId, [String? cityName]) {
    emit(
      state.copyWith(
        selectedLocationId: locationId,
        selectedCityName:
            cityName ??
            (locationId == 'loc_02' ? 'Green Valley' : 'Valley Sector 4'),
      ),
    );
    loadBatchData();
  }

  /// Public method to trigger pricing quote calculation from backend.
  Future<void> recalculatePricing() => _recalculatePricing();

  Future<void> _recalculatePricing() async {
    final configsToUse = state.activePatchConfigs;
    if (configsToUse.isEmpty) {
      emit(
        state.copyWith(
          pricing: null,
          isPricingLoading: false,
          clearPricingError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(isPricingLoading: true, clearPricingError: true));

    try {
      final pricing = await _calculatePricing(
        planId: configsToUse.first.patchId,
        patchConfigs: configsToUse,
        batchId: state.selectedBatch?.id,
      );
      emit(
        state.copyWith(
          pricing: pricing,
          isPricingLoading: false,
          clearPricingError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isPricingLoading: false,
          pricingError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
