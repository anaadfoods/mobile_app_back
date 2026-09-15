/// Domain entity representing a health observation extracted from user's chat.
/// This is returned by the AI when it detects a food-symptom association.
class HealthObservation {
  /// Type identifier, always 'health_observation'
  final String type;
  /// The food item mentioned (e.g. 'Kurkure')
  final String food;
  /// The symptom reported (e.g. 'mild fever')
  final String symptom;
  /// Causality status: 'user_reported_unconfirmed'
  final String causality;
  /// Whether save was already requested
  final bool saveRequested;
  /// Whether user consent is required before saving
  final bool requiresConsent;
  /// Backend disclaimer/explanatory message
  final String message;

  const HealthObservation({
    required this.type,
    required this.food,
    required this.symptom,
    required this.causality,
    required this.saveRequested,
    required this.requiresConsent,
    required this.message,
  });

  factory HealthObservation.fromJson(Map<String, dynamic> json) {
    return HealthObservation(
      type: json['type'] as String? ?? 'health_observation',
      food: json['food'] as String? ?? '',
      symptom: json['symptom'] as String? ?? '',
      causality: json['causality'] as String? ?? 'user_reported_unconfirmed',
      saveRequested: json['save_requested'] as bool? ?? false,
      requiresConsent: json['requires_consent'] as bool? ?? true,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'food': food,
    'symptom': symptom,
    'causality': causality,
    'save_requested': saveRequested,
    'requires_consent': requiresConsent,
    'message': message,
  };
}
