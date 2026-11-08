import 'dart:convert';

import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../screens/workouts/daily_workout_tracker_screen.dart';
import 'app_navigator.dart';

/// FCM / yerel bildirimden gelen `workoutId` ile antrenman takip ekranına yönlendirme.
class PushNavigation {
  PushNavigation._();

  static String? _pendingWorkoutId;

  /// Bildirim payload'ı JSON: `{"workoutId":"..."}`
  static void handleLocalNotificationTap(String? payload) {
    final id = _parseWorkoutIdFromPayload(payload);
    if (id != null) {
      _pendingWorkoutId = id;
    }
  }

  /// Uygulama kapalıyken açılış (pending — ana sayfa yüklenince flush).
  static void handleInitialRemoteMessage(Map<String, dynamic> data) {
    final id = data['workoutId']?.toString();
    if (id != null && id.isNotEmpty) {
      _pendingWorkoutId = id;
    }
  }

  /// Arka plandan bildirime tıklanınca (uygulama hafızadaysa hemen dene).
  static void handleRemoteMessageOpenedApp(Map<String, dynamic> data) {
    final id = data['workoutId']?.toString();
    if (id != null && id.isNotEmpty) {
      _pendingWorkoutId = id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        flushPendingWorkoutNavigation();
      });
    }
  }

  /// Ana sayfa hazır olduğunda çağır (Splash/onboarding sonrası).
  static void flushPendingWorkoutNavigation() {
    final id = _pendingWorkoutId;
    if (id == null || id.isEmpty) return;

    if (SupabaseConfig.client.auth.currentSession == null) return;

    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    _pendingWorkoutId = null;

    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => DailyWorkoutTrackerScreen(initialWorkoutId: id),
      ),
    );
  }

  static String? _parseWorkoutIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final id = map['workoutId']?.toString();
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return null;
  }
}
