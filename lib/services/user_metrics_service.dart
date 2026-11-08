import '../config/supabase_config.dart';
import '../models/user_metric.dart';

class UserMetricsService {
  final _supabase = SupabaseConfig.client;

  Future<UserMetric?> getLatestMetric(String userId) async {
    try {
      final response = await _supabase
          .from('user_metrics')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return UserMetric.fromJson(response);
    } catch (e) {
      throw Exception('Son metrik getirme hatası: $e');
    }
  }

  Future<List<UserMetric>> getMetricsHistory(String userId, {int limit = 30}) async {
    try {
      final response = await _supabase
          .from('user_metrics')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => UserMetric.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Metrik geçmişi getirme hatası: $e');
    }
  }

  Future<UserMetric> addMetric({
    required String userId,
    double? height,
    double? weight,
    double? bodyFatPercentage,
  }) async {
    try {
      final response = await _supabase
          .from('user_metrics')
          .insert({
            'user_id': userId,
            'height': height,
            'weight': weight,
            'body_fat_percentage': bodyFatPercentage,
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return UserMetric.fromJson(response);
    } catch (e) {
      throw Exception('Metrik ekleme hatası: $e');
    }
  }

  Future<void> deleteMetric(String metricId) async {
    try {
      await _supabase.from('user_metrics').delete().eq('id', metricId);
    } catch (e) {
      throw Exception('Metrik silme hatası: $e');
    }
  }
}
