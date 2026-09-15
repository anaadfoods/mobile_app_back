import 'package:equatable/equatable.dart';

/// Domain entity representing a logged Food Thali with its photo,
/// detailed nutritional & Ayurvedic description, and symptom records.
class FoodThaliItemEntity extends Equatable {
  final int id;
  final String mealType;
  final String mealTypeDisplay;
  final List<String> thaliItems;
  final String imageUrl;
  final String description;
  final int? totalCalories;
  final double? carbsG;
  final double? proteinG;
  final double? fatG;
  final double? fiberG;
  final String glycemicLoad;
  final List<String> symptomsExperienced;
  final String notes;
  final String loggedAt;
  final String loggedDate;

  const FoodThaliItemEntity({
    required this.id,
    required this.mealType,
    required this.mealTypeDisplay,
    required this.thaliItems,
    required this.imageUrl,
    required this.description,
    this.totalCalories,
    this.carbsG,
    this.proteinG,
    this.fatG,
    this.fiberG,
    required this.glycemicLoad,
    required this.symptomsExperienced,
    required this.notes,
    required this.loggedAt,
    required this.loggedDate,
  });

  factory FoodThaliItemEntity.fromJson(Map<String, dynamic> json) {
    return FoodThaliItemEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      mealType: json['meal_type'] as String? ?? 'LUNCH',
      mealTypeDisplay: json['meal_type_display'] as String? ?? 'Lunch',
      thaliItems: (json['thali_items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      totalCalories: (json['total_calories'] as num?)?.toInt(),
      carbsG: (json['carbs_g'] as num?)?.toDouble(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      glycemicLoad: json['glycemic_load'] as String? ?? 'MEDIUM',
      symptomsExperienced: (json['symptoms_experienced'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      notes: json['notes'] as String? ?? '',
      loggedAt: json['logged_at'] as String? ?? '',
      loggedDate: json['logged_date'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        mealType,
        mealTypeDisplay,
        thaliItems,
        imageUrl,
        description,
        totalCalories,
        carbsG,
        proteinG,
        fatG,
        fiberG,
        glycemicLoad,
        symptomsExperienced,
        notes,
        loggedAt,
        loggedDate,
      ];
}
