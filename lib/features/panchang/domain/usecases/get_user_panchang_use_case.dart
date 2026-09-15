// lib/features/panchang/domain/usecases/get_user_panchang_use_case.dart
import '../repositories/panchang_repository.dart';

class GetUserPanchangUseCase {
  final PanchangRepository _repository;

  GetUserPanchangUseCase(this._repository);

  Future<Map<String, dynamic>> call() {
    return _repository.getUserPanchang();
  }
}
