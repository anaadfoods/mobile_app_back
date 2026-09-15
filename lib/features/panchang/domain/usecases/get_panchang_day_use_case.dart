// lib/features/panchang/domain/usecases/get_panchang_day_use_case.dart
import '../entities/panchang_entities.dart';
import '../repositories/panchang_repository.dart';

class GetPanchangDayUseCase {
  final PanchangRepository _repository;

  GetPanchangDayUseCase(this._repository);

  Future<PanchangDayEntity> call({
    DateTime? date,
    PanchangLocationEntity? location,
    String locale = 'en',
    String calendarSystem = 'amanta',
    String profile = 'default',
  }) {
    return _repository.getPanchangDay(
      date: date,
      location: location,
      locale: locale,
      calendarSystem: calendarSystem,
      profile: profile,
    );
  }
}
