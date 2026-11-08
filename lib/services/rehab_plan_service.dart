import '../config/supabase_config.dart';
import '../models/rehab_plan.dart';

class RehabPlanService {
  final _supabase = SupabaseConfig.client;

  Future<RehabPlan> createPlan({
    required String userId,
    required String bodyPart,
    required String name,
    required List<RehabPlanExercise> exercises,
    required int totalDays,
    String? assessmentId,
  }) async {
    try {
      await _supabase
          .from('rehab_plans')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_active', true);

      final response = await _supabase
          .from('rehab_plans')
          .insert({
            'user_id': userId,
            'assessment_id': assessmentId,
            'body_part': bodyPart,
            'name': name,
            'exercises': exercises.map((e) => e.toJson()).toList(),
            'total_days': totalDays,
            'is_active': true,
            'recovery_status': 'aktif',
          })
          .select()
          .single();

      return RehabPlan.fromJson(response);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('rehab_plans') && msg.contains('PGRST205')) {
        throw Exception(
          'Veritabanında rehab_plans tablosu yok. '
          'Supabase SQL Editor\'de database/fix_rehab_plans_migration.sql dosyasını çalıştırın.',
        );
      }
      throw Exception('Rehab planı oluşturulamadı: $e');
    }
  }

  Future<RehabPlan?> getActivePlan(String userId) async {
    try {
      final response = await _supabase
          .from('rehab_plans')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('recovery_status', 'aktif')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return RehabPlan.fromJson(response);
    } catch (e) {
      if (e.toString().contains('PGRST205')) return null;
      throw Exception('Aktif rehab planı getirilemedi: $e');
    }
  }

  Future<RehabPlan?> getPlanById(String planId) async {
    try {
      final response = await _supabase
          .from('rehab_plans')
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (response == null) return null;
      return RehabPlan.fromJson(response);
    } catch (e) {
      throw Exception('Rehab planı getirilemedi: $e');
    }
  }

  Future<List<RehabPlan>> getUserPlans(String userId) async {
    try {
      final response = await _supabase
          .from('rehab_plans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RehabPlan.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Rehab planları getirilemedi: $e');
    }
  }

  Future<Set<int>> getCompletedDays({
    required String userId,
    required String rehabPlanId,
  }) async {
    try {
      final response = await _supabase
          .from('rehab_plan_progress')
          .select('day_number, completed')
          .eq('user_id', userId)
          .eq('rehab_plan_id', rehabPlanId)
          .eq('completed', true);

      return (response as List)
          .map((row) => row['day_number'] as int)
          .toSet();
    } catch (e) {
      throw Exception('Rehab ilerlemesi getirilemedi: $e');
    }
  }

  Future<void> markDayComplete({
    required String userId,
    required String rehabPlanId,
    required int dayNumber,
  }) async {
    try {
      await _supabase.from('rehab_plan_progress').upsert({
        'user_id': userId,
        'rehab_plan_id': rehabPlanId,
        'day_number': dayNumber,
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,rehab_plan_id,day_number');
    } catch (e) {
      throw Exception('Gün tamamlanamadı: $e');
    }
  }

  Future<void> updateRecoveryStatus({
    required String rehabPlanId,
    required String status,
    String? assessmentId,
  }) async {
    try {
      await _supabase.from('rehab_plans').update({
        'recovery_status': status,
        'recovery_checked_at': DateTime.now().toIso8601String(),
        'is_active': status == 'geçti' ? false : true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', rehabPlanId);

      if (assessmentId != null) {
        await _supabase.from('injury_assessments').update({
          'recovery_status': status,
          'recovery_checked_at': DateTime.now().toIso8601String(),
        }).eq('id', assessmentId);
      }
    } catch (e) {
      throw Exception('İyileşme durumu kaydedilemedi: $e');
    }
  }

  Future<double> getPlanCompletionRatio({
    required String userId,
    required String rehabPlanId,
    required int totalDays,
  }) async {
    final completed = await getCompletedDays(
      userId: userId,
      rehabPlanId: rehabPlanId,
    );
    if (totalDays <= 0) return 0;
    return (completed.length / totalDays).clamp(0.0, 1.0);
  }
}
