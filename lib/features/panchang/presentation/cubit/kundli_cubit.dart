// lib/features/panchang/presentation/cubit/kundli_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/kundli_entities.dart';
import '../../domain/usecases/get_user_kundli_use_case.dart';
import '../../domain/usecases/generate_kundli_use_case.dart';
import '../../domain/usecases/get_birth_details_use_case.dart';
import '../../domain/usecases/save_birth_details_use_case.dart';
import 'kundli_state.dart';

class KundliCubit extends Cubit<KundliState> {
  final GetUserKundliUseCase _getUserKundliUseCase;
  final GenerateKundliUseCase _generateKundliUseCase;
  final GetBirthDetailsUseCase _getBirthDetailsUseCase;
  final SaveBirthDetailsUseCase _saveBirthDetailsUseCase;

  KundliCubit({
    required GetUserKundliUseCase getUserKundliUseCase,
    required GenerateKundliUseCase generateKundliUseCase,
    required GetBirthDetailsUseCase getBirthDetailsUseCase,
    required SaveBirthDetailsUseCase saveBirthDetailsUseCase,
  })  : _getUserKundliUseCase = getUserKundliUseCase,
        _generateKundliUseCase = generateKundliUseCase,
        _getBirthDetailsUseCase = getBirthDetailsUseCase,
        _saveBirthDetailsUseCase = saveBirthDetailsUseCase,
        super(const KundliInitial());

  Future<void> loadUserKundli() async {
    emit(const KundliLoading());
    try {
      final kundli = await _getUserKundliUseCase();
      if (kundli != null) {
        emit(KundliLoaded(kundli: kundli, isTemporary: false));
      } else {
        final saved = await _getBirthDetailsUseCase();
        emit(KundliPendingDetails(savedDetails: saved));
      }
    } catch (e) {
      emit(KundliError(e.toString()));
    }
  }

  void showKundli(KundliEntity kundli, {bool isTemporary = false}) {
    emit(KundliLoaded(kundli: kundli, isTemporary: isTemporary));
  }

  Future<KundliEntity?> generateAndSaveKundli({
    required String dateOfBirth,
    required String timeOfBirth,
    String name = '',
    required String birthCity,
    String birthState = '',
    String birthCountry = 'India',
    required double latitude,
    required double longitude,
    String timezone = 'Asia/Kolkata',
    bool saveToProfile = true,
  }) async {
    emit(const KundliLoading());
    try {
      if (saveToProfile) {
        await _saveBirthDetailsUseCase(
          dateOfBirth: dateOfBirth,
          timeOfBirth: timeOfBirth,
          name: name,
          birthCity: birthCity,
          birthState: birthState,
          birthCountry: birthCountry,
          latitude: latitude,
          longitude: longitude,
          timezone: timezone,
        );
      }

      final kundli = await _generateKundliUseCase(
        dateOfBirth: dateOfBirth,
        timeOfBirth: timeOfBirth,
        name: name,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
        birthCity: birthCity,
        birthState: birthState,
        saveToProfile: saveToProfile,
      );

      emit(KundliLoaded(kundli: kundli, isTemporary: !saveToProfile));
      return kundli;
    } catch (e) {
      emit(KundliError(e.toString()));
      return null;
    }
  }

  Future<bool> saveBirthDetailsToProfile({
    required String dateOfBirth,
    required String timeOfBirth,
    String name = '',
    required String birthCity,
    String birthState = '',
    String birthCountry = 'India',
    required double latitude,
    required double longitude,
    String timezone = 'Asia/Kolkata',
  }) async {
    try {
      final success = await _saveBirthDetailsUseCase(
        dateOfBirth: dateOfBirth,
        timeOfBirth: timeOfBirth,
        name: name,
        birthCity: birthCity,
        birthState: birthState,
        birthCountry: birthCountry,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
      );
      if (success && state is KundliLoaded) {
        final current = state as KundliLoaded;
        emit(current.copyWith(isTemporary: false));
      }
      return success;
    } catch (e) {
      emit(KundliError(e.toString()));
      return false;
    }
  }

  void toggleChartFormat() {
    if (state is KundliLoaded) {
      final current = state as KundliLoaded;
      emit(current.copyWith(isNorthIndianFormat: !current.isNorthIndianFormat));
    }
  }
}
