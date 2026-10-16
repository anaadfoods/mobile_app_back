import '../entities/rfp_location.dart';
import '../repositories/rfp_repository.dart';

class GetLocationsUseCase {
  final RfpRepository _repository;
  GetLocationsUseCase(this._repository);

  Future<List<RfpLocation>> call() => _repository.getAvailableLocations();
}
