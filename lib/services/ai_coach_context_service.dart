import '../models/user_goal.dart';
import '../models/user_limitation.dart';
import '../models/workout.dart';
import '../models/calorie_daily_summary.dart';
import 'auth_service.dart';
import 'calorie_tracking_service.dart';
import 'user_goals_service.dart';
import 'user_limitations_service.dart';
import 'workout_service.dart';

/// AI chat ekranında gösterilecek antrenman aksiyonu.
class AiCoachWorkoutAction {
  final bool visible;
  final String? workoutId;
  final String label;

  const AiCoachWorkoutAction({
    this.visible = false,
    this.workoutId,
    this.label = 'Bugünkü antrenmana git',
  });
}

/// AI koç ekranı için kullanıcı bağlamı ve kişiselleştirilmiş öneri metinleri.
class AiCoachContextService {
  final _authService = AuthService();
  final _goalsService = UserGoalsService();
  final _workoutService = WorkoutService();
  final _limitationsService = UserLimitationsService();
  final _calorieTracking = CalorieTrackingService();

  /// Bugünkü antrenman seansına düşen hareketler (ana sayfa ile aynı bölümleme).
  static List<WorkoutExercise> todaySessionExercises({
    required Workout? workout,
    required UserGoal? goal,
    DateTime? referenceDate,
  }) {
    if (workout == null || workout.exercises.isEmpty) return const [];

    final exercises = workout.exercises;
    final todayWeekday = (referenceDate ?? DateTime.now()).weekday;
    final sortedWorkoutDays =
        goal != null ? (List<int>.from(goal.workoutDays)..sort()) : <int>[];

    if (sortedWorkoutDays.isNotEmpty) {
      final dayIndex = sortedWorkoutDays.indexOf(todayWeekday);
      if (dayIndex == -1) return const [];

      final exercisesPerDay =
          (exercises.length / sortedWorkoutDays.length).ceil();
      final startIdx = dayIndex * exercisesPerDay;
      return exercises.skip(startIdx).take(exercisesPerDay).toList();
    }

    final daysPerWeek = goal?.workoutDaysPerWeek ?? 3;
    final exercisesPerDay = (exercises.length / daysPerWeek).ceil();
    final dayIndex = (todayWeekday - 1) % daysPerWeek;
    final startIdx = dayIndex * exercisesPerDay;
    return exercises.skip(startIdx).take(exercisesPerDay).toList();
  }

  static bool isTodayWorkoutDay(UserGoal? goal, {DateTime? referenceDate}) {
    if (goal == null || goal.workoutDays.isEmpty) return true;
    final todayWeekday = (referenceDate ?? DateTime.now()).weekday;
    return goal.workoutDays.contains(todayWeekday);
  }

  /// Ana sayfa AI Koç kartı için tek satırlık özet.
  static String buildMiniCoachSummary({
    required Workout? workout,
    required UserGoal? goal,
  }) {
    if (workout == null || workout.exercises.isEmpty) {
      if (goal != null) {
        return '${goal.goalTypeDisplayName} hedefin için koçtan program önerisi al.';
      }
      return 'Antrenman ve sağlık hakkında sorularını sor.';
    }

    if (!isTodayWorkoutDay(goal)) {
      return 'Bugün dinlenme günün — mobilite veya toparlanma sor.';
    }

    final today = todaySessionExercises(workout: workout, goal: goal);
    if (today.isEmpty) {
      return '${workout.name} aktif; bugün için atanmış egzersiz yok.';
    }

    if (today.length == 1) {
      return 'Bugün 1 egzersiz: ${today.first.exerciseName}';
    }

    final preview = today.take(2).map((e) => e.exerciseName).join(', ');
    if (today.length == 2) {
      return 'Bugün 2 egzersiz: $preview';
    }
    return 'Bugün ${today.length} egzersiz: $preview +${today.length - 2}';
  }

