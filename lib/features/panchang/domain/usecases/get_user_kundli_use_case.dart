// lib/features/panchang/domain/usecases/get_user_kundli_use_case.dart
import '../entities/kundli_entities.dart';
import '../repositories/kundli_repository.dart';

class GetUserKundliUseCase {
  final KundliRepository _repository;

  GetUserKundliUseCase(this._repository);

  Future<KundliEntity?> call() {
    return _repository.getUserKundli();
  }
}
