// lib/features/panchang/domain/usecases/get_vrat_calendar_use_case.dart
import '../entities/panchang_entities.dart';
import '../repositories/panchang_repository.dart';

class GetVratCalendarUseCase {
  final PanchangRepository _repository;

  GetVratCalendarUseCase(this._repository);

  Future<List<PanchangVratEntity>> call({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String locale = 'en',
  }) {
    return _repository.getVratCalendar(
      startDate: startDate,
      endDate: endDate,
      days: days,
      locale: locale,
    );
  }
}
