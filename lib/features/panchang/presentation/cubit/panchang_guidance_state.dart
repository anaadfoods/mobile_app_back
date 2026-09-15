// lib/features/panchang/presentation/cubit/panchang_guidance_state.dart
import 'package:equatable/equatable.dart';
import '../../../../models/panchang/panchang_guidance_models.dart';

abstract class PanchangGuidanceState extends Equatable {
  const PanchangGuidanceState();

  @override
  List<Object?> get props => [];
}

class PanchangGuidanceInitial extends PanchangGuidanceState {
  const PanchangGuidanceInitial();
}

class PanchangGuidanceLoading extends PanchangGuidanceState {
  const PanchangGuidanceLoading();
}

class PanchangGuidanceSuccess extends PanchangGuidanceState {
  final GuidanceTodayResponse guidance;

  const PanchangGuidanceSuccess({required this.guidance});

  @override
  List<Object?> get props => [guidance];
}

class PanchangGuidanceError extends PanchangGuidanceState {
  final String message;

  const PanchangGuidanceError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PanchangProfileLoading extends PanchangGuidanceState {
  const PanchangProfileLoading();
}

class PanchangProfileSuccess extends PanchangGuidanceState {
  final GuidanceProfileResponse profile;

  const PanchangProfileSuccess({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class PanchangProfileError extends PanchangGuidanceState {
  final String message;

  const PanchangProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PanchangProfileSaved extends PanchangGuidanceState {
  final GuidanceProfileResponse profile;

  const PanchangProfileSaved({required this.profile});

  @override
  List<Object?> get props => [profile];
}
