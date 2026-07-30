import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/repositories/panchang_repository.dart';
import 'package:grocery_app/models/panchang/panchang_guidance_models.dart';
import 'panchang_guidance_state.dart';

/// Cubit for managing Panchang Guidance feature state
class PanchangGuidanceCubit extends Cubit<PanchangGuidanceState> {
  final PanchangRepository repository;

  PanchangGuidanceCubit({required this.repository})
      : super(const PanchangGuidanceInitial());

  /// Load today's guidance
  Future<void> loadTodayGuidance({
    DateTime? date,
    double? lat,
    double? lon,
  }) async {
    emit(const PanchangGuidanceLoading());
    try {
      final guidance = await repository.getTodayGuidance(
        date: date,
        lat: lat,
        lon: lon,
      );
      emit(PanchangGuidanceSuccess(guidance: guidance));
    } catch (e) {
      emit(PanchangGuidanceError(message: e.toString()));
    }
  }

  /// Load guidance (alias for loadTodayGuidance)
  Future<void> loadGuidance() => loadTodayGuidance();

  /// Load user's guidance profile/preferences
  Future<void> loadProfile() async {
    emit(const PanchangProfileLoading());
    try {
      final profile = await repository.getGuidanceProfile();
      emit(PanchangProfileSuccess(profile: profile));
    } catch (e) {
      emit(PanchangProfileError(message: e.toString()));
    }
  }

  /// Save user's guidance profile/preferences
  Future<void> saveProfile(GuidanceProfileRequest request) async {
    emit(const PanchangProfileLoading());
    try {
      final profile = await repository.saveGuidanceProfile(request);
      emit(PanchangProfileSaved(profile: profile));
    } catch (e) {
      emit(PanchangProfileError(message: e.toString()));
    }
  }
}


