// lib/features/panchang/presentation/cubit/panchang_guidance_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../repositories/panchang_repository.dart';
import '../../../../models/panchang/panchang_guidance_models.dart';
import 'panchang_guidance_state.dart';

class PanchangGuidanceCubit extends Cubit<PanchangGuidanceState> {
  final PanchangRepository repository;

  PanchangGuidanceCubit({required this.repository})
      : super(const PanchangGuidanceInitial());

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

  Future<void> loadGuidance() => loadTodayGuidance();

  Future<void> loadProfile() async {
    emit(const PanchangProfileLoading());
    try {
      final profile = await repository.getGuidanceProfile();
      emit(PanchangProfileSuccess(profile: profile));
    } catch (e) {
      emit(PanchangProfileError(message: e.toString()));
    }
  }

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
