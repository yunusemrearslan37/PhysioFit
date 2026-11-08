import '../config/supabase_config.dart';
import '../models/exercise_history.dart';

class ExerciseHistoryService {
  final _supabase = SupabaseConfig.client;

  // Kullanıcının egzersiz geçmişini getir
  Future<List<ExerciseHistory>> getUserHistory(String userId) async {
    try {
      final response = await _supabase
          .from('exercise_history')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExerciseHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Egzersiz geçmişi getirme hatası: $e');
    }
  }

  // Belirli bir tarih aralığındaki geçmişi getir
  Future<List<ExerciseHistory>> getUserHistoryByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('exercise_history')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExerciseHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Tarih aralığına göre geçmiş getirme hatası: $e');
    }
  }

  // Egzersiz geçmişi ekle
  Future<ExerciseHistory> addExerciseHistory({
    required String userId,
    required String exerciseId,
    required DateTime date,
    int? sets,
    int? reps,
    double? weight,
    int? duration,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('exercise_history')
          .insert({
            'user_id': userId,
            'exercise_id': exerciseId,
            'date': date.toIso8601String().split('T')[0],
            'sets': sets,
            'reps': reps,
            'weight': weight,
            'duration': duration,
            'notes': notes,
          })
          .select()
          .single();

      return ExerciseHistory.fromJson(response);
    } catch (e) {
      throw Exception('Egzersiz geçmişi ekleme hatası: $e');
    }
  }

  // Egzersiz geçmişi güncelle
  Future<ExerciseHistory> updateExerciseHistory({
    required String historyId,
    int? sets,
    int? reps,
    double? weight,
    int? duration,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('exercise_history')
          .update({
            if (sets != null) 'sets': sets,
            if (reps != null) 'reps': reps,
            if (weight != null) 'weight': weight,
            if (duration != null) 'duration': duration,
            if (notes != null) 'notes': notes,
          })
          .eq('id', historyId)
          .select()
          .single();

      return ExerciseHistory.fromJson(response);
    } catch (e) {
      throw Exception('Egzersiz geçmişi güncelleme hatası: $e');
    }
  }

  // Egzersiz geçmişi sil
  Future<void> deleteExerciseHistory(String historyId) async {
    try {
      await _supabase
          .from('exercise_history')
          .delete()
          .eq('id', historyId);
    } catch (e) {
      throw Exception('Egzersiz geçmişi silme hatası: $e');
    }
  }
}

