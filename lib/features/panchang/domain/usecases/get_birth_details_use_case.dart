// lib/features/panchang/domain/usecases/get_birth_details_use_case.dart
import '../entities/kundli_entities.dart';
import '../repositories/kundli_repository.dart';

class GetBirthDetailsUseCase {
  final KundliRepository _repository;

  GetBirthDetailsUseCase(this._repository);

  Future<KundliBirthDetails?> call() {
    return _repository.getSavedBirthDetails();
  }
}
