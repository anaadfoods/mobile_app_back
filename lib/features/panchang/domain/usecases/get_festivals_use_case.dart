// lib/features/panchang/domain/usecases/get_festivals_use_case.dart
import '../entities/panchang_entities.dart';
import '../repositories/panchang_repository.dart';

class GetFestivalsUseCase {
  final PanchangRepository _repository;

  GetFestivalsUseCase(this._repository);

  Future<List<PanchangFestivalEntity>> call({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String locale = 'en',
  }) {
    return _repository.getFestivals(
      startDate: startDate,
      endDate: endDate,
      days: days,
      locale: locale,
    );
  }

  Future<List<PanchangFestivalEntity>> search({
    required String query,
    int? year,
    int? month,
    String locale = 'en',
  }) {
    return _repository.searchFestivals(
      query: query,
      year: year,
      month: month,
      locale: locale,
    );
  }
}
