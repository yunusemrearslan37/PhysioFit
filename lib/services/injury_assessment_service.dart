import '../config/supabase_config.dart';
import '../data/injury_assessment_guidance.dart';
import '../data/physical_therapy_data.dart';
import '../models/injury_assessment.dart';

class InjuryAssessmentService {
  final _supabase = SupabaseConfig.client;

  Future<InjuryAssessment> saveAssessment(InjuryAssessment assessment) async {
    try {
      final response = await _supabase
          .from('injury_assessments')
          .insert(assessment.toJson())
          .select()
          .single();

      return InjuryAssessment.fromJson(response);
    } catch (e) {
      throw Exception('Sakatlık analizi kaydetme hatası: $e');
    }
  }

  Future<List<InjuryAssessment>> getUserAssessments(String userId) async {
    try {
      final response = await _supabase
          .from('injury_assessments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => InjuryAssessment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Analiz geçmişi getirme hatası: $e');
    }
  }

  Future<InjuryAssessmentResult> assessInjuryRisk({
    required String bodyPart,
    required String painType,
    required List<String> triggeringMovements,
    required Map<String, dynamic> functionalityTest,
    required List<String> riskFactors,
    List<String> redFlags = const [],
    String? painDuration,
    String? morningStiffness,
    bool? isUnilateral,
    bool? improvesWithRest,
  }) async {
    if (redFlags.isNotEmpty) {
      final guidance = InjuryAssessmentGuidance.redFlagGuidance();
      return InjuryAssessmentResult(
        severityScore: 100,
        recommendedInjuryType: 'Acil değerlendirme gerekli',
        recommendedExerciseIds: const [],
        riskLevel: 'Yüksek Risk',
        hasRedFlags: true,
        guidance: guidance,
      );
    }

    final normalizedBodyPart = _normalizeBodyPart(bodyPart);
    final normalizedPainType = _normalizeKey(painType);
    final normalizedMovements =
        triggeringMovements.map(_normalizeMovement).toList();
    final normalizedRiskFactors = riskFactors.map(_normalizeKey).toList();
    final normalizedTest = _normalizeFunctionalityTest(functionalityTest);

    int severityScore = 0;

    severityScore += _getBodyPartRiskScore(normalizedBodyPart);
    severityScore += _getPainTypeRiskScore(normalizedPainType);
    severityScore +=
        _getTriggeringMovementsRiskScore(normalizedMovements, normalizedBodyPart);
    severityScore += _getFunctionalityTestRiskScore(normalizedTest);
    severityScore += _getRiskFactorsScore(normalizedRiskFactors);
    severityScore += _getPainContextScore(
      painDuration: painDuration,
      morningStiffness: morningStiffness,
      isUnilateral: isUnilateral,
      improvesWithRest: improvesWithRest,
    );

    severityScore = severityScore.clamp(0, 100);

    final recommendedInjuryType = _determineInjuryType(
      bodyPart: normalizedBodyPart,
      painType: normalizedPainType,
      severityScore: severityScore,
      functionalityTest: normalizedTest,
      painDuration: painDuration,
    );

    final riskLevel = _getRiskLevel(severityScore);

    final recommendedExerciseIds = riskLevel == 'Yüksek Risk'
        ? <String>[]
        : await _getRecommendedExercises(
            bodyPart: normalizedBodyPart,
            injuryType: recommendedInjuryType,
            severityScore: severityScore,
          );

    final guidance = InjuryAssessmentGuidance.build(
      bodyPart: normalizedBodyPart,
      riskLevel: riskLevel,
      severityScore: severityScore,
    );

    return InjuryAssessmentResult(
      severityScore: severityScore,
      recommendedInjuryType: recommendedInjuryType,
      recommendedExerciseIds: recommendedExerciseIds,
      riskLevel: riskLevel,
      hasRedFlags: false,
      guidance: guidance,
    );
  }

  int _getPainContextScore({
    String? painDuration,
    String? morningStiffness,
    bool? isUnilateral,
    bool? improvesWithRest,
  }) {
    int score = 0;

    final duration = _normalizeKey(painDuration ?? '');
    if (duration.contains('1 aydan uzun') || duration.contains('kronik')) {
      score += 10;
    } else if (duration.contains('1-4 hafta')) {
      score += 6;
    } else if (duration.contains('3-7 gun') || duration.contains('3-7 gün')) {
      score += 3;
    }

    final stiffness = _normalizeKey(morningStiffness ?? '');
    if (stiffness.contains('60') || stiffness.contains('1 saat')) {
      score += 8;
    } else if (stiffness.contains('30')) {
      score += 5;
    } else if (stiffness.contains('15')) {
      score += 2;
    }

    if (isUnilateral == true) score += 4;
    if (improvesWithRest == false) score += 6;

    return score.clamp(0, 20);
  }

