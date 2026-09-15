// lib/features/panchang/domain/usecases/get_panchang_month_use_case.dart
import '../entities/panchang_entities.dart';
import '../repositories/panchang_repository.dart';

class GetPanchangMonthUseCase {
  final PanchangRepository _repository;

  GetPanchangMonthUseCase(this._repository);

  Future<Map<String, dynamic>> call({
    required int year,
    required int month,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  }) {
    return _repository.getPanchangMonth(
      year: year,
      month: month,
      location: location,
      locale: locale,
      calendarSystem: calendarSystem,
      profile: profile,
    );
  }
}
