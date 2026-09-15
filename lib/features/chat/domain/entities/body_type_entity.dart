import 'package:equatable/equatable.dart';

/// User's answered question response from backend DB.
class AssessmentAnswerEntity extends Equatable {
  final String questionCode;
  final int order;
  final String category;
  final String questionEn;
  final String questionHi;
  final String selectedOptionId;
  final String selectedText;
  final String? answeredAt;

  const AssessmentAnswerEntity({
    required this.questionCode,
    required this.order,
    required this.category,
    required this.questionEn,
    required this.questionHi,
    required this.selectedOptionId,
    required this.selectedText,
    this.answeredAt,
  });

  factory AssessmentAnswerEntity.fromJson(Map<String, dynamic> json) {
    return AssessmentAnswerEntity(
      questionCode: json['question_code'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      questionEn: json['question_en'] as String? ?? '',
      questionHi: json['question_hi'] as String? ?? '',
      selectedOptionId: json['selected_option_id'] as String? ?? '',
      selectedText: json['selected_text'] as String? ?? '',
      answeredAt: json['answered_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        questionCode,
        order,
        category,
        questionEn,
        questionHi,
        selectedOptionId,
        selectedText,
        answeredAt,
      ];
}

/// 40-Day Assessment Lifecycle tracking entity.
class AssessmentLifecycleEntity extends Equatable {
  final int cycleDays;
  final int? daysSinceLast;
  final int daysRemaining;
  final bool isDue;
  final String? lastAssessmentAt;
  final String statusLabel;

  const AssessmentLifecycleEntity({
    required this.cycleDays,
    this.daysSinceLast,
    required this.daysRemaining,
    required this.isDue,
    this.lastAssessmentAt,
    required this.statusLabel,
  });

  factory AssessmentLifecycleEntity.fromJson(Map<String, dynamic> json) {
    return AssessmentLifecycleEntity(
      cycleDays: (json['cycle_days'] as num?)?.toInt() ?? 40,
      daysSinceLast: (json['days_since_last'] as num?)?.toInt(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      isDue: json['is_due'] as bool? ?? true,
      lastAssessmentAt: json['last_assessment_at'] as String?,
      statusLabel: json['status_label'] as String? ?? 'Assessment Due Now',
    );
  }

  @override
  List<Object?> get props => [
        cycleDays,
        daysSinceLast,
        daysRemaining,
        isDue,
        lastAssessmentAt,
        statusLabel,
      ];
}

/// Domain entity representing the user's Ayurvedic Body Type (Prakriti),
/// elemental breakdown, 'What it is', 'Why it is', 40-day cycle, and past answers from DB.
class BodyTypeEntity extends Equatable {
  final bool isAssessed;
  final String prakriti;
  final String title;
  final String primaryDosha;
  final String secondaryDosha;
  final int vataScore;
  final int pittaScore;
  final int kaphaScore;
  final String whatIsIt;
  final String whyIsIt;
  final String whyIsItRequired;
  final List<String> characteristics;
  final List<String> keyFoods;
  final List<String> tastesToFavor;
  final List<String> tastesToMinimize;
  final List<String> lifestyleGuidelines;
  final String lagnaAscendant;
  final String janmaRashi;
  final String janmaNakshatra;
  final String imbalanceDosha;
  final AssessmentLifecycleEntity lifecycle;
  final List<AssessmentAnswerEntity> answeredQuestions;

  const BodyTypeEntity({
    this.isAssessed = true,
    required this.prakriti,
    required this.title,
    required this.primaryDosha,
    required this.secondaryDosha,
    required this.vataScore,
    required this.pittaScore,
    required this.kaphaScore,
    required this.whatIsIt,
    required this.whyIsIt,
    required this.whyIsItRequired,
    required this.characteristics,
    required this.keyFoods,
    required this.tastesToFavor,
    required this.tastesToMinimize,
    required this.lifestyleGuidelines,
    required this.lagnaAscendant,
    required this.janmaRashi,
    required this.janmaNakshatra,
    required this.imbalanceDosha,
    required this.lifecycle,
    required this.answeredQuestions,
  });

  bool get hasAssessment => isAssessed && primaryDosha.isNotEmpty && primaryDosha != 'None' && (vataScore + pittaScore + kaphaScore > 0);

  factory BodyTypeEntity.fromJson(Map<String, dynamic> json) {
    final scores = json['scores'] as Map<String, dynamic>? ?? {};
    final diet = json['balancing_diet'] as Map<String, dynamic>? ?? {};
    final kundli = json['kundli_alignment'] as Map<String, dynamic>? ?? {};
    final imbalance = json['imbalance_status'] as Map<String, dynamic>? ?? {};
    final lifecycleJson = json['assessment_lifecycle'] as Map<String, dynamic>? ?? {};
    final answersList = json['answered_questions'] as List<dynamic>? ?? [];

    final assessed = json['is_assessed'] as bool? ??
        (json['has_assessment'] as bool? ??
            (json['prakriti'] != null &&
                json['prakriti'].toString().isNotEmpty &&
                json['prakriti'] != 'NOT_STARTED'));

    return BodyTypeEntity(
      isAssessed: assessed,
      prakriti: json['prakriti'] as String? ?? (assessed ? 'PITTA_VATA' : ''),
      title: json['title'] as String? ?? (assessed ? 'Pitta-Vata Dual Constitution' : 'Assessment Required'),
      primaryDosha: json['primary_dosha'] as String? ?? (assessed ? 'Pitta' : ''),
      secondaryDosha: json['secondary_dosha'] as String? ?? (assessed ? 'Vata' : ''),
      vataScore: (scores['vata'] as num?)?.toInt() ?? (assessed ? 35 : 0),
      pittaScore: (scores['pitta'] as num?)?.toInt() ?? (assessed ? 45 : 0),
      kaphaScore: (scores['kapha'] as num?)?.toInt() ?? (assessed ? 20 : 0),
      whatIsIt: json['what_is_it'] as String? ?? '',
      whyIsIt: json['why_it_is'] as String? ?? '',
      whyIsItRequired: json['why_is_it_required'] as String? ?? '',
      characteristics: (json['characteristics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      keyFoods: (diet['key_foods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tastesToFavor: (diet['tastes_to_favor'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tastesToMinimize: (diet['tastes_to_minimize'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lifestyleGuidelines: (json['lifestyle_guidelines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lagnaAscendant: kundli['lagna_ascendant'] as String? ?? 'Not Set',
      janmaRashi: kundli['janma_rashi'] as String? ?? 'Not Set',
      janmaNakshatra: kundli['janma_nakshatra'] as String? ?? 'Not Set',
      imbalanceDosha: imbalance['imbalance_dosha'] as String? ?? 'None',
      lifecycle: AssessmentLifecycleEntity.fromJson(lifecycleJson),
      answeredQuestions: answersList.map((e) => AssessmentAnswerEntity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [
        prakriti,
        title,
        primaryDosha,
        secondaryDosha,
        vataScore,
        pittaScore,
        kaphaScore,
        whatIsIt,
        whyIsIt,
        whyIsItRequired,
        characteristics,
        keyFoods,
        tastesToFavor,
        tastesToMinimize,
        lifestyleGuidelines,
        lagnaAscendant,
        janmaRashi,
        janmaNakshatra,
        imbalanceDosha,
        lifecycle,
        answeredQuestions,
      ];
}
