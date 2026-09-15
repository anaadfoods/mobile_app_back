import 'package:equatable/equatable.dart';

/// Discrete biomarker measurement model
class MedicalMarkerEntity extends Equatable {
  final int id;
  final String name;
  final String standardizedCode;
  final double? value;
  final String unit;
  final double? referenceRangeMin;
  final double? referenceRangeMax;
  final bool isAbnormal;
  final String flag;
  final String notes;

  const MedicalMarkerEntity({
    required this.id,
    required this.name,
    required this.standardizedCode,
    this.value,
    required this.unit,
    this.referenceRangeMin,
    this.referenceRangeMax,
    required this.isAbnormal,
    required this.flag,
    required this.notes,
  });

  factory MedicalMarkerEntity.fromJson(Map<String, dynamic> json) {
    return MedicalMarkerEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      standardizedCode: json['standardized_code'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? '',
      referenceRangeMin: (json['reference_range_min'] as num?)?.toDouble(),
      referenceRangeMax: (json['reference_range_max'] as num?)?.toDouble(),
      isAbnormal: json['is_abnormal'] as bool? ?? false,
      flag: json['flag'] as String? ?? 'NORMAL',
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        standardizedCode,
        value,
        unit,
        referenceRangeMin,
        referenceRangeMax,
        isAbnormal,
        flag,
        notes,
      ];
}

/// Domain entity representing an uploaded Medical OCR Report.
class MedicalReportItemEntity extends Equatable {
  final int id;
  final String title;
  final String reportType;
  final String reportTypeDisplay;
  final String status;
  final String statusDisplay;
  final String fileUrl;
  final String description;
  final List<String> extractedKeywords;
  final List<MedicalMarkerEntity> markers;
  final String uploadedAt;
  final String uploadedDate;

  const MedicalReportItemEntity({
    required this.id,
    required this.title,
    required this.reportType,
    required this.reportTypeDisplay,
    required this.status,
    required this.statusDisplay,
    required this.fileUrl,
    required this.description,
    required this.extractedKeywords,
    required this.markers,
    required this.uploadedAt,
    required this.uploadedDate,
  });

  factory MedicalReportItemEntity.fromJson(Map<String, dynamic> json) {
    final rawMarkers = json['markers'] as List<dynamic>? ?? [];
    return MedicalReportItemEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Medical Report',
      reportType: json['report_type'] as String? ?? 'OTHER',
      reportTypeDisplay: json['report_type_display'] as String? ?? 'Document',
      status: json['status'] as String? ?? 'COMPLETED',
      statusDisplay: json['status_display'] as String? ?? 'Completed',
      fileUrl: json['file_url'] as String? ?? '',
      description: json['description'] as String? ?? (json['summary'] as String? ?? ''),
      extractedKeywords: (json['extracted_keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      markers: rawMarkers.map((m) => MedicalMarkerEntity.fromJson(m as Map<String, dynamic>)).toList(),
      uploadedAt: json['uploaded_at'] as String? ?? '',
      uploadedDate: json['uploaded_date'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        reportType,
        reportTypeDisplay,
        status,
        statusDisplay,
        fileUrl,
        description,
        extractedKeywords,
        markers,
        uploadedAt,
        uploadedDate,
      ];
}
