import 'dart:math';

import '../models/exercise.dart';
import '../models/user_goal.dart';
import '../models/user_metric.dart';
import '../models/user_limitation.dart';
import '../models/workout.dart';
import '../data/physical_therapy_data.dart';
import 'exercise_service.dart';
import 'user_goals_service.dart';
import 'user_metrics_service.dart';
import 'user_limitations_service.dart';
import 'workout_service.dart';

class PlanSuggestion {
  final String name;
  final String description;
  final String splitType; // 'full_body', 'push_pull_legs', 'upper_lower', 'bro_split'
  final int exercisesPerDay;
  final int weeks;
  final List<_SplitDay> splitDays;

  PlanSuggestion({
    required this.name,
    required this.description,
    required this.splitType,
    required this.exercisesPerDay,
    required this.weeks,
    required this.splitDays,
  });
}

class PersonalizationService {
  final _exerciseService = ExerciseService();
  final _goalsService = UserGoalsService();
  final _metricsService = UserMetricsService();
  final _limitationsService = UserLimitationsService();
  final _workoutService = WorkoutService();
  final _random = Random();

  /// Kullanıcının hedefine göre birden fazla plan önerisi üret (kaydetmez)
  List<PlanSuggestion> generatePlanSuggestions({
    required String goalType,
    required int daysPerWeek,
    required String experienceLevel,
    required int programWeeks,
  }) {
    final suggestions = <PlanSuggestion>[];

    if (daysPerWeek <= 2) {
      suggestions.add(PlanSuggestion(
        name: 'Full Body',
        description: 'Tüm vücudu her antrenmanda çalıştırır. Az gün yapanlar için ideal.',
        splitType: 'full_body',
        exercisesPerDay: experienceLevel == 'beginner' ? 5 : 6,
        weeks: programWeeks,
        splitDays: List.generate(daysPerWeek, (i) => _SplitDay(
          name: 'Full Body ${i + 1}',
          categories: ['Chest', 'Back', 'Legs', 'Shoulders', 'Core', 'Cardio'],
          exerciseCount: experienceLevel == 'beginner' ? 5 : 6,
        )),
      ));
    }

    if (daysPerWeek >= 2 && daysPerWeek <= 4) {
      suggestions.add(PlanSuggestion(
        name: 'Upper / Lower',
        description: 'Üst ve alt vücut günlere bölünür. Dengeli gelişim sağlar.',
        splitType: 'upper_lower',
        exercisesPerDay: 5,
        weeks: programWeeks,
        splitDays: _buildUpperLowerSplit(daysPerWeek),
      ));
    }

    if (daysPerWeek >= 3) {
      suggestions.add(PlanSuggestion(
        name: 'Push / Pull / Legs',
        description: 'İtme, çekme ve bacak günleri. En popüler split programı.',
        splitType: 'push_pull_legs',
        exercisesPerDay: 5,
        weeks: programWeeks,
        splitDays: _buildPPLSplit(daysPerWeek),
      ));
    }

    if (daysPerWeek >= 4) {
      suggestions.add(PlanSuggestion(
        name: 'Bro Split',
        description: 'Her gün farklı kas grubu. İleri seviye için detaylı çalışma.',
        splitType: 'bro_split',
        exercisesPerDay: 5,
        weeks: programWeeks,
        splitDays: _buildBroSplit(daysPerWeek),
      ));
    }

    if (goalType == 'weight_loss') {
      suggestions.add(PlanSuggestion(
        name: 'Kardiyo Ağırlıklı',
        description: 'Yağ yakımına odaklı: kardiyo + compound hareketler.',
        splitType: 'cardio_focus',
        exercisesPerDay: 6,
        weeks: programWeeks,
        splitDays: _buildCardioFocusSplit(daysPerWeek),
      ));
    }

    if (goalType == 'physiotherapy') {
      suggestions.add(PlanSuggestion(
        name: 'Rehabilitasyon',
        description: 'Düşük yoğunluklu, esneme ve güçlendirme odaklı program.',
        splitType: 'rehab',
        exercisesPerDay: 4,
        weeks: programWeeks,
        splitDays: List.generate(daysPerWeek, (i) => _SplitDay(
          name: 'Rehabilitasyon ${i + 1}',
          categories: ['Core', 'Legs', 'Back', 'Shoulders'],
          exerciseCount: 4,
        )),
      ));
    }

    return suggestions;
  }

