class InjuryAssessment {
  final String? id;
  final String userId;
  final String bodyPart; // 'diz', 'omuz', 'bel', 'boyun', 'ayak bileği', 'dirsek', 'kalça'
  final String painType; // 'keskin', 'yanma', 'batma', 'donuk', 'zonklama', 'gerginlik'
  final List<String> triggeringMovements; // ['squat', 'koşu', 'ağırlık kaldırma']
  final Map<String, dynamic> functionalityTest; // {'range_of_motion': 'kısıtlı', 'strength': 'zayıf', 'stability': 'dengesiz'}
  final List<String> riskFactors; // ['geçmiş sakatlık', 'aşırı antrenman', 'yaş']
  final int severityScore; // 0-100 arası
  final String? recommendedInjuryType; // Analiz sonucu önerilen sakatlık tipi
  final List<String> recommendedExerciseIds; // Önerilen egzersiz ID'leri
  final String? recoveryStatus; // 'aktif', 'geçti', 'devam_ediyor'
  final DateTime? recoveryCheckedAt;
  final DateTime createdAt;

  InjuryAssessment({
    this.id,
    required this.userId,
    required this.bodyPart,
    required this.painType,
    required this.triggeringMovements,
    required this.functionalityTest,
    required this.riskFactors,
    required this.severityScore,
    this.recommendedInjuryType,
    required this.recommendedExerciseIds,
    this.recoveryStatus,
    this.recoveryCheckedAt,
    required this.createdAt,
  });

  bool get isRecovered => recoveryStatus == 'geçti';

  String get recoveryStatusDisplay {
    switch (recoveryStatus) {
      case 'geçti':
        return 'Geçti';
      case 'devam_ediyor':
        return 'Devam Ediyor';
      case 'aktif':
        return 'Aktif';
      default:
        return 'Belirsiz';
    }
  }

  factory InjuryAssessment.fromJson(Map<String, dynamic> json) {
    return InjuryAssessment(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      bodyPart: json['body_part'] as String,
      painType: json['pain_type'] as String,
      triggeringMovements: (json['triggering_movements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      functionalityTest: json['functionality_test'] as Map<String, dynamic>? ?? {},
      riskFactors: (json['risk_factors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      severityScore: json['severity_score'] as int? ?? 0,
      recommendedInjuryType: json['recommended_injury_type'] as String?,
      recommendedExerciseIds: (json['recommended_exercise_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recoveryStatus: json['recovery_status'] as String?,
      recoveryCheckedAt: json['recovery_checked_at'] != null
          ? DateTime.parse(json['recovery_checked_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'body_part': bodyPart,
      'pain_type': painType,
      'triggering_movements': triggeringMovements,
      'functionality_test': functionalityTest,
      'risk_factors': riskFactors,
      'severity_score': severityScore,
      'recommended_injury_type': recommendedInjuryType,
      'recommended_exercise_ids': recommendedExerciseIds,
      if (recoveryStatus != null) 'recovery_status': recoveryStatus,
      if (recoveryCheckedAt != null)
        'recovery_checked_at': recoveryCheckedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

