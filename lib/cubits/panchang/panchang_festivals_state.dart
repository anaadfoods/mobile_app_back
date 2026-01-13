import 'package:equatable/equatable.dart';

import '../../models/panchang/panchang_festival_models.dart';

abstract class PanchangFestivalsState extends Equatable {
  const PanchangFestivalsState();

  @override
  List<Object?> get props => [];
}

class PanchangFestivalsInitial extends PanchangFestivalsState {
  const PanchangFestivalsInitial();
}

class PanchangFestivalsLoading extends PanchangFestivalsState {
  const PanchangFestivalsLoading();
}

class PanchangFestivalsSuccess extends PanchangFestivalsState {
  final PanchangFestivalsResponse response;
  final DateTime startDate;
  final DateTime endDate;
  final String? filterType;

  const PanchangFestivalsSuccess({
    required this.response,
    required this.startDate,
    required this.endDate,
    this.filterType,
  });

  @override
  List<Object?> get props => [response, startDate, endDate, filterType];
}

class PanchangFestivalsSearching extends PanchangFestivalsState {
  const PanchangFestivalsSearching();
}

class PanchangFestivalsSearchSuccess extends PanchangFestivalsState {
  final FestivalSearchResponse response;
  final String query;

  const PanchangFestivalsSearchSuccess({
    required this.response,
    required this.query,
  });

  @override
  List<Object?> get props => [response, query];
}

class PanchangFestivalsError extends PanchangFestivalsState {
  final String message;

  const PanchangFestivalsError(this.message);

  @override
  List<Object?> get props => [message];
}
