// lib/features/panchang/presentation/cubit/kundli_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/kundli_entities.dart';

abstract class KundliState extends Equatable {
  const KundliState();

  @override
  List<Object?> get props => [];
}

class KundliInitial extends KundliState {
  const KundliInitial();
}

class KundliLoading extends KundliState {
  const KundliLoading();
}

class KundliPendingDetails extends KundliState {
  final KundliBirthDetails? savedDetails;
  const KundliPendingDetails({this.savedDetails});

  @override
  List<Object?> get props => [savedDetails];
}

class KundliLoaded extends KundliState {
  final KundliEntity kundli;
  final bool isNorthIndianFormat;
  final bool isTemporary;

  const KundliLoaded({
    required this.kundli,
    this.isNorthIndianFormat = true,
    this.isTemporary = false,
  });

  KundliLoaded copyWith({
    KundliEntity? kundli,
    bool? isNorthIndianFormat,
    bool? isTemporary,
  }) {
    return KundliLoaded(
      kundli: kundli ?? this.kundli,
      isNorthIndianFormat: isNorthIndianFormat ?? this.isNorthIndianFormat,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  @override
  List<Object?> get props => [kundli, isNorthIndianFormat, isTemporary];
}

class KundliError extends KundliState {
  final String message;

  const KundliError(this.message);

  @override
  List<Object?> get props => [message];
}
