import '../models/workout.dart';
import '../utils/gender_helper.dart';

/// Günlük kalori hedefi ve egzersiz kalori tahminleri.
class CalorieCalculatorService {
  static const double strengthMet = 4.0;
  static const int strengthMinutesPerSet = 2;

  /// Egzersiz adına göre yedek MET değerleri (veritabanında yoksa).
  static const Map<String, double> cardioMetFallback = {
    'yürüyüş': 3.5,
    'jumping jacks': 8.0,
    'stationary bike': 6.0,
    'koşu': 9.8,
    'burpees': 8.0,
    'high knees': 8.0,
    'sprint intervals': 11.0,
    'box jumps': 8.0,
    'rowing machine': 7.0,
  };

  /// Mifflin-St Jeor BMR (kcal/gün).
  static double? calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    String? gender,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return null;

    final englishGender = GenderHelper.toEnglish(gender);
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;

    if (englishGender == 'female') {
      return base - 161;
    }
    // Erkek veya belirtilmemiş: erkek formülü
    return base + 5;
  }

  static double activityMultiplier(String activityLevel) {
    switch (activityLevel) {
      case 'sedentary':
        return 1.2;
      case 'light':
        return 1.375;
      case 'moderate':
        return 1.55;
      case 'active':
        return 1.725;
      case 'very_active':
        return 1.9;
      default:
        return 1.55;
    }
  }

  /// TDEE + hedefe göre günlük kalori hedefi.
  static int? calculateDailyTarget({
    required double weightKg,
    required double heightCm,
    required int age,
    String? gender,
    String activityLevel = 'moderate',
    String goalType = 'general_fitness',
  }) {
    final bmr = calculateBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    if (bmr == null) return null;

    final tdee = bmr * activityMultiplier(activityLevel);

    switch (goalType) {
      case 'weight_loss':
        return (tdee - 400).round().clamp(1200, 5000);
      case 'muscle_gain':
        return (tdee + 250).round().clamp(1500, 6000);
      default:
        return tdee.round().clamp(1200, 6000);
    }
  }

  /// MET formülü: kcal = MET × kg × saat
  static int calculateFromMet({
    required double met,
    required double weightKg,
    required int durationSeconds,
  }) {
    if (met <= 0 || weightKg <= 0 || durationSeconds <= 0) return 0;
    final hours = durationSeconds / 3600;
    return (met * weightKg * hours).round();
  }

  static double resolveMet({
    required String exerciseName,
    String? category,
    double? metFromDb,
  }) {
    if (metFromDb != null && metFromDb > 0) return metFromDb;

    final isCardio = (category ?? '').trim().toLowerCase() == 'cardio';
    if (isCardio) {
      return cardioMetFallback[exerciseName.trim().toLowerCase()] ?? 6.0;
    }
    return strengthMet;
  }

  /// Tek bir program satırı için tahmini kalori.
  static int estimateExerciseCalories({
    required WorkoutExercise exercise,
    required double weightKg,
    String? category,
    double? metFromDb,
  }) {
    final met = resolveMet(
      exerciseName: exercise.exerciseName,
      category: category,
      metFromDb: metFromDb,
    );

    final duration = exercise.durationSeconds;
    if (duration != null && duration > 0) {
      return calculateFromMet(
        met: met,
        weightKg: weightKg,
        durationSeconds: duration,
      );
    }

    // Kuvvet: set başına ~2 dk, MET 4
    final estimatedSeconds = exercise.sets * strengthMinutesPerSet * 60;
    return calculateFromMet(
      met: met,
      weightKg: weightKg,
      durationSeconds: estimatedSeconds,
    );
  }

  /// Tüm antrenman programı için toplam tahmini kalori.
  static int estimateWorkoutCalories({
    required List<WorkoutExercise> exercises,
    required double weightKg,
    Map<String, double>? metByExerciseId,
    Map<String, String>? categoryByExerciseId,
  }) {
    if (weightKg <= 0 || exercises.isEmpty) return 0;

    var total = 0;
    for (final ex in exercises) {
      total += estimateExerciseCalories(
        exercise: ex,
        weightKg: weightKg,
        category: categoryByExerciseId?[ex.exerciseId],
        metFromDb: metByExerciseId?[ex.exerciseId],
      );
    }
    return total;
  }
}
