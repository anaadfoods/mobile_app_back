import '../../domain/entities/rfp_patch_config.dart';
import '../../domain/entities/rfp_plan.dart';
import '../models/rfp_batch_model.dart';

/// Helper utility to construct API payloads for RFP subscription booking and calculation.
class RfpPayloadBuilder {
  const RfpPayloadBuilder._();

  /// Resolves the integer batch ID associated with a given plan or explicit batch.
  static int findBatchId(
    String planId,
    List<RfpBatchModel> cachedBatches, [
    String? explicitBatchId,
  ]) {
    if (explicitBatchId != null) {
      final parsed = int.tryParse(explicitBatchId);
      if (parsed != null) return parsed;
    }
    for (final b in cachedBatches) {
      for (final p in b.plans) {
        if (p.id == planId) {
          return int.tryParse(b.id) ?? 1;
        }
      }
    }
    return int.tryParse(
          cachedBatches.isNotEmpty ? cachedBatches.first.id : '1',
        ) ??
        1;
  }

  /// Derives delivery days from patch configurations and optional selected day indices.
  /// Length must equal frequency_per_week (1 or 2).
  static List<String> buildDeliveryDays(
    List<RfpPatchConfig> patchConfigs, [
    Set<int>? selectedDays,
  ]) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final hasTwice = patchConfigs.any(
      (c) => c.deliveryFrequency == 'twice_a_week',
    );
    final neededCount = hasTwice ? 2 : 1;

    for (final c in patchConfigs) {
      if (c.deliveryDays != null && c.deliveryDays!.length == neededCount) {
        return c.deliveryDays!;
      }
    }

    if (selectedDays != null && selectedDays.isNotEmpty) {
      final sorted = selectedDays.toList()..sort();
      final mapped =
          sorted.map((d) => dayNames[d % 7]).take(neededCount).toList();
      if (mapped.length == neededCount) return mapped;
    }

    return hasTwice ? ['Monday', 'Thursday'] : ['Monday'];
  }

  /// Builds the plans payload with selected pricing ID and vegetable IDs.
  static List<Map<String, dynamic>> buildPlansPayload(
    String planId,
    List<RfpPatchConfig> patchConfigs,
    List<RfpBatchModel> cachedBatches,
  ) {
    final plansPayload = <Map<String, dynamic>>[];

    for (final config in patchConfigs) {
      RfpPlan? matchedPlan;
      for (final b in cachedBatches) {
        final pMatch = b.plans.where((p) => p.id == config.patchId);
        if (pMatch.isNotEmpty) {
          matchedPlan = pMatch.first;
          break;
        }
      }
      if (matchedPlan == null) {
        for (final b in cachedBatches) {
          final pMatch = b.plans.where((p) => p.id == planId);
          if (pMatch.isNotEmpty) {
            matchedPlan = pMatch.first;
            break;
          }
        }
      }

      int? pricingId = config.planPricingId;
      if (pricingId == null &&
          matchedPlan != null &&
          matchedPlan.pricings.isNotEmpty) {
        final isTwice = config.deliveryFrequency == 'twice_a_week';
        final targetFreq = isTwice ? 2 : 1;

        final matchingPricings = matchedPlan.pricings.where(
          (pr) =>
              pr.weightKg == config.selectedWeight &&
              pr.frequencyPerWeek == targetFreq,
        );

        if (matchingPricings.isNotEmpty) {
          pricingId = matchingPricings.first.id;
        } else {
          pricingId = matchedPlan.pricings.first.id;
        }
      }
      pricingId ??= int.tryParse(config.patchId) ?? int.tryParse(planId) ?? 1;

      final includedVegIds = <int>[];
      if (config.selectedVegetableIds != null &&
          config.selectedVegetableIds!.isNotEmpty) {
        for (final v in config.selectedVegetableIds!) {
          final intId = int.tryParse(v);
          if (intId != null) includedVegIds.add(intId);
        }
      } else if (matchedPlan != null) {
        if (config.excludedVegetableIds.isNotEmpty) {
          for (final v in matchedPlan.availableVegetables) {
            if (!config.excludedVegetableIds.contains(v.id)) {
              final intId = int.tryParse(v.id);
              if (intId != null) includedVegIds.add(intId);
            }
          }
        } else {
          final defaults =
              matchedPlan.availableVegetables
                  .where((v) => v.isDefaultSelected)
                  .map((v) => int.tryParse(v.id))
                  .whereType<int>()
                  .toList();

          if (defaults.length == matchedPlan.selectionLimit) {
            includedVegIds.addAll(defaults);
          } else {
            final limit =
                matchedPlan.selectionLimit > 0
                    ? matchedPlan.selectionLimit
                    : matchedPlan.availableVegetables.length;
            final fallback =
                matchedPlan.availableVegetables
                    .take(limit)
                    .map((v) => int.tryParse(v.id))
                    .whereType<int>()
                    .toList();
            includedVegIds.addAll(fallback);
          }
        }
      }

      plansPayload.add({
        'plan_pricing_id': pricingId,
        if (includedVegIds.isNotEmpty) 'vegetable_ids': includedVegIds,
      });
    }

    return plansPayload;
  }
}
