import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/helpers/app_error_helper.dart';

import '../../repositories/panchang_repository.dart';
import 'panchang_vrat_state.dart';

class PanchangVratCubit extends Cubit<PanchangVratState> {
	final PanchangRepository _repository;

	PanchangVratCubit({required PanchangRepository repository})
			: _repository = repository,
				super(const PanchangVratInitial());

	Future<void> loadVrats({int days = 90}) async {
		try {
			if (isClosed) return;
			emit(const PanchangVratLoading());

			final calendar = await _repository.getVratCalendar(days: days);

			if (isClosed) return;
			emit(PanchangVratSuccess(calendar: calendar));
		} catch (e) {
			if (isClosed) return;
			emit(PanchangVratError(AppErrorHelper.getErrorMessage(e)));
		}
	}

	Future<void> loadVratsRange({
		required DateTime start,
		required DateTime end,
	}) async {
		try {
			if (isClosed) return;
			emit(const PanchangVratLoading());

			final calendar = await _repository.getVratCalendar(
				start: start,
				end: end,
			);

			if (isClosed) return;
			emit(PanchangVratSuccess(calendar: calendar));
		} catch (e) {
			if (isClosed) return;
			emit(PanchangVratError(AppErrorHelper.getErrorMessage(e)));
		}
	}

	void filterByImportance(String? importance) {
		final current = state;
		if (current is PanchangVratSuccess) {
			if (importance == null) {
				emit(current.copyWith(clearImportance: true));
			} else {
				emit(current.copyWith(selectedImportance: importance));
			}
		}
	}
}