  List<_SplitDay> _buildUpperLowerSplit(int daysPerWeek) {
    final days = <_SplitDay>[];
    for (var i = 0; i < daysPerWeek; i++) {
      if (i.isEven) {
        days.add(_SplitDay(name: 'Upper ${(i ~/ 2) + 1}', categories: ['Chest', 'Back', 'Shoulders', 'Arms'], exerciseCount: 5));
      } else {
        days.add(_SplitDay(name: 'Lower ${(i ~/ 2) + 1}', categories: ['Legs', 'Core', 'Cardio'], exerciseCount: 5));
      }
    }
    return days;
  }

  List<_SplitDay> _buildPPLSplit(int daysPerWeek) {
    final base = [
      _SplitDay(name: 'Push', categories: ['Chest', 'Shoulders', 'Arms'], exerciseCount: 5),
      _SplitDay(name: 'Pull', categories: ['Back', 'Arms', 'Core'], exerciseCount: 5),
      _SplitDay(name: 'Legs', categories: ['Legs', 'Core', 'Cardio'], exerciseCount: 5),
    ];
    final days = <_SplitDay>[];
    for (var i = 0; i < daysPerWeek; i++) {
      days.add(base[i % 3]);
    }
    return days;
  }

  List<_SplitDay> _buildBroSplit(int daysPerWeek) {
    final allDays = [
      _SplitDay(name: 'Göğüs', categories: ['Chest'], exerciseCount: 5),
      _SplitDay(name: 'Sırt', categories: ['Back'], exerciseCount: 5),
      _SplitDay(name: 'Bacak', categories: ['Legs'], exerciseCount: 5),
      _SplitDay(name: 'Omuz', categories: ['Shoulders', 'Core'], exerciseCount: 5),
      _SplitDay(name: 'Kol', categories: ['Arms'], exerciseCount: 5),
      _SplitDay(name: 'Kardiyo & Core', categories: ['Cardio', 'Core'], exerciseCount: 5),
    ];
    return allDays.take(daysPerWeek).toList();
  }

  List<_SplitDay> _buildCardioFocusSplit(int daysPerWeek) {
    final days = <_SplitDay>[];
    for (var i = 0; i < daysPerWeek; i++) {
      if (i.isEven) {
        days.add(_SplitDay(name: 'Kardiyo + Full', categories: ['Cardio', 'Legs', 'Core'], exerciseCount: 6));
      } else {
        days.add(_SplitDay(name: 'HIIT + Üst', categories: ['Cardio', 'Chest', 'Back', 'Shoulders'], exerciseCount: 6));
      }
    }
    return days;
  }

