// lib/features/panchang/presentation/cubit/panchang_home_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../helpers/app_error_helper.dart';
import '../../../../models/panchang/panchang_day_models.dart';
import '../../../../models/panchang/panchang_highlights_models.dart';
import '../../../../models/panchang/panchang_guidance_models.dart';
import '../../../../repositories/panchang_repository.dart';
import 'panchang_home_state.dart';

class PanchangHomeCubit extends Cubit<PanchangHomeState> {
  final PanchangRepository _repository;
  DateTime _selectedDate = DateTime.now();

  PanchangHomeCubit({required PanchangRepository repository})
      : _repository = repository,
        super(const PanchangHomeInitial());

  DateTime get selectedDate => _selectedDate;

  Future<void> loadToday() async {
    _selectedDate = DateTime.now();
    await loadDate(_selectedDate);
  }

  Future<void> loadDate(DateTime date) async {
    try {
      if (isClosed) return;
      _selectedDate = date;
      emit(const PanchangHomeLoading());

      final dayFuture = _repository.getDay(date);
      final highlightsFuture = _repository.getHighlights(
        year: date.year,
        month: date.month,
      );
      final guidanceFuture = _repository.getTodayGuidance(date: date);

      final results = await Future.wait<dynamic>([
        dayFuture,
        (highlightsFuture as Future<PanchangHighlightsResponse?>).catchError((_) => null),
        (guidanceFuture as Future<GuidanceTodayResponse?>).catchError((_) => null),
      ]);

      if (isClosed) return;
      emit(
        PanchangHomeSuccess(
          day: results[0] as PanchangDayResponse,
          selectedDate: date,
          highlights: results[1] as PanchangHighlightsResponse?,
          guidance: results[2] as GuidanceTodayResponse?,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(PanchangHomeError(AppErrorHelper.getErrorMessage(e)));
    }
  }

  Future<void> loadMuhurats(DateTime date, {List<String>? types}) async {
    try {
      if (isClosed) return;
      _selectedDate = date;
      emit(const PanchangMuhuratsLoading());

      final muhurats = await _repository.getMuhurats(date, types: types);

      if (isClosed) return;
      emit(PanchangMuhuratsSuccess(muhurats: muhurats, selectedDate: date));
    } catch (e) {
      if (isClosed) return;
      emit(PanchangHomeError(AppErrorHelper.getErrorMessage(e)));
    }
  }
}