  int _getBodyPartRiskScore(String bodyPart) {
    const riskScores = {
      'diz': 15,
      'omuz': 18,
      'bel': 20,
      'boyun': 16,
      'ayak bilegi': 12,
      'dirsek': 10,
      'kalca': 14,
    };
    return riskScores[bodyPart] ?? 10;
  }

  int _getPainTypeRiskScore(String painType) {
    const riskScores = {
      'keskin': 25,
      'yanma': 20,
      'batma': 22,
      'donuk': 10,
      'zonklama': 15,
      'gerginlik': 8,
    };
    return riskScores[painType] ?? 10;
  }

  int _getTriggeringMovementsRiskScore(List<String> movements, String bodyPart) {
    int score = 0;
    const highRiskMovements = {
      'diz': ['squat', 'lunge', 'kosu', 'ziplama'],
      'omuz': ['overhead press', 'pull up', 'bench press', 'agirlik kaldirma'],
      'bel': ['deadlift', 'squat', 'agirlik kaldirma'],
      'boyun': ['overhead press'],
      'ayak bilegi': ['kosu', 'ziplama', 'lateral movement'],
      'dirsek': ['bicep curl', 'tricep extension'],
      'kalca': ['squat', 'deadlift', 'lunge'],
    };

    final riskyMovements = highRiskMovements[bodyPart] ?? [];
    for (final movement in movements) {
      if (riskyMovements.contains(movement)) {
        score += 8;
      } else {
        score += 3;
      }
    }
    return score.clamp(0, 20);
  }

  int _getFunctionalityTestRiskScore(Map<String, dynamic> test) {
    int score = 0;

    final rom = _normalizeKey(test['range_of_motion'] as String? ?? '');
    if (rom.contains('cok kisitli')) {
      score += 15;
    } else if (rom.contains('kisitli') && !rom.contains('hafif')) {
      score += 10;
    } else if (rom.contains('hafif')) {
      score += 5;
    }

    final strength = _normalizeKey(test['strength'] as String? ?? '');
    if (strength.contains('cok zayif')) {
      score += 12;
    } else if (strength.contains('zayif')) {
      score += 8;
    } else if (strength.contains('orta')) {
      score += 4;
    }

    final stability = _normalizeKey(test['stability'] as String? ?? '');
    if (stability.contains('cok dengesiz')) {
      score += 10;
    } else if (stability.contains('dengesiz') && !stability.contains('hafif')) {
      score += 6;
    } else if (stability.contains('hafif')) {
      score += 3;
    }

    return score.clamp(0, 25);
  }

  int _getRiskFactorsScore(List<String> riskFactors) {
    int score = 0;
    const factorScores = {
      'gecmis sakatlik': 15,
      'asiri antrenman': 12,
      'yas (40+)': 8,
      'sedanter yasam': 6,
      'dusuk esneklik': 5,
      'dusuk kas gucu': 7,
      'dusuk denge': 6,
    };

    for (final factor in riskFactors) {
      score += factorScores[factor] ?? 3;
    }
    return score.clamp(0, 30);
  }

  String _determineInjuryType({
    required String bodyPart,
    required String painType,
    required int severityScore,
    required Map<String, dynamic> functionalityTest,
    String? painDuration,
  }) {
    if (severityScore > 70) {
      return _getSeriousInjuryType(bodyPart, painType);
    }
    if (severityScore >= 40) {
      return _getModerateInjuryType(bodyPart, painType);
    }
    return _getMildInjuryType(bodyPart, painType);
  }

  String _getSeriousInjuryType(String bodyPart, String painType) {
    const seriousInjuries = {
      'diz': 'Diz bağ yaralanması / Menisküs yırtığı',
      'omuz': 'Rotator cuff yaralanması / Omuz çıkığı',
      'bel': 'Bel fıtığı / Spinal yaralanma',
      'boyun': 'Boyun fıtığı / Servikal yaralanma',
      'ayak bilegi': 'Ayak bileği burkulması (şiddetli) / Kırık',
      'dirsek': 'Tenis dirseği (şiddetli) / Dirsek yaralanması',
      'kalca': 'Kalça labrum yırtığı / Kalça yaralanması',
    };
    return seriousInjuries[bodyPart] ?? 'Ciddi yaralanma riski';
  }

