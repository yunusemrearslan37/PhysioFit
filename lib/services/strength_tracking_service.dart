import '../config/supabase_config.dart';
import '../models/strength_record.dart';

class StrengthTrackingService {
  final _supabase = SupabaseConfig.client;

  // Yeni güç kaydı ekle (PR - Personal Record)
  Future<StrengthRecord> addStrengthRecord({
    required String userId,
    required String exerciseType,
    required double weight,
    required DateTime date,
  }) async {
    try {
      final response = await _supabase
          .from('strength_records')
          .insert({
            'user_id': userId,
            'exercise_type': exerciseType,
            'weight': weight,
            'date': date.toIso8601String().split('T')[0],
          })
          .select()
          .single();

      return StrengthRecord.fromJson(response);
    } catch (e) {
      throw Exception('Güç kaydı ekleme hatası: $e');
    }
  }

  // Kullanıcının tüm güç kayıtlarını getir
  Future<List<StrengthRecord>> getUserStrengthRecords(String userId) async {
    try {
      final response = await _supabase
          .from('strength_records')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => StrengthRecord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Güç kayıtları getirme hatası: $e');
    }
  }

  // Belirli bir egzersiz tipine göre kayıtları getir
  Future<List<StrengthRecord>> getStrengthRecordsByExerciseType({
    required String userId,
    required String exerciseType,
  }) async {
    try {
      final response = await _supabase
          .from('strength_records')
          .select()
          .eq('user_id', userId)
          .eq('exercise_type', exerciseType)
          .order('date', ascending: true);

      return (response as List)
          .map((json) => StrengthRecord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Egzersiz tipine göre kayıt getirme hatası: $e');
    }
  }

  // Güç kaydı güncelle
  Future<StrengthRecord> updateStrengthRecord({
    required String recordId,
    double? weight,
    DateTime? date,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (weight != null) updateData['weight'] = weight;
      if (date != null) updateData['date'] = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('strength_records')
          .update(updateData)
          .eq('id', recordId)
          .select()
          .single();

      return StrengthRecord.fromJson(response);
    } catch (e) {
      throw Exception('Güç kaydı güncelleme hatası: $e');
    }
  }

  // Güç kaydı sil
  Future<void> deleteStrengthRecord(String recordId) async {
    try {
      await _supabase
          .from('strength_records')
          .delete()
          .eq('id', recordId);
    } catch (e) {
      throw Exception('Güç kaydı silme hatası: $e');
    }
  }

  // Belirli bir tarih aralığındaki kayıtları getir
  Future<List<StrengthRecord>> getStrengthRecordsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? exerciseType,
  }) async {
    try {
      var query = _supabase
          .from('strength_records')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      if (exerciseType != null) {
        query = query.eq('exercise_type', exerciseType);
      }

      final response = await query.order('date', ascending: true);

      return (response as List)
          .map((json) => StrengthRecord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Tarih aralığına göre kayıt getirme hatası: $e');
    }
  }
}