  /// Boş sohbet ekranı için kişiselleştirilmiş hızlı soru chip metinleri.
  Future<List<String>> buildPersonalizedSuggestions({int maxCount = 4}) async {
    final user = _authService.currentUser;
    if (user == null) {
      return _defaultSuggestions().take(maxCount).toList();
    }

    try {
      final results = await Future.wait([
        _goalsService.getActiveGoal(user.id),
        _workoutService.getActiveWorkout(user.id),
        _limitationsService.getActiveLimitations(user.id),
        _calorieTracking.getTodaySummary(userId: user.id),
      ]);

      final goal = results[0] as UserGoal?;
      final workout = results[1] as Workout?;
      final limitations = results[2] as List<UserLimitation>;
      final calorieSummary = results[3] as CalorieDailySummary;

      final suggestions = <String>[];

      if (calorieSummary.isAvailable) {
        suggestions.add('Bugünkü kalori durumum nasıl?');
        if (calorieSummary.consumedToday <= 0) {
          suggestions.add('Günlük kalori hedefime göre ne yemeliyim?');
        } else {
          suggestions.add('Kalan kalorime uygun öğün öner');
        }
      } else if (goal?.goalType == 'weight_loss') {
        suggestions.add('Kilo vermek için beslenme öner');
      }

      if (limitations.isNotEmpty) {
        final bodyPart = limitations.first.bodyPart.trim();
        if (bodyPart.isNotEmpty) {
          suggestions.add('$bodyPart için alternatif egzersiz öner');
        }
        suggestions.add('Hareket yaparken nelere dikkat etmeliyim?');
      }

      final isWorkoutDay = isTodayWorkoutDay(goal);
      final todayExercises =
          todaySessionExercises(workout: workout, goal: goal);

      if (workout != null && workout.exercises.isNotEmpty) {
        if (isWorkoutDay && todayExercises.isNotEmpty) {
          suggestions.add('Bugünkü antrenmanımı özetle');
          final firstName = todayExercises.first.exerciseName.trim();
          if (firstName.isNotEmpty) {
            suggestions.add('$firstName formu nasıl olmalı?');
          }
          suggestions.add('Set ve dinlenme öner');
        } else if (!isWorkoutDay) {
          suggestions.add('Bugün dinlenme günü mü, ne yapmalıyım?');
        }
      } else if (goal != null) {
        suggestions.add(
          '${goal.goalTypeDisplayName} hedefim için program öner',
        );
      }

      for (final fallback in _defaultSuggestions()) {
        if (suggestions.length >= maxCount) break;
        if (!suggestions.contains(fallback)) {
          suggestions.add(fallback);
        }
      }

      return suggestions.take(maxCount).toList();
    } catch (_) {
      return _defaultSuggestions().take(maxCount).toList();
    }
  }

  /// Aktif program ve bugünkü seans varsa antrenman ekranına git butonu göster.
  Future<AiCoachWorkoutAction> getWorkoutAction() async {
    final user = _authService.currentUser;
    if (user == null) return const AiCoachWorkoutAction();

    try {
      final results = await Future.wait([
        _goalsService.getActiveGoal(user.id),
        _workoutService.getActiveWorkout(user.id),
      ]);

      final goal = results[0] as UserGoal?;
      final workout = results[1] as Workout?;

      if (workout == null || workout.exercises.isEmpty) {
        return const AiCoachWorkoutAction();
      }

      if (!isTodayWorkoutDay(goal)) {
        return const AiCoachWorkoutAction();
      }

      final todayExercises =
          todaySessionExercises(workout: workout, goal: goal);
      if (todayExercises.isEmpty) {
        return const AiCoachWorkoutAction();
      }

      return AiCoachWorkoutAction(
        visible: true,
        workoutId: workout.id,
      );
    } catch (_) {
      return const AiCoachWorkoutAction();
    }
  }