  String _getModerateInjuryType(String bodyPart, String painType) {
    const moderateInjuries = {
      'diz': 'Diz tendoniti / Patellofemoral ağrı sendromu',
      'omuz': 'Omuz impingement / Bursit',
      'bel': 'Bel kas gerginliği / Lumbago',
      'boyun': 'Boyun kas gerginliği / Servikal gerginlik',
      'ayak bilegi': 'Ayak bileği burkulması (orta) / Tendonit',
      'dirsek': 'Tenis dirseği (orta) / Golfçü dirseği',
      'kalca': 'Kalça bursiti / IT band sendromu',
    };
    return moderateInjuries[bodyPart] ?? 'Orta seviye yaralanma riski';
  }

  String _getMildInjuryType(String bodyPart, String painType) {
    const mildInjuries = {
      'diz': 'Hafif diz ağrısı / Kas yorgunluğu',
      'omuz': 'Hafif omuz ağrısı / Kas gerginliği',
      'bel': 'Hafif bel ağrısı / Kas gerginliği',
      'boyun': 'Hafif boyun ağrısı / Kas gerginliği',
      'ayak bilegi': 'Hafif ayak bileği ağrısı / Kas yorgunluğu',
      'dirsek': 'Hafif dirsek ağrısı / Kas gerginliği',
      'kalca': 'Hafif kalça ağrısı / Kas yorgunluğu',
    };
    return mildInjuries[bodyPart] ?? 'Hafif yaralanma riski';
  }

  String _getRiskLevel(int severityScore) {
    if (severityScore >= 70) return 'Yüksek Risk';
    if (severityScore >= 40) return 'Orta Risk';
    return 'Düşük Risk';
  }

  Future<List<String>> _getRecommendedExercises({
    required String bodyPart,
    required String? injuryType,
    required int severityScore,
  }) async {
    try {
      if (severityScore < 40) {
        return _getRehabilitationExercises(bodyPart);
      }
      return _getSpecializedExercises(bodyPart);
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _getRehabilitationExercises(String bodyPart) async {
    return PhysicalTherapyData.getExercisesForBodyPart(bodyPart)
        .map((e) => e.name)
        .take(10)
        .toList();
  }

  Future<List<String>> _getSpecializedExercises(String bodyPart) async {
    return PhysicalTherapyData.getExercisesForBodyPart(bodyPart)
        .where((e) => !_isHighImpactExercise(e.name))
        .take(8)
        .map((e) => e.name)
        .toList();
  }

  bool _isHighImpactExercise(String exerciseName) {
    const highImpact = ['squat', 'deadlift', 'jump', 'lunge', 'sprint', 'plyometric'];
    final nameLower = _normalizeKey(exerciseName);
    return highImpact.any(nameLower.contains);
  }

  String _normalizeBodyPart(String bodyPart) {
    final normalized = _normalizeKey(bodyPart);
    if (normalized.contains('ayak')) return 'ayak bilegi';
    if (normalized.startsWith('kal')) return 'kalca';
    return normalized;
  }

  String _normalizeMovement(String movement) {
    return _normalizeKey(movement)
        .replaceAll('agirlik kaldirma', 'agirlik kaldirma')
        .replaceAll('kosu', 'kosu')
        .replaceAll('ziplama', 'ziplama');
  }

  Map<String, dynamic> _normalizeFunctionalityTest(Map<String, dynamic> test) {
    return {
      for (final entry in test.entries)
        entry.key: entry.value is String ? _normalizeKey(entry.value as String) : entry.value,
    };
  }

  String _normalizeKey(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }
}

class InjuryAssessmentResult {
  final int severityScore;
  final String? recommendedInjuryType;
  final List<String> recommendedExerciseIds;
  final String riskLevel;
  final bool hasRedFlags;
  final InjuryGuidance guidance;

  InjuryAssessmentResult({
    required this.severityScore,
    this.recommendedInjuryType,
    required this.recommendedExerciseIds,
    required this.riskLevel,
    this.hasRedFlags = false,
    required this.guidance,
  });
}
