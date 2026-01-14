import 'package:equatable/equatable.dart';
import '../../models/panchang/panchang_guidance_models.dart';

/// Base state for Panchang Guidance feature
abstract class PanchangGuidanceState extends Equatable {
  const PanchangGuidanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PanchangGuidanceInitial extends PanchangGuidanceState {
  const PanchangGuidanceInitial();
}

/// Loading today's guidance
class PanchangGuidanceLoading extends PanchangGuidanceState {
  const PanchangGuidanceLoading();
}

/// Successfully loaded today's guidance
class PanchangGuidanceSuccess extends PanchangGuidanceState {
  final GuidanceTodayResponse guidance;

  const PanchangGuidanceSuccess({required this.guidance});

  @override
  List<Object?> get props => [guidance];
}

/// Error loading guidance
class PanchangGuidanceError extends PanchangGuidanceState {
  final String message;

  const PanchangGuidanceError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Loading user profile preferences
class PanchangProfileLoading extends PanchangGuidanceState {
  const PanchangProfileLoading();
}

/// Successfully loaded profile
class PanchangProfileSuccess extends PanchangGuidanceState {
  final GuidanceProfileResponse profile;

  const PanchangProfileSuccess({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// Error loading profile
class PanchangProfileError extends PanchangGuidanceState {
  final String message;

  const PanchangProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Profile saved successfully
class PanchangProfileSaved extends PanchangGuidanceState {
  final GuidanceProfileResponse profile;

  const PanchangProfileSaved({required this.profile});

  @override
  List<Object?> get props => [profile];
}

