// lib/features/panchang/domain/usecases/save_guidance_profile_use_case.dart
import '../entities/panchang_entities.dart';
import '../repositories/panchang_repository.dart';

class SaveGuidanceProfileUseCase {
  final PanchangRepository _repository;

  SaveGuidanceProfileUseCase(this._repository);

  Future<PanchangGuidanceProfileEntity> call(
    PanchangGuidanceProfileEntity profile,
  ) {
    return _repository.saveGuidanceProfile(profile);
  }
}
