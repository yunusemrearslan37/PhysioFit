import '../models/workout.dart';
import '../models/calorie_daily_summary.dart';
import '../models/user_profile.dart';
import '../models/user_goal.dart';
import '../services/auth_service.dart';
import '../services/calorie_calculator_service.dart';
import '../services/daily_nutrition_service.dart';
import '../services/exercise_service.dart';
import '../services/user_analytics_service.dart';
import '../services/user_goals_service.dart';
import '../services/user_metrics_service.dart';

/// Antrenman tamamlanınca kalori kaydı ve günlük özet hesabı.
class CalorieTrackingService {
  final _analytics = UserAnalyticsService();
  final _metrics = UserMetricsService();
  final _nutrition = DailyNutritionService();
  final _goals = UserGoalsService();
  final _auth = AuthService();
  final _exerciseService = ExerciseService();

  UserAnalyticsService get analyticsService => _analytics;

  Future<CalorieDailySummary> getTodaySummary({
    String? userId,
    UserProfile? profile,
    UserGoal? goal,
  }) async {
    final resolvedUserId = userId ?? _auth.currentUser?.id;
    if (resolvedUserId == null) {
      return const CalorieDailySummary(
        dailyTarget: null,
        burnedToday: 0,
        consumedToday: 0,
        hasProfileData: false,
      );
    }

    final resolvedProfile = profile ?? await _auth.getUserProfile();
    final resolvedGoal = goal ?? await _goals.getActiveGoal(resolvedUserId);
    final metric = await _metrics.getLatestMetric(resolvedUserId);
    final nutrition = await _nutrition.getForDate(
      userId: resolvedUserId,
      date: DateTime.now(),
    );
    final burned = await _analytics.getCaloriesBurnedForDate(
      userId: resolvedUserId,
      date: DateTime.now(),
    );

    int? target;
    var hasData = false;
    if (resolvedProfile != null &&
        metric?.weight != null &&
        metric?.height != null &&
        resolvedProfile.age != null &&
        metric!.weight! > 0 &&
        metric.height! > 0) {
      hasData = true;
      target = CalorieCalculatorService.calculateDailyTarget(
        weightKg: metric.weight!,
        heightCm: metric.height!,
        age: resolvedProfile.age!,
        gender: resolvedProfile.gender,
        activityLevel: resolvedGoal?.activityLevel ?? 'moderate',
        goalType: resolvedGoal?.goalType ?? 'general_fitness',
      );
    }

    return CalorieDailySummary(
      dailyTarget: target,
      burnedToday: burned,
      consumedToday: nutrition?.caloriesConsumed ?? 0,
      hasProfileData: hasData,
    );
  }

  Future<double?> getUserWeight(String userId) async {
    final metric = await _metrics.getLatestMetric(userId);
    return metric?.weight;
  }

  Future<int> estimateWorkoutCaloriesForUser({
    required String userId,
    required Workout workout,
  }) async {
    final weight = await getUserWeight(userId);
    if (weight == null || weight <= 0) return 0;

    final allExercises = await _exerciseService.getAllExercises();
    final metById = <String, double>{};
    final categoryById = <String, String>{};
    for (final e in allExercises) {
      if (e.metValue != null) metById[e.id] = e.metValue!;
      if (e.category != null) categoryById[e.id] = e.category!;
    }

    return CalorieCalculatorService.estimateWorkoutCalories(
      exercises: workout.exercises,
      weightKg: weight,
      metByExerciseId: metById,
      categoryByExerciseId: categoryById,
    );
  }

  Future<void> onWorkoutCompleted({
    required String userId,
    required Workout workout,
    required DateTime date,
  }) async {
    final calories = await estimateWorkoutCaloriesForUser(
      userId: userId,
      workout: workout,
    );
    if (calories > 0) {
      await _analytics.addCaloriesBurned(
        userId: userId,
        date: date,
        caloriesToAdd: calories,
      );
    }
  }

  Future<void> onWorkoutUncompleted({
    required String userId,
    required Workout workout,
    required DateTime date,
  }) async {
    final calories = await estimateWorkoutCaloriesForUser(
      userId: userId,
      workout: workout,
    );
    if (calories > 0) {
      await _analytics.subtractCaloriesBurned(
        userId: userId,
        date: date,
        caloriesToSubtract: calories,
      );
    }
  }
}
