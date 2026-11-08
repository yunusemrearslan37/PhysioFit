import '../config/supabase_config.dart';
import '../models/user_limitation.dart';

class UserLimitationsService {
  final _supabase = SupabaseConfig.client;

  Future<List<UserLimitation>> getActiveLimitations(String userId) async {
    try {
      final response = await _supabase
          .from('user_limitations')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserLimitation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Aktif kısıtlamaları getirme hatası: $e');
    }
  }

  Future<List<UserLimitation>> getAllLimitations(String userId) async {
    try {
      final response = await _supabase
          .from('user_limitations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserLimitation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Kısıtlamaları getirme hatası: $e');
    }
  }

  Future<UserLimitation> addLimitation({
    required String userId,
    required String bodyPart,
    required String limitationType,
    String severity = 'medium',
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('user_limitations')
          .insert({
            'user_id': userId,
            'body_part': bodyPart,
            'limitation_type': limitationType,
            'severity': severity,
            'notes': notes,
            'is_active': true,
          })
          .select()
          .single();

      return UserLimitation.fromJson(response);
    } catch (e) {
      throw Exception('Kısıtlama ekleme hatası: $e');
    }
  }

  Future<UserLimitation> updateLimitation({
    required String limitationId,
    String? bodyPart,
    String? limitationType,
    String? severity,
    String? notes,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (bodyPart != null) updateData['body_part'] = bodyPart;
      if (limitationType != null) updateData['limitation_type'] = limitationType;
      if (severity != null) updateData['severity'] = severity;
      if (notes != null) updateData['notes'] = notes;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from('user_limitations')
          .update(updateData)
          .eq('id', limitationId)
          .select()
          .single();

      return UserLimitation.fromJson(response);
    } catch (e) {
      throw Exception('Kısıtlama güncelleme hatası: $e');
    }
  }

  Future<void> deleteLimitation(String limitationId) async {
    try {
      await _supabase.from('user_limitations').delete().eq('id', limitationId);
    } catch (e) {
      throw Exception('Kısıtlama silme hatası: $e');
    }
  }

  /// Aynı vücut bölgesindeki aktif kısıtlamaları iyileşme sonrası kapatır.
  Future<int> deactivateLimitationsForBodyPart({
    required String userId,
    required String bodyPart,
  }) async {
    try {
      final normalizedTarget = _normalizeBodyPart(bodyPart);
      final limitations = await getActiveLimitations(userId);
      var updated = 0;

      for (final limitation in limitations) {
        if (_normalizeBodyPart(limitation.bodyPart) != normalizedTarget) continue;
        await updateLimitation(
          limitationId: limitation.id!,
          isActive: false,
          notes: limitation.notes == null
              ? 'Rehab planı sonrası geçti olarak işaretlendi'
              : '${limitation.notes} (Rehab sonrası geçti)',
        );
        updated++;
      }
      return updated;
    } catch (e) {
      throw Exception('Kısıtlama kapatma hatası: $e');
    }
  }

  String _normalizeBodyPart(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }
}
