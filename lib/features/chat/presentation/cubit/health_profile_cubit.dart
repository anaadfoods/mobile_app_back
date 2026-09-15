import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/api_config.dart';
import 'package:grocery_app/utils/app_logger.dart';
import '../../domain/entities/body_type_entity.dart';
import '../../domain/entities/food_thali_item_entity.dart';
import '../../domain/entities/medical_report_item_entity.dart';
import '../../domain/entities/summary_dossier_entity.dart';
import 'health_profile_state.dart';

class HealthProfileCubit extends Cubit<HealthProfileState> {
  final ApiClient _apiClient;

  HealthProfileCubit({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance,
        super(const HealthProfileInitial());

  Map<String, dynamic> _extractMap(dynamic resData) {
    if (resData is Map<String, dynamic>) {
      if (resData.containsKey('data') && resData['data'] is Map<String, dynamic>) {
        return resData['data'] as Map<String, dynamic>;
      }
      return resData;
    }
    return {};
  }

  List<dynamic> _extractList(dynamic resData) {
    if (resData is List) {
      return resData;
    }
    if (resData is Map<String, dynamic>) {
      if (resData['data'] is List) {
        return resData['data'] as List<dynamic>;
      }
      if (resData['results'] is List) {
        return resData['results'] as List<dynamic>;
      }
    }
    return [];
  }

  Future<void> loadHealthProfileData() async {
    emit(const HealthProfileLoading());
    try {
      // 1. Fetch Body Type from Backend Assessment API
      final bodyTypeRes = await _apiClient.get(ApiConfig.healthProfileBodyTypeEndpoint);
      final bodyTypeData = _extractMap(bodyTypeRes.data);
      final bodyType = BodyTypeEntity.fromJson(bodyTypeData);

      // 2. Fetch Food Thalis
      final thaliRes = await _apiClient.get(ApiConfig.foodThaliEndpoint);
      final thaliList = _extractList(thaliRes.data);
      final thalis = thaliList
          .map((t) => FoodThaliItemEntity.fromJson(t as Map<String, dynamic>))
          .toList();

      // 3. Fetch Medical Reports
      final reportRes = await _apiClient.get(ApiConfig.medicalReportsEndpoint);
      final reportList = _extractList(reportRes.data);
      final reports = reportList
          .map((r) => MedicalReportItemEntity.fromJson(r as Map<String, dynamic>))
          .toList();

      // 4. Fetch Summary Dossier
      final summaryRes = await _apiClient.get(ApiConfig.healthProfileSummaryEndpoint);
      final summaryData = _extractMap(summaryRes.data);
      final summary = SummaryDossierEntity.fromJson(summaryData);

      // 5. Fetch Conditions & Allergies from base profile
      final baseProfileRes = await _apiClient.get(ApiConfig.healthProfileEndpoint);
      final baseData = _extractMap(baseProfileRes.data);
      final conditions = (baseData['medical_conditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final allergies = (baseData['allergies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      emit(HealthProfileLoaded(
        bodyType: bodyType,
        thalis: thalis,
        reports: reports,
        summary: summary,
        medicalConditions: conditions,
        allergies: allergies,
      ));
    } catch (e, stack) {
      AppLogger.error('Failed to load health profile memory data', e, stack);
      emit(HealthProfileError(
        message: 'Could not load health memory. Please check your connection. ($e)',
      ));
    }
  }

  Future<SummaryDossierEntity?> generateSummaryDocument() async {
    final currentState = state;
    if (currentState is! HealthProfileLoaded) return null;

    emit(currentState.copyWith(isGeneratingSummary: true));
    try {
      final res = await _apiClient.post(ApiConfig.healthProfileGenerateSummaryDocEndpoint);
      final summaryData = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
      final updatedSummary = SummaryDossierEntity.fromJson(summaryData);
      emit(currentState.copyWith(summary: updatedSummary, isGeneratingSummary: false));
      return updatedSummary;
    } catch (e, stack) {
      AppLogger.error('Failed to generate summary document', e, stack);
      emit(currentState.copyWith(isGeneratingSummary: false));
      return null;
    }
  }

  Future<void> updateDosha(String dosha) async {
    try {
      await _apiClient.post(
        ApiConfig.healthProfileEndpoint,
        data: {'prakriti_dosha': dosha},
      );
      await loadHealthProfileData();
    } catch (e) {
      AppLogger.error('Failed to update dosha', e);
    }
  }

  Future<void> addCondition(String condition) async {
    final currentState = state;
    if (currentState is! HealthProfileLoaded) return;
    try {
      final updated = List<String>.from(currentState.medicalConditions)..add(condition);
      await _apiClient.post(
        ApiConfig.healthProfileEndpoint,
        data: {'medical_conditions': updated},
      );
      emit(currentState.copyWith(medicalConditions: updated));
    } catch (e) {
      AppLogger.error('Failed to add medical condition', e);
    }
  }

  Future<void> removeCondition(String condition) async {
    final currentState = state;
    if (currentState is! HealthProfileLoaded) return;
    try {
      final updated = List<String>.from(currentState.medicalConditions)..remove(condition);
      await _apiClient.post(
        ApiConfig.healthProfileEndpoint,
        data: {'medical_conditions': updated},
      );
      emit(currentState.copyWith(medicalConditions: updated));
    } catch (e) {
      AppLogger.error('Failed to remove medical condition', e);
    }
  }

  Future<void> addAllergy(String allergy) async {
    final currentState = state;
    if (currentState is! HealthProfileLoaded) return;
    try {
      final updated = List<String>.from(currentState.allergies)..add(allergy);
      await _apiClient.post(
        ApiConfig.healthProfileEndpoint,
        data: {'allergies': updated},
      );
      emit(currentState.copyWith(allergies: updated));
    } catch (e) {
      AppLogger.error('Failed to add allergy', e);
    }
  }

  Future<void> removeAllergy(String allergy) async {
    final currentState = state;
    if (currentState is! HealthProfileLoaded) return;
    try {
      final updated = List<String>.from(currentState.allergies)..remove(allergy);
      await _apiClient.post(
        ApiConfig.healthProfileEndpoint,
        data: {'allergies': updated},
      );
      emit(currentState.copyWith(allergies: updated));
    } catch (e) {
      AppLogger.error('Failed to remove allergy', e);
    }
  }

  Future<bool> uploadMedicalReport({
    required File file,
    String reportType = 'BLOOD_TEST',
    String title = 'Medical Report',
  }) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'title': title,
        'report_type': reportType,
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      await _apiClient.post(
        ApiConfig.medicalReportsEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadHealthProfileData();
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to upload medical report', e, stack);
      return false;
    }
  }

  Future<bool> uploadFoodThali({
    required File imageFile,
    String mealType = 'LUNCH',
    String notes = '',
  }) async {
    try {
      final fileName = imageFile.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'meal_type': mealType,
        'notes': notes,
        'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      await _apiClient.post(
        ApiConfig.foodThaliEndpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadHealthProfileData();
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to upload food thali', e, stack);
      return false;
    }
  }
}
