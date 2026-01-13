import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/helpers/app_error_helper.dart';

import '../../repositories/panchang_repository.dart';
import 'panchang_month_state.dart';

class PanchangMonthCubit extends Cubit<PanchangMonthState> {
  final PanchangRepository _repository;
  int _currentYear;
  int _currentMonth;

  PanchangMonthCubit({required PanchangRepository repository})
      : _repository = repository,
        _currentYear = DateTime.now().year,
        _currentMonth = DateTime.now().month,
        super(const PanchangMonthInitial());

  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;

  Future<void> loadCurrentMonth() async {
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    await _loadMonth();
  }

  Future<void> loadMonth(int year, int month) async {
    _currentYear = year;
    _currentMonth = month;
    await _loadMonth();
  }

  Future<void> nextMonth() async {
    if (_currentMonth == 12) {
      _currentMonth = 1;
      _currentYear++;
    } else {
      _currentMonth++;
    }
    await _loadMonth();
  }

  Future<void> previousMonth() async {
    if (_currentMonth == 1) {
      _currentMonth = 12;
      _currentYear--;
    } else {
      _currentMonth--;
    }
    await _loadMonth();
  }

  Future<void> _loadMonth() async {
    try {
      if (isClosed) return;
      emit(PanchangMonthLoading(year: _currentYear, month: _currentMonth));
      final data = await _repository.getMonth(
        year: _currentYear,
        month: _currentMonth,
      );
      if (isClosed) return;
      emit(PanchangMonthSuccess(data: data));
    } catch (e) {
      if (isClosed) return;
      emit(PanchangMonthError(
        message: AppErrorHelper.getErrorMessage(e),
        year: _currentYear,
        month: _currentMonth,
      ));
    }
  }
}
