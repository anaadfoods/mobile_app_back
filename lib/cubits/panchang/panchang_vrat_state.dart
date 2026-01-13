import 'package:equatable/equatable.dart';

import '../../models/panchang/panchang_vrat_models.dart';

abstract class PanchangVratState extends Equatable {
	const PanchangVratState();

	@override
	List<Object?> get props => [];
}

class PanchangVratInitial extends PanchangVratState {
	const PanchangVratInitial();
}

class PanchangVratLoading extends PanchangVratState {
	const PanchangVratLoading();
}

class PanchangVratSuccess extends PanchangVratState {
	final VratCalendarResponse calendar;
	final String? selectedImportance; // null | 'high' | 'medium' | 'low'

	const PanchangVratSuccess({
		required this.calendar,
		this.selectedImportance,
	});

	@override
	List<Object?> get props => [calendar, selectedImportance];

	List<VratItem> get filteredItems {
		final importance = selectedImportance;
		if (importance == null) return calendar.items;
		return calendar.items
				.where((item) => item.importanceLower == importance)
				.toList();
	}

	PanchangVratSuccess copyWith({
		VratCalendarResponse? calendar,
		String? selectedImportance,
		bool clearImportance = false,
	}) {
		return PanchangVratSuccess(
			calendar: calendar ?? this.calendar,
			selectedImportance: clearImportance ? null : selectedImportance ?? this.selectedImportance,
		);
	}
}

class PanchangVratError extends PanchangVratState {
	final String message;

	const PanchangVratError(this.message);

	@override
	List<Object?> get props => [message];
}

