import 'package:equatable/equatable.dart';

import '../../models/panchang/panchang_day_models.dart';
import '../../models/panchang/panchang_highlights_models.dart';
import '../../models/panchang/panchang_muhurats_models.dart';

abstract class PanchangHomeState extends Equatable {
  const PanchangHomeState();

  @override
  List<Object?> get props => [];
}

class PanchangHomeInitial extends PanchangHomeState {
  const PanchangHomeInitial();
}

class PanchangHomeLoading extends PanchangHomeState {
  const PanchangHomeLoading();
}

class PanchangHomeSuccess extends PanchangHomeState {
  final PanchangDayResponse day;
  final DateTime selectedDate;
  final PanchangHighlightsResponse? highlights;

  const PanchangHomeSuccess({
    required this.day,
    required this.selectedDate,
    this.highlights,
  });

  @override
  List<Object?> get props => [day, selectedDate, highlights];
}

class PanchangHomeError extends PanchangHomeState {
  final String message;

  const PanchangHomeError(this.message);

  @override
  List<Object?> get props => [message];
}

class PanchangMuhuratsLoading extends PanchangHomeState {
  const PanchangMuhuratsLoading();
}

class PanchangMuhuratsSuccess extends PanchangHomeState {
  final PanchangMuhuratsResponse muhurats;
  final DateTime selectedDate;

  const PanchangMuhuratsSuccess({
    required this.muhurats,
    required this.selectedDate,
  });

  @override
  List<Object?> get props => [muhurats, selectedDate];
}
