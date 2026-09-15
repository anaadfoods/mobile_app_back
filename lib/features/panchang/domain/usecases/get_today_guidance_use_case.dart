// lib/features/panchang/domain/usecases/get_today_guidance_use_case.dart
import '../entities/panchang_entities.dart';
import '../repositories/panchang_repository.dart';

class GetTodayGuidanceUseCase {
  final PanchangRepository _repository;

  GetTodayGuidanceUseCase(this._repository);

  Future<PanchangGuidanceEntity> call({
    DateTime? date,
    PanchangLocationEntity? location,
  }) {
    return _repository.getTodayGuidance(
      date: date,
      location: location,
    );
  }
}
