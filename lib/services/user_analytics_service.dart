import '../config/supabase_config.dart';

class UserAnalyticsService {
  final _supabase = SupabaseConfig.client;

  Future<int> getCaloriesBurnedForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('user_analytics')
          .select('calories_burned')
          .eq('user_id', userId)
          .eq('date', dateString)
          .maybeSingle();

      return response?['calories_burned'] as int? ?? 0;
    } catch (e) {
      throw Exception('Analitik getirme hatası: $e');
    }
  }

  /// Günlük yakılan kaloriye ekleme yapar (antrenman tamamlanınca).
  Future<void> addCaloriesBurned({
    required String userId,
    required DateTime date,
    required int caloriesToAdd,
  }) async {
    if (caloriesToAdd <= 0) return;

    try {
      final dateString = date.toIso8601String().split('T')[0];
      final existing = await _supabase
          .from('user_analytics')
          .select('calories_burned, total_workouts')
          .eq('user_id', userId)
          .eq('date', dateString)
          .maybeSingle();

      final currentBurned = existing?['calories_burned'] as int? ?? 0;
      final currentWorkouts = existing?['total_workouts'] as int? ?? 0;

      await _supabase.from('user_analytics').upsert({
        'user_id': userId,
        'date': dateString,
        'calories_burned': currentBurned + caloriesToAdd,
        'total_workouts': currentWorkouts + 1,
      }, onConflict: 'user_id,date');
    } catch (e) {
      throw Exception('Kalori kaydı hatası: $e');
    }
  }

  /// Antrenman iptal edildiğinde yakılan kaloriyi geri al.
  Future<void> subtractCaloriesBurned({
    required String userId,
    required DateTime date,
    required int caloriesToSubtract,
  }) async {
    if (caloriesToSubtract <= 0) return;

    try {
      final dateString = date.toIso8601String().split('T')[0];
      final existing = await _supabase
          .from('user_analytics')
          .select('calories_burned, total_workouts')
          .eq('user_id', userId)
          .eq('date', dateString)
          .maybeSingle();

      if (existing == null) return;

      final currentBurned = existing['calories_burned'] as int? ?? 0;
      final currentWorkouts = existing['total_workouts'] as int? ?? 0;

      await _supabase.from('user_analytics').upsert({
        'user_id': userId,
        'date': dateString,
        'calories_burned': (currentBurned - caloriesToSubtract).clamp(0, 99999),
        'total_workouts': (currentWorkouts - 1).clamp(0, 999),
      }, onConflict: 'user_id,date');
    } catch (e) {
      throw Exception('Kalori güncelleme hatası: $e');
    }
  }
}