  /// Seçilen plan önerisinden workout üret ve kaydet
  Future<Workout?> generateFromSuggestion({
    required String userId,
    required PlanSuggestion suggestion,
    required String goalType,
    required String experienceLevel,
  }) async {
    final limitations = await _limitationsService.getActiveLimitations(userId);

    if (goalType == 'physiotherapy') {
      return _generatePhysiotherapyPlan(userId,
        UserGoal(userId: userId, goalType: goalType, experienceLevel: experienceLevel,
          workoutDaysPerWeek: suggestion.splitDays.length, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        limitations,
      );
    }

    final allExercises = await _exerciseService.getAllExercises();
    final levelFiltered = _filterByExperienceLevel(allExercises, experienceLevel);
    final safeExercises = _applySafetyFilter(levelFiltered, limitations);
    final categoryDistribution = _getCategoryDistribution(goalType);
    final params = _getExerciseParams(experienceLevel);
    final allWorkoutExercises = <WorkoutExercise>[];

    for (final day in suggestion.splitDays) {
      final dayExercises = _selectExercisesForDay(
        safeExercises, day.categories, day.exerciseCount, categoryDistribution,
      );
      for (final exercise in dayExercises) {
        allWorkoutExercises.add(_workoutExerciseFromSelection(
          exercise,
          params,
          '${day.name} - ${exercise.category ?? ""}',
          experienceLevel,
        ));
      }
    }

    if (allWorkoutExercises.isEmpty) return null;

    final workout = await _workoutService.createWorkout(
      userId: userId,
      name: suggestion.name,
      exercises: allWorkoutExercises,
      weeks: suggestion.weeks,
    );

    await _workoutService.setActiveWorkout(userId, workout.id);
    return workout;
  }

  /// Kullanıcıya özel antrenman planı üret ve kaydet (eski yöntem, uyumluluk için)
  Future<Workout?> generatePersonalizedPlan(String userId) async {
    final goal = await _goalsService.getActiveGoal(userId);
    if (goal == null) return null;

    final metrics = await _metricsService.getLatestMetric(userId);
    final limitations = await _limitationsService.getActiveLimitations(userId);

    // Fizyoterapi hedefi için ayrı akış
    if (goal.goalType == 'physiotherapy') {
      return _generatePhysiotherapyPlan(userId, goal, limitations);
    }

    final allExercises = await _exerciseService.getAllExercises();

    // 1. Deneyim seviyesine göre filtrele
    final levelFiltered = _filterByExperienceLevel(allExercises, goal.experienceLevel);

    // 2. Güvenlik filtresi: kısıtlamalara göre riskli egzersizleri çıkar
    final safeExercises = _applySafetyFilter(levelFiltered, limitations);

    // 3. Hedefe göre egzersiz kategorilerini ve oranlarını belirle
    final categoryDistribution = _getCategoryDistribution(goal.goalType);

    // 4. Split yapısını belirle
    final splitDays = _buildSplit(goal.workoutDaysPerWeek, goal.goalType);

    // 5. Her gün için egzersiz seç
    final params = _getExerciseParams(goal.experienceLevel);
    final allWorkoutExercises = <WorkoutExercise>[];

    for (final day in splitDays) {
      final dayExercises = _selectExercisesForDay(
        safeExercises,
        day.categories,
        day.exerciseCount,
        categoryDistribution,
      );

      for (final exercise in dayExercises) {
        allWorkoutExercises.add(_workoutExerciseFromSelection(
          exercise,
          params,
          '${day.name} - ${exercise.category ?? ""}',
          goal.experienceLevel,
        ));
      }
    }

    if (allWorkoutExercises.isEmpty) return null;

    // 6. Workout oluştur ve aktif yap
    final planName = _generatePlanName(goal);
    final weeks = _getRecommendedWeeks(goal.experienceLevel);

    final workout = await _workoutService.createWorkout(
      userId: userId,
      name: planName,
      exercises: allWorkoutExercises,
      weeks: weeks,
    );

    await _workoutService.setActiveWorkout(userId, workout.id);
    return workout;
  }

  // ─── FİZYOTERAPİ PLANI ───

  Future<Workout?> _generatePhysiotherapyPlan(
    String userId,
    UserGoal goal,
    List<UserLimitation> limitations,
  ) async {
    final exercises = <WorkoutExercise>[];

    if (limitations.isEmpty) {
      // Kısıtlama yoksa tüm bölgelerden genel esneklik programı
      for (final category in PhysicalTherapyData.getCategories()) {
        final selected = category.exercises.take(3);
        for (final ex in selected) {
          exercises.add(WorkoutExercise(
            exerciseId: 'pt_${category.englishName.toLowerCase()}_${exercises.length}',
            exerciseName: ex.name,
            sets: 2,
            reps: 12,
            restSeconds: 30,
            notes: '${category.name} - ${ex.description}',
          ));
        }
      }
    } else {
      // Kısıtlı bölgelere odaklan
      for (final limitation in limitations.where((l) => l.isActive)) {
        final bodyPartExercises = PhysicalTherapyData.getExercisesForBodyPart(limitation.bodyPart);
        final maxCount = limitation.severity == 'high' ? 4 : 6;

        for (final ex in bodyPartExercises.take(maxCount)) {
          exercises.add(WorkoutExercise(
            exerciseId: 'pt_${limitation.bodyPart.toLowerCase()}_${exercises.length}',
            exerciseName: ex.name,
            sets: limitation.severity == 'high' ? 1 : 2,
            reps: 10,
            restSeconds: 45,
            notes: '${limitation.bodyPart} rehabilitasyon - ${ex.description}',
          ));
        }
      }
    }

    if (exercises.isEmpty) return null;

    final workout = await _workoutService.createWorkout(
      userId: userId,
      name: 'Fizyoterapi Programı',
      exercises: exercises,
      weeks: 6,
    );

    await _workoutService.setActiveWorkout(userId, workout.id);
    return workout;
  }

  // ─── DENEYİM SEVİYESİNE GÖRE FİLTRELE ───

  List<Exercise> _filterByExperienceLevel(List<Exercise> exercises, String level) {
    final allowedDifficulties = <String>[];

    switch (level) {
      case 'beginner':
        allowedDifficulties.add('beginner');
        break;
      case 'intermediate':
        allowedDifficulties.addAll(['beginner', 'intermediate']);
        break;
      case 'advanced':
        allowedDifficulties.addAll(['beginner', 'intermediate', 'advanced']);
        break;
    }

    return exercises.where((e) {
      if (e.difficulty == null) return true;
      return allowedDifficulties.contains(e.difficulty);
    }).toList();
  }

  // ─── GÜVENLİK FİLTRESİ ───

  List<Exercise> _applySafetyFilter(
    List<Exercise> exercises,
    List<UserLimitation> limitations,
  ) {
    if (limitations.isEmpty) return exercises;

    final riskyMuscleGroups = <String>{};
    final riskyCategories = <String>{};

    for (final limitation in limitations.where((l) => l.isActive)) {
      final bodyPart = limitation.bodyPart.toLowerCase();
      final isHigh = limitation.severity == 'high';

      switch (bodyPart) {
        case 'diz':
          riskyMuscleGroups.addAll(['quadriceps', 'hamstrings']);
          if (isHigh) riskyCategories.add('legs');
          break;
        case 'omuz':
          riskyMuscleGroups.add('shoulders');
          if (isHigh) riskyCategories.add('shoulders');
          break;
        case 'bel':
          riskyMuscleGroups.add('back');
          if (isHigh) riskyCategories.add('back');
          break;
        case 'kalça':
        case 'kalca':
          riskyMuscleGroups.addAll(['glutes', 'hamstrings']);
          break;
        case 'dirsek':
          riskyMuscleGroups.addAll(['biceps', 'triceps', 'forearms']);
          if (isHigh) riskyCategories.add('arms');
          break;
        case 'ayak bileği':
        case 'ayak bilegi':
          riskyMuscleGroups.add('calves');
          break;
      }
    }

    return exercises.where((exercise) {
      final category = (exercise.category ?? '').toLowerCase();

      // Yüksek şiddetli kısıtlamada tüm kategori hariç
      if (riskyCategories.contains(category)) return false;

      // Kas grubu kontrolü
      final muscleGroups = exercise.muscleGroups ?? [];
      final lowerMuscles = muscleGroups.map((m) => m.toLowerCase()).toList();

      // Birincil kas grubu riskli ise çıkar (ilk eleman genellikle birincil)
      if (lowerMuscles.isNotEmpty && riskyMuscleGroups.contains(lowerMuscles.first)) {
        return false;
      }

      return true;
    }).toList();
  }

  // ─── HEDEF BAZLI KATEGORİ DAĞILIMI ───

  Map<String, double> _getCategoryDistribution(String goalType) {
    switch (goalType) {
      case 'weight_loss':
        return {
          'Cardio': 0.40,
          'Legs': 0.15,
          'Core': 0.15,
          'Chest': 0.10,
          'Back': 0.10,
          'Shoulders': 0.05,
          'Arms': 0.05,
        };
      case 'muscle_gain':
        return {
          'Chest': 0.18,
          'Back': 0.18,
          'Legs': 0.20,
          'Shoulders': 0.12,
          'Arms': 0.12,
          'Core': 0.10,
          'Cardio': 0.10,
        };
      default: // general_fitness
        return {
          'Chest': 0.14,
          'Back': 0.14,
          'Legs': 0.16,
          'Shoulders': 0.10,
          'Arms': 0.10,
          'Core': 0.16,
          'Cardio': 0.20,
        };
    }
  }

  // ─── SPLIT YAPISI ───

  List<_SplitDay> _buildSplit(int daysPerWeek, String goalType) {
    switch (daysPerWeek) {
      case 1:
      case 2:
        return List.generate(daysPerWeek, (i) => _SplitDay(
          name: 'Full Body ${i + 1}',
          categories: ['Chest', 'Back', 'Legs', 'Core', 'Cardio'],
          exerciseCount: 6,
        ));
      case 3:
        return [
          _SplitDay(name: 'Push', categories: ['Chest', 'Shoulders', 'Arms'], exerciseCount: 5),
          _SplitDay(name: 'Pull', categories: ['Back', 'Arms', 'Core'], exerciseCount: 5),
          _SplitDay(name: 'Legs & Cardio', categories: ['Legs', 'Core', 'Cardio'], exerciseCount: 5),
        ];
      case 4:
        return [
          _SplitDay(name: 'Upper A', categories: ['Chest', 'Back', 'Shoulders'], exerciseCount: 5),
          _SplitDay(name: 'Lower A', categories: ['Legs', 'Core', 'Cardio'], exerciseCount: 5),
          _SplitDay(name: 'Upper B', categories: ['Chest', 'Back', 'Arms'], exerciseCount: 5),
          _SplitDay(name: 'Lower B', categories: ['Legs', 'Core', 'Cardio'], exerciseCount: 5),
        ];
      case 5:
        return [
          _SplitDay(name: 'Push', categories: ['Chest', 'Shoulders'], exerciseCount: 5),
          _SplitDay(name: 'Pull', categories: ['Back', 'Arms'], exerciseCount: 5),
          _SplitDay(name: 'Legs', categories: ['Legs', 'Core'], exerciseCount: 5),
          _SplitDay(name: 'Upper', categories: ['Chest', 'Back', 'Shoulders', 'Arms'], exerciseCount: 5),
          _SplitDay(name: 'Cardio & Core', categories: ['Cardio', 'Core'], exerciseCount: 5),
        ];
      default: // 6-7
        return [
          _SplitDay(name: 'Push', categories: ['Chest', 'Shoulders'], exerciseCount: 5),
          _SplitDay(name: 'Pull', categories: ['Back', 'Arms'], exerciseCount: 5),
          _SplitDay(name: 'Legs', categories: ['Legs'], exerciseCount: 5),
          _SplitDay(name: 'Push 2', categories: ['Chest', 'Shoulders', 'Arms'], exerciseCount: 5),
          _SplitDay(name: 'Pull 2', categories: ['Back', 'Arms'], exerciseCount: 5),
          _SplitDay(name: 'Legs & Core', categories: ['Legs', 'Core', 'Cardio'], exerciseCount: 5),
        ];
    }
  }

  // ─── GÜN İÇİN EGZERSİZ SEÇ ───

  List<Exercise> _selectExercisesForDay(
    List<Exercise> allExercises,
    List<String> dayCategories,
    int targetCount,
    Map<String, double> distribution,
  ) {
    final selected = <Exercise>[];
    final usedIds = <String>{};

    for (final category in dayCategories) {
      final categoryExercises = allExercises
          .where((e) => (e.category ?? '').toLowerCase() == category.toLowerCase())
          .where((e) => !usedIds.contains(e.id))
          .toList();

      if (categoryExercises.isEmpty) continue;

      // Kategorinin oranına göre kaç tane seçilecek
      final weight = distribution[category] ?? 0.1;
      final countForCategory = max(1, (targetCount * weight / dayCategories.length * dayCategories.length).round());
      final toTake = min(countForCategory, categoryExercises.length);

      // Rastgele seç
      categoryExercises.shuffle(_random);
      for (var i = 0; i < toTake && selected.length < targetCount; i++) {
        selected.add(categoryExercises[i]);
        usedIds.add(categoryExercises[i].id);
      }
    }

    // Hedef sayıya ulaşamadıysa kalan kategorilerden doldur
    if (selected.length < targetCount) {
      final remaining = allExercises
          .where((e) => !usedIds.contains(e.id))
          .where((e) => dayCategories.any(
              (c) => (e.category ?? '').toLowerCase() == c.toLowerCase()))
          .toList();
      remaining.shuffle(_random);
      for (final e in remaining) {
        if (selected.length >= targetCount) break;
        selected.add(e);
        usedIds.add(e.id);
      }
    }

    return selected;
  }

  // ─── EGZERSİZ PARAMETRELERİ ───

  _ExerciseParams _getExerciseParams(String experienceLevel) {
    switch (experienceLevel) {
      case 'beginner':
        return _ExerciseParams(sets: 3, reps: 12, restSeconds: 75);
      case 'intermediate':
        return _ExerciseParams(sets: 4, reps: 10, restSeconds: 60);
      case 'advanced':
        return _ExerciseParams(sets: 4, reps: 8, restSeconds: 90);
      default:
        return _ExerciseParams(sets: 3, reps: 12, restSeconds: 60);
    }
  }

  bool _isCardioCategory(Exercise exercise) =>
      (exercise.category ?? '').trim().toLowerCase() == 'cardio';

  int _cardioDurationSeconds(String experienceLevel) {
    switch (experienceLevel) {
      case 'beginner':
        return 120;
      case 'intermediate':
        return 180;
      case 'advanced':
        return 240;
      default:
        return 180;
    }
  }

  WorkoutExercise _workoutExerciseFromSelection(
    Exercise exercise,
    _ExerciseParams params,
    String dayNote,
    String experienceLevel,
  ) {
    if (_isCardioCategory(exercise)) {
      return WorkoutExercise(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        sets: 1,
        reps: null,
        durationSeconds: _cardioDurationSeconds(experienceLevel),
        restSeconds: null,
        notes: dayNote,
      );
    }
    return WorkoutExercise(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      sets: params.sets,
      reps: params.reps,
      restSeconds: params.restSeconds,
      notes: dayNote,
    );
  }

  // ─── PLAN İSMİ ───

  String _generatePlanName(UserGoal goal) {
    final goalName = goal.goalTypeDisplayName;
    final level = goal.experienceLevelDisplayName;
    return '$goalName - $level Seviye';
  }

  // ─── ÖNERİLEN HAFTA SAYISI ───

  int _getRecommendedWeeks(String experienceLevel) {
    switch (experienceLevel) {
      case 'beginner':
        return 6;
      case 'intermediate':
        return 8;
      case 'advanced':
        return 10;
      default:
        return 6;
    }
  }
}

// ─── YARDIMCI SINIFLAR ───

class _SplitDay {
  final String name;
  final List<String> categories;
  final int exerciseCount;

  _SplitDay({
    required this.name,
    required this.categories,
    required this.exerciseCount,
  });
}

class _ExerciseParams {
  final int sets;
  final int reps;
  final int restSeconds;

  _ExerciseParams({
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });
}
