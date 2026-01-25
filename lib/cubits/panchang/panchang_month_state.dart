import 'package:equatable/equatable.dart';

import '../../models/panchang/panchang_month_models.dart';

abstract class PanchangMonthState extends Equatable {
  const PanchangMonthState();

  @override
  List<Object?> get props => [];
}

class PanchangMonthInitial extends PanchangMonthState {
  const PanchangMonthInitial();
}

class PanchangMonthLoading extends PanchangMonthState {
  final int year;
  final int month;

  const PanchangMonthLoading({required this.year, required this.month});

  @override
  List<Object?> get props => [year, month];
}

class PanchangMonthSuccess extends PanchangMonthState {
  final PanchangMonthResponse data;

  const PanchangMonthSuccess({required this.data});

  @override
  List<Object?> get props => [data];
}

class PanchangMonthError extends PanchangMonthState {
  final String message;
  final int year;
  final int month;

  const PanchangMonthError({
    required this.message,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [message, year, month];
}
