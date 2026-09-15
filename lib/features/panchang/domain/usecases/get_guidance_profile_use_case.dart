// lib/features/panchang/domain/usecases/get_guidance_profile_use_case.dart
import '../entities/panchang_entities.dart';
import '../repositories/panchang_repository.dart';

class GetGuidanceProfileUseCase {
  final PanchangRepository _repository;

  GetGuidanceProfileUseCase(this._repository);

  Future<PanchangGuidanceProfileEntity> call() {
    return _repository.getGuidanceProfile();
  }
}
