import '../entities/rfp_batch.dart';
import '../repositories/rfp_repository.dart';

class GetBatchesUseCase {
  final RfpRepository _repository;
  GetBatchesUseCase(this._repository);

  Future<List<RfpBatch>> call(String locationId) =>
      _repository.getBatches(locationId);
}
