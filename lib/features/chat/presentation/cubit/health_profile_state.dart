import 'package:equatable/equatable.dart';
import '../../domain/entities/body_type_entity.dart';
import '../../domain/entities/food_thali_item_entity.dart';
import '../../domain/entities/medical_report_item_entity.dart';
import '../../domain/entities/summary_dossier_entity.dart';

abstract class HealthProfileState extends Equatable {
  const HealthProfileState();

  @override
  List<Object?> get props => [];
}

class HealthProfileInitial extends HealthProfileState {
  const HealthProfileInitial();
}

class HealthProfileLoading extends HealthProfileState {
  const HealthProfileLoading();
}

class HealthProfileLoaded extends HealthProfileState {
  final BodyTypeEntity bodyType;
  final List<FoodThaliItemEntity> thalis;
  final List<MedicalReportItemEntity> reports;
  final SummaryDossierEntity summary;
  final List<String> medicalConditions;
  final List<String> allergies;
  final bool isGeneratingSummary;

  const HealthProfileLoaded({
    required this.bodyType,
    required this.thalis,
    required this.reports,
    required this.summary,
    required this.medicalConditions,
    required this.allergies,
    this.isGeneratingSummary = false,
  });

  HealthProfileLoaded copyWith({
    BodyTypeEntity? bodyType,
    List<FoodThaliItemEntity>? thalis,
    List<MedicalReportItemEntity>? reports,
    SummaryDossierEntity? summary,
    List<String>? medicalConditions,
    List<String>? allergies,
    bool? isGeneratingSummary,
  }) {
    return HealthProfileLoaded(
      bodyType: bodyType ?? this.bodyType,
      thalis: thalis ?? this.thalis,
      reports: reports ?? this.reports,
      summary: summary ?? this.summary,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      isGeneratingSummary: isGeneratingSummary ?? this.isGeneratingSummary,
    );
  }

  @override
  List<Object?> get props => [
        bodyType,
        thalis,
        reports,
        summary,
        medicalConditions,
        allergies,
        isGeneratingSummary,
      ];
}

class HealthProfileError extends HealthProfileState {
  final String message;

  const HealthProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
