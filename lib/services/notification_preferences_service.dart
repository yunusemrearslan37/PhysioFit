import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../models/notification_preferences.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'user_goals_service.dart';

class NotificationPreferencesService {
  final _supabase = SupabaseConfig.client;
  final _authService = AuthService();
  final _userGoalsService = UserGoalsService();
  final _localNotificationService = NotificationService();

  Future<NotificationPreferences> getPreferences() async {
    final user = _authService.currentUser;
    if (user == null) {
      return const NotificationPreferences();
    }

    final response = await _supabase
        .from('notification_preferences')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      return const NotificationPreferences();
    }

    return NotificationPreferences.fromJson(response);
  }

  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('Bildirim ayarları için giriş yapmalısınız.');
    }

    final response = await _supabase
        .from('notification_preferences')
        .upsert(preferences.toJson(user.id))
        .select()
        .single();

    return NotificationPreferences.fromJson(response);
  }

  Future<void> syncLocalWorkoutReminders({
    NotificationPreferences? preferences,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final effectivePreferences = preferences ?? await getPreferences();

    if (!effectivePreferences.notificationsEnabled ||
        !effectivePreferences.workoutRemindersEnabled) {
      await _localNotificationService.cancelWorkoutRemindersOnly();
      return;
    }

    final goal = await _userGoalsService.getActiveGoal(user.id);
    final workoutDays = goal?.workoutDays ?? const <int>[];

    if (workoutDays.isEmpty) {
      await _localNotificationService.cancelWorkoutRemindersOnly();
      return;
    }

    final granted = await _localNotificationService.requestPermission();
    if (!granted) {
      return;
    }

    await _localNotificationService.scheduleWorkoutReminders(
      workoutDays: List<int>.from(workoutDays)..sort(),
      hour: effectivePreferences.reminderHour,
      minute: effectivePreferences.reminderMinute,
      playSound: effectivePreferences.soundEnabled,
      enableVibration: effectivePreferences.vibrationEnabled,
    );
  }

  Future<WaterReminderSettings> getWaterReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return WaterReminderSettings(
      enabled: prefs.getBool('water_reminder_enabled') ?? true,
      hour: prefs.getInt('water_reminder_hour') ?? 15,
      minute: prefs.getInt('water_reminder_minute') ?? 30,
    );
  }

  Future<void> saveWaterReminder(WaterReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminder_enabled', settings.enabled);
    await prefs.setInt('water_reminder_hour', settings.hour);
    await prefs.setInt('water_reminder_minute', settings.minute);
  }

  Future<void> applyWaterReminder([WaterReminderSettings? settings]) async {
    final value = settings ?? await getWaterReminder();
    if (!value.enabled) {
      await _localNotificationService.cancelDailyWaterReminder();
      return;
    }
    await _localNotificationService.scheduleDailyWaterReminder(
      hour: value.hour,
      minute: value.minute,
    );
  }
}

class WaterReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const WaterReminderSettings({
    this.enabled = true,
    this.hour = 15,
    this.minute = 30,
  });
}
