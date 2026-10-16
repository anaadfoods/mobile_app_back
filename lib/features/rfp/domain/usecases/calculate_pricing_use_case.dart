import '../entities/rfp_pricing.dart';
import '../entities/rfp_patch_config.dart';
import '../repositories/rfp_repository.dart';

class CalculatePricingUseCase {
  final RfpRepository _repository;
  CalculatePricingUseCase(this._repository);

  Future<RfpPricing> call({
    required String planId,
    required List<RfpPatchConfig> patchConfigs,
    String? batchId,
  }) => _repository.calculatePricing(
    planId: planId,
    patchConfigs: patchConfigs,
    batchId: batchId,
  );
}