  /// Son kullanıcı mesajı ve AI yanıtına göre takip soruları (backend gerekmez).
  Future<List<String>> buildFollowUpSuggestions({
    required String lastUserMessage,
    String? lastAiReply,
    int maxCount = 3,
  }) async {
    final combined =
        '${lastUserMessage.toLowerCase()} ${(lastAiReply ?? '').toLowerCase()}';
    final suggestions = <String>[];

    UserGoal? goal;
    Workout? workout;
    List<UserLimitation> limitations = const [];

    final user = _authService.currentUser;
    if (user != null) {
      try {
        final results = await Future.wait([
          _goalsService.getActiveGoal(user.id),
          _workoutService.getActiveWorkout(user.id),
          _limitationsService.getActiveLimitations(user.id),
        ]);
        goal = results[0] as UserGoal?;
        workout = results[1] as Workout?;
        limitations = results[2] as List<UserLimitation>;
      } catch (_) {}
    }

    if (_matchesAny(combined, [
      'ağrı',
      'agri',
      'sakat',
      'bel',
      'diz',
      'omuz',
      'kısıt',
      'kisit',
      'ameliyat',
      'fizyo',
      'fizik',
    ])) {
      suggestions.addAll([
        'Hangi hareketlerden kaçınmalıyım?',
        'Evde yapabileceğim güvenli egzersizler neler?',
      ]);
      if (limitations.isNotEmpty) {
        final bodyPart = limitations.first.bodyPart.trim();
        if (bodyPart.isNotEmpty) {
          suggestions.add('$bodyPart için ısınma öner');
        }
      }
    } else if (_matchesAny(combined, [
      'beslen',
      'protein',
      'kalori',
      'kcal',
      'diyet',
      'öğün',
      'ogun',
      'yemek',
      'besin',
      'bütçe',
      'butce',
    ])) {
      suggestions.addAll([
        'Bugünkü kalori durumuma göre öner',
        'Örnek bir günlük menü ver',
        'Günde ne kadar protein almalıyım?',
        'Antrenman öncesi ne yemeliyim?',
      ]);
    } else if (_matchesAny(combined, [
      'form',
      'teknik',
      'nasıl',
      'nasil',
      'doğru',
      'dogru',
    ])) {
      suggestions.addAll([
        'Yaygın form hataları neler?',
        'Ağırlığı nasıl artırmalıyım?',
        'Dinlenme süresi ne olmalı?',
      ]);
    } else if (_matchesAny(combined, [
      'antrenman',
      'bugün',
      'bugun',
      'program',
      'set',
      'tekrar',
      'egzersiz',
      'hareket',
    ])) {
      suggestions.add('Daha detaylı anlat');
      final todayExercises =
          todaySessionExercises(workout: workout, goal: goal);
      if (todayExercises.isNotEmpty) {
        final name = todayExercises.first.exerciseName.trim();
        if (name.isNotEmpty) {
          suggestions.add('$name için alternatif var mı?');
        }
      }
      suggestions.add('Set ve dinlenme öner');
    } else if (_matchesAny(combined, [
      'dinlen',
      'uyku',
      'toparlan',
      'recovery',
      'istirahat',
    ])) {
      suggestions.addAll([
        'Aktif dinlenme ne demek?',
        'Uyku antrenmanı nasıl etkiler?',
        'Yarın antrenman yapmalı mıyım?',
      ]);
    } else if (_matchesAny(combined, ['motiv', 'disiplin', 'tutarlı', 'tutarli'])) {
      suggestions.addAll([
        'Alışkanlık oluşturmak için ne önerirsin?',
        'Haftalık hedef belirlememe yardım et',
      ]);
    } else {
      if (workout != null && isTodayWorkoutDay(goal)) {
        suggestions.add('Bugünkü programıma uygun mu?');
      }
      if (limitations.isNotEmpty) {
        suggestions.add('Önerilerim güvenli mi?');
      }
      suggestions.addAll([
        'Bunu biraz daha açar mısın?',
        'Pratik bir özet ver',
      ]);
    }

    return _uniqueTake(suggestions, maxCount);
  }

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static List<String> _uniqueTake(List<String> items, int max) {
    final seen = <String>{};
    final result = <String>[];
    for (final item in items) {
      if (seen.add(item)) result.add(item);
      if (result.length >= max) break;
    }
    return result;
  }

  static List<String> _defaultSuggestions() => [
        'Bugün ne yapmalıyım?',
        'Beslenme önerileri',
        'Kas yapma taktikleri',
        'Motivasyon ipuçları',
      ];
}
