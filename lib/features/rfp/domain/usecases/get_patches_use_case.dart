import '../entities/rfp_patch.dart';
import '../repositories/rfp_repository.dart';

class GetPatchesUseCase {
  final RfpRepository _repository;
  GetPatchesUseCase(this._repository);

  Future<List<RfpPatch>> call(String batchId) =>
      _repository.getPatches(batchId);
}
