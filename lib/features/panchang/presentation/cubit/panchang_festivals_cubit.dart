// lib/features/panchang/presentation/cubit/panchang_festivals_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../helpers/app_error_helper.dart';
import '../../../../repositories/panchang_repository.dart';
import 'panchang_festivals_state.dart';

class PanchangFestivalsCubit extends Cubit<PanchangFestivalsState> {
  final PanchangRepository _repository;
  DateTime _startDate;
  DateTime _endDate;
  String? _filterType;

  PanchangFestivalsCubit({required PanchangRepository repository})
      : _repository = repository,
        _startDate = DateTime.now(),
        _endDate = DateTime.now().add(const Duration(days: 30)),
        super(const PanchangFestivalsInitial());

  Future<void> loadFestivals({
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    String? filterType,
  }) async {
    try {
      if (isClosed) return;
      emit(const PanchangFestivalsLoading());

      _startDate = startDate ?? DateTime.now();
      _endDate = endDate ?? _startDate.add(Duration(days: days ?? 30));
      _filterType = filterType;

      final response = await _repository.getFestivals(
        startDate: _startDate,
        endDate: _endDate,
        type: _filterType,
      );

      if (isClosed) return;
      emit(
        PanchangFestivalsSuccess(
          response: response,
          startDate: _startDate,
          endDate: _endDate,
          filterType: _filterType,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(PanchangFestivalsError(AppErrorHelper.getErrorMessage(e)));
    }
  }

  Future<void> searchFestivals(String query, {int? year, int? month}) async {
    if (query.trim().isEmpty) {
      await loadFestivals();
      return;
    }
    try {
      if (isClosed) return;
      emit(const PanchangFestivalsSearching());

      final response = await _repository.searchFestivals(
        query: query,
        year: year,
      );

      if (isClosed) return;
      emit(PanchangFestivalsSearchSuccess(response: response, query: query));
    } catch (e) {
      if (isClosed) return;
      emit(PanchangFestivalsError(AppErrorHelper.getErrorMessage(e)));
    }
  }

  Future<void> loadCurrentMonth() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    await loadFestivals(
      startDate: firstDay,
      endDate: lastDay,
      filterType: _filterType,
    );
  }

  Future<void> loadUpcoming() async {
    final now = DateTime.now();
    await loadFestivals(startDate: now, days: 30, filterType: _filterType);
  }

  Future<void> loadFullYear(int year) async {
    final firstDay = DateTime(year, 1, 1);
    final lastDay = DateTime(year, 12, 31);
    await loadFestivals(
      startDate: firstDay,
      endDate: lastDay,
      filterType: _filterType,
    );
  }

  Future<void> applyFilter(String? type) async {
    _filterType = type;
    await loadFestivals(
      startDate: _startDate,
      endDate: _endDate,
      filterType: _filterType,
    );
  }

  Future<void> refresh() async {
    await loadFestivals(
      startDate: _startDate,
      endDate: _endDate,
      filterType: _filterType,
    );
  }

  Future<void> clearSearch() async {
    await loadFestivals(
      startDate: _startDate,
      endDate: _endDate,
      filterType: _filterType,
    );
  }
}
