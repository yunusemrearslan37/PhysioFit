import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../models/workout.dart';
import 'push_notification_api_service.dart';

class WorkoutService {
  final _supabase = SupabaseConfig.client;
  final _pushNotificationApiService = PushNotificationApiService();

  // Kullanıcının tüm antrenmanlarını getir
  Future<List<Workout>> getUserWorkouts(String userId) async {
    try {
      final response = await _supabase
          .from('workouts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Workout.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Antrenmanları getirme hatası: $e');
    }
  }

  // ID'ye göre antrenman getir
  Future<Workout?> getWorkoutById(String id) async {
    try {
      final response = await _supabase
          .from('workouts')
          .select()
          .eq('id', id)
          .single();

      return Workout.fromJson(response);
    } catch (e) {
      throw Exception('Antrenman getirme hatası: $e');
    }
  }

  // Aktif antrenmanı getir
  Future<Workout?> getActiveWorkout(String userId) async {
    try {
      final response = await _supabase
          .from('workouts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return Workout.fromJson(response);
    } catch (e) {
      throw Exception('Aktif antrenman getirme hatası: $e');
    }
  }

  // Yeni antrenman oluştur
  Future<Workout> createWorkout({
    required String userId,
    required String name,
    required List<WorkoutExercise> exercises,
    required int weeks,
  }) async {
    try {
      final workoutData = {
        'user_id': userId,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'weeks': weeks,
        'is_active': false, // Yeni oluşturulan antrenman varsayılan olarak aktif değil
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('workouts')
          .insert(workoutData)
          .select()
          .single();

      final workout = Workout.fromJson(response);
      unawaited(_sendPlanUpdateNotification(workout));

      return workout;
    } catch (e) {
      throw Exception('Antrenman oluşturma hatası: $e');
    }
  }

  Future<void> _sendPlanUpdateNotification(Workout workout) async {
    try {
      await _pushNotificationApiService.sendNotification(
        title: 'Yeni programın hazır!',
        body: _truncateNotificationBody(
          '${workout.name} programın oluşturuldu. Hadi ilk antrenmana başlayalım.',
        ),
        notificationType: 'plan_update',
        data: {
          'workoutId': workout.id,
          'workoutName': workout.name,
          'weeks': workout.weeks,
          'exerciseCount': workout.exercises.length,
          'dedupKey': 'plan_update_${workout.id}',
        },
      );
    } catch (e) {
      debugPrint('Plan güncelleme bildirimi gönderilemedi: $e');
    }
  }

  String _truncateNotificationBody(String body) {
    const maxLength = 240;
    if (body.length <= maxLength) return body;
    return '${body.substring(0, maxLength - 3)}...';
  }

  // Antrenman güncelle
  Future<Workout> updateWorkout({
    required String id,
    String? name,
    List<WorkoutExercise>? exercises,
    int? weeks,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) {
        updateData['name'] = name;
      }

      if (exercises != null) {
        updateData['exercises'] = exercises.map((e) => e.toJson()).toList();
      }

      if (weeks != null) {
        updateData['weeks'] = weeks;
      }

      if (isActive != null) {
        updateData['is_active'] = isActive;
      }

      final response = await _supabase
          .from('workouts')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Workout.fromJson(response);
    } catch (e) {
      throw Exception('Antrenman güncelleme hatası: $e');
    }
  }

  // Aktif antrenmanı ayarla (diğerlerini pasif yapar)
  Future<void> setActiveWorkout(String userId, String workoutId) async {
    try {
      // Önce tüm antrenmanları pasif yap
      await _supabase
          .from('workouts')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId);

      // Sonra seçilen antrenmanı aktif yap
      await _supabase
          .from('workouts')
          .update({'is_active': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', workoutId);
    } catch (e) {
      throw Exception('Aktif antrenman ayarlama hatası: $e');
    }
  }

  // Antrenman sil
  Future<void> deleteWorkout(String id) async {
    try {
      await _supabase.from('workouts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Antrenman silme hatası: $e');
    }
  }
}
