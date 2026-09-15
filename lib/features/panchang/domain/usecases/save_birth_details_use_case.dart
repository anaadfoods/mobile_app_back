// lib/features/panchang/domain/usecases/save_birth_details_use_case.dart
import '../repositories/kundli_repository.dart';

class SaveBirthDetailsUseCase {
  final KundliRepository _repository;

  SaveBirthDetailsUseCase(this._repository);

  Future<bool> call({
    required String dateOfBirth,
    required String timeOfBirth,
    required String birthCity,
    String name = '',
    String birthState = '',
    String birthCountry = 'India',
    double? latitude,
    double? longitude,
    String timezone = 'Asia/Kolkata',
  }) {
    return _repository.saveBirthDetails(
      dateOfBirth: dateOfBirth,
      timeOfBirth: timeOfBirth,
      name: name,
      birthCity: birthCity,
      birthState: birthState,
      birthCountry: birthCountry,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
    );
  }
}
