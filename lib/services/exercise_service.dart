import '../config/supabase_config.dart';
import '../models/exercise.dart';

class ExerciseService {
  final _supabase = SupabaseConfig.client;

  // Tüm egzersizleri getir
  Future<List<Exercise>> getAllExercises({bool includeHidden = false}) async {
    try {
      var query = _supabase.from('exercises').select();
      if (!includeHidden) {
        query = query.eq('is_hidden', false);
      }
      final response = await query.order('name');

      return (response as List)
          .map((json) => Exercise.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Egzersizleri getirme hatası: $e');
    }
  }

  // ID'ye göre egzersiz getir
  Future<Exercise?> getExerciseById(String id) async {
    try {
      final response = await _supabase
          .from('exercises')
          .select()
          .eq('id', id)
          .single();

      return Exercise.fromJson(response);
    } catch (e) {
      throw Exception('Egzersiz getirme hatası: $e');
    }
  }

  // Kategoriye göre egzersizleri getir
  Future<List<Exercise>> getExercisesByCategory(
    String category, {
    bool includeHidden = false,
  }) async {
    try {
      var query = _supabase.from('exercises').select().eq('category', category);
      if (!includeHidden) {
        query = query.eq('is_hidden', false);
      }
      final response = await query.order('name');

      return (response as List)
          .map((json) => Exercise.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Kategoriye göre egzersiz getirme hatası: $e');
    }
  }

  // Ekipman türüne göre egzersizleri getir
  Future<List<Exercise>> getExercisesByEquipment(
    String equipmentType, {
    bool includeHidden = false,
  }) async {
    try {
      var query =
          _supabase.from('exercises').select().eq('equipment_type', equipmentType);
      if (!includeHidden) {
        query = query.eq('is_hidden', false);
      }
      final response = await query.order('name');

      return (response as List)
          .map((json) => Exercise.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ekipmana göre egzersiz getirme hatası: $e');
    }
  }

  // Zorluk seviyesine göre egzersizleri getir
  Future<List<Exercise>> getExercisesByDifficulty(
    String difficulty, {
    bool includeHidden = false,
  }) async {
    try {
      var query = _supabase.from('exercises').select().eq('difficulty', difficulty);
      if (!includeHidden) {
        query = query.eq('is_hidden', false);
      }
      final response = await query.order('name');

      return (response as List)
          .map((json) => Exercise.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Zorluğa göre egzersiz getirme hatası: $e');
    }
  }
}

