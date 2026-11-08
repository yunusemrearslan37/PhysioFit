import '../config/supabase_config.dart';
import '../models/user_goal.dart';

class UserGoalsService {
  final _supabase = SupabaseConfig.client;

  Future<UserGoal?> getActiveGoal(String userId) async {
    try {
      final response = await _supabase
          .from('user_goals')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return UserGoal.fromJson(response);
    } catch (e) {
      throw Exception('Aktif hedef getirme hatası: $e');
    }
  }

  Future<List<UserGoal>> getUserGoals(String userId) async {
    try {
      final response = await _supabase
          .from('user_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserGoal.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Hedefleri getirme hatası: $e');
    }
  }

  Future<UserGoal> createGoal({
    required String userId,
    required String goalType,
    double? targetWeight,
    String activityLevel = 'moderate',
    int workoutDaysPerWeek = 3,
    List<int> workoutDays = const [],
    int programWeeks = 6,
    String experienceLevel = 'beginner',
  }) async {
    try {
      // Mevcut aktif hedefleri pasif yap
      await _supabase
          .from('user_goals')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_active', true);

      final response = await _supabase
          .from('user_goals')
          .insert({
            'user_id': userId,
            'goal_type': goalType,
            'target_weight': targetWeight,
            'activity_level': activityLevel,
            'workout_days_per_week': workoutDaysPerWeek,
            'workout_days': workoutDays,
            'program_weeks': programWeeks,
            'experience_level': experienceLevel,
            'is_active': true,
          })
          .select()
          .single();

      return UserGoal.fromJson(response);
    } catch (e) {
      throw Exception('Hedef oluşturma hatası: $e');
    }
  }

  Future<UserGoal> updateGoal({
    required String goalId,
    String? goalType,
    double? targetWeight,
    String? activityLevel,
    int? workoutDaysPerWeek,
    String? experienceLevel,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (goalType != null) updateData['goal_type'] = goalType;
      if (targetWeight != null) updateData['target_weight'] = targetWeight;
      if (activityLevel != null) updateData['activity_level'] = activityLevel;
      if (workoutDaysPerWeek != null) updateData['workout_days_per_week'] = workoutDaysPerWeek;
      if (experienceLevel != null) updateData['experience_level'] = experienceLevel;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from('user_goals')
          .update(updateData)
          .eq('id', goalId)
          .select()
          .single();

      return UserGoal.fromJson(response);
    } catch (e) {
      throw Exception('Hedef güncelleme hatası: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _supabase.from('user_goals').delete().eq('id', goalId);
    } catch (e) {
      throw Exception('Hedef silme hatası: $e');
    }
  }
}
