import '../config/supabase_config.dart';

class WorkoutProgressService {
  final _supabase = SupabaseConfig.client;

  // Günlük antrenman tamamlama durumunu kaydet/güncelle
  Future<void> markWorkoutDay({
    required String userId,
    required String workoutId,
    required DateTime date,
    required bool completed,
    String? notes,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0]; // Sadece tarih

      await _supabase.from('workout_progress').upsert({
        'user_id': userId,
        'workout_id': workoutId,
        'date': dateString,
        'completed': completed,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,workout_id,date');
    } catch (e) {
      throw Exception('Antrenman günü işaretleme hatası: $e');
    }
  }

  // Belirli bir tarih için antrenman durumunu getir
  Future<bool> getWorkoutDayStatus({
    required String userId,
    required String workoutId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('workout_progress')
          .select('completed')
          .eq('user_id', userId)
          .eq('workout_id', workoutId)
          .eq('date', dateString)
          .maybeSingle();

      return response?['completed'] as bool? ?? false;
    } catch (e) {
      throw Exception('Antrenman günü durumu getirme hatası: $e');
    }
  }

  // Haftalık ilerlemeyi getir (bu hafta için)
  Future<Map<String, bool>> getWeeklyProgress({
    required String userId,
    required String workoutId,
  }) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final response = await _supabase
          .from('workout_progress')
          .select('date, completed')
          .eq('user_id', userId)
          .eq('workout_id', workoutId)
          .gte('date', startOfWeek.toIso8601String().split('T')[0])
          .lte('date', endOfWeek.toIso8601String().split('T')[0]);

      final progressMap = <String, bool>{};
      for (var item in response as List) {
        progressMap[item['date'] as String] = item['completed'] as bool;
      }

      return progressMap;
    } catch (e) {
      throw Exception('Haftalık ilerleme getirme hatası: $e');
    }
  }

  // Haftalık tamamlama yüzdesini hesapla (bu hafta için - eski metod)
  Future<double> getWeeklyCompletionPercentage({
    required String userId,
    required String workoutId,
  }) async {
    try {
      final weeklyProgress = await getWeeklyProgress(
        userId: userId,
        workoutId: workoutId,
      );

      if (weeklyProgress.isEmpty) return 0.0;

      final completedDays = weeklyProgress.values.where((completed) => completed).length;
      return completedDays / weeklyProgress.length;
    } catch (e) {
      throw Exception('Haftalık tamamlama yüzdesi hesaplama hatası: $e');
    }
  }

  // Programın tüm süresi için tamamlama yüzdesini hesapla
  // Programın tüm haftaları dolduğunda %100'e ulaşır
  Future<double> getWorkoutProgramCompletionPercentage({
    required String userId,
    required String workoutId,
    required int totalWeeks,
  }) async {
    try {
      // Programın ilk antrenman gününü bul (veya programın aktif olduğu tarih)
      final allProgress = await _supabase
          .from('workout_progress')
          .select('date, completed')
          .eq('user_id', userId)
          .eq('workout_id', workoutId)
          .order('date', ascending: true);

      DateTime? programStartDate;
      
      if (allProgress != null && (allProgress as List).isNotEmpty) {
        // İlk antrenman gününü başlangıç olarak al
        final firstDate = (allProgress as List).first['date'] as String;
        programStartDate = DateTime.parse(firstDate);
      } else {
        // Eğer hiç antrenman yoksa, bugünden itibaren say
        programStartDate = DateTime.now();
      }

      // Programın bitiş tarihini hesapla (başlangıç + hafta sayısı)
      final programEndDate = programStartDate.add(Duration(days: totalWeeks * 7));
      
      // Toplam gün sayısı
      final totalDays = totalWeeks * 7;
      
      // Şu ana kadar tamamlanan gün sayısını hesapla
      int completedDays = 0;
      if (allProgress != null && (allProgress as List).isNotEmpty) {
        completedDays = (allProgress as List)
            .where((item) => item['completed'] == true)
            .length;
      }

      // Yüzdeyi hesapla (0.0 - 1.0 arası)
      final percentage = totalDays > 0 ? (completedDays / totalDays).clamp(0.0, 1.0) : 0.0;
      
      return percentage;
    } catch (e) {
      throw Exception('Program tamamlama yüzdesi hesaplama hatası: $e');
    }
  }

  // Belirli bir tarih aralığındaki tüm kayıtları getir
  Future<List<Map<String, dynamic>>> getProgressInDateRange({
    required String userId,
    required String workoutId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('workout_progress')
          .select()
          .eq('user_id', userId)
          .eq('workout_id', workoutId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date');

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Tarih aralığı ilerleme getirme hatası: $e');
    }
  }
}

