import '../config/supabase_config.dart';
import '../models/injury.dart';

class InjuryService {
  final _supabase = SupabaseConfig.client;

  // Kullanıcının tüm sakatlıklarını getir
  Future<List<Injury>> getUserInjuries(String userId) async {
    try {
      final response = await _supabase
          .from('injuries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Injury.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Sakatlıkları getirme hatası: $e');
    }
  }

  // Sakatlık ekle
  Future<Injury> addInjury({
    required String userId,
    required String injuryType,
    String? bodyPart,
    String? severity,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('injuries')
          .insert({
            'user_id': userId,
            'injury_type': injuryType,
            'body_part': bodyPart,
            'severity': severity,
            'date': date?.toIso8601String().split('T')[0],
            'notes': notes,
          })
          .select()
          .single();

      return Injury.fromJson(response);
    } catch (e) {
      throw Exception('Sakatlık ekleme hatası: $e');
    }
  }

  // Sakatlık güncelle
  Future<Injury> updateInjury({
    required String injuryId,
    String? injuryType,
    String? bodyPart,
    String? severity,
    DateTime? date,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('injuries')
          .update({
            if (injuryType != null) 'injury_type': injuryType,
            if (bodyPart != null) 'body_part': bodyPart,
            if (severity != null) 'severity': severity,
            if (date != null) 'date': date.toIso8601String().split('T')[0],
            if (notes != null) 'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', injuryId)
          .select()
          .single();

      return Injury.fromJson(response);
    } catch (e) {
      throw Exception('Sakatlık güncelleme hatası: $e');
    }
  }

  // Sakatlık sil
  Future<void> deleteInjury(String injuryId) async {
    try {
      await _supabase.from('injuries').delete().eq('id', injuryId);
    } catch (e) {
      throw Exception('Sakatlık silme hatası: $e');
    }
  }
}

