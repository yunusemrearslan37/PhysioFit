import '../config/supabase_config.dart';
import '../models/daily_nutrition.dart';

class DailyNutritionService {
  final _supabase = SupabaseConfig.client;

  Future<DailyNutrition?> getForDate({
    required String userId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('daily_nutrition')
          .select()
          .eq('user_id', userId)
          .eq('date', dateString)
          .maybeSingle();

      if (response == null) return null;
      return DailyNutrition.fromJson(response);
    } catch (e) {
      throw Exception('Beslenme kaydı getirme hatası: $e');
    }
  }

  Future<DailyNutrition> upsert({
    required String userId,
    required DateTime date,
    required int caloriesConsumed,
    String? notes,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      final response = await _supabase
          .from('daily_nutrition')
          .upsert({
            'user_id': userId,
            'date': dateString,
            'calories_consumed': caloriesConsumed,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,date')
          .select()
          .single();

      return DailyNutrition.fromJson(response);
    } catch (e) {
      throw Exception('Beslenme kaydı kaydetme hatası: $e');
    }
  }
}
