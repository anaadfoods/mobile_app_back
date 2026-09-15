// lib/features/panchang/domain/usecases/generate_kundli_use_case.dart
import '../entities/kundli_entities.dart';
import '../repositories/kundli_repository.dart';

class GenerateKundliUseCase {
  final KundliRepository _repository;

  GenerateKundliUseCase(this._repository);

  Future<KundliEntity> call({
    required String dateOfBirth,
    required String timeOfBirth,
    String name = '',
    required double latitude,
    required double longitude,
    String timezone = 'Asia/Kolkata',
    String birthCity = '',
    String birthState = '',
    bool saveToProfile = false,
  }) {
    return _repository.generateKundli(
      dateOfBirth: dateOfBirth,
      timeOfBirth: timeOfBirth,
      name: name,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      birthCity: birthCity,
      birthState: birthState,
      saveToProfile: saveToProfile,
    );
  }
}
