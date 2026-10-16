import '../entities/rfp_plan.dart';
import '../repositories/rfp_repository.dart';

class GetPlansUseCase {
  final RfpRepository _repository;
  GetPlansUseCase(this._repository);

  Future<List<RfpPlan>> call(String batchId) => _repository.getPlans(batchId);
}
