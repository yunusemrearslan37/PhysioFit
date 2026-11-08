class NotificationPreferences {
  final bool notificationsEnabled;
  final bool workoutRemindersEnabled;
  final int reminderHour;
  final int reminderMinute;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool pushAiEnabled;
  final bool pushPlanUpdatesEnabled;
  final bool pushReengagementEnabled;

  const NotificationPreferences({
    this.notificationsEnabled = true,
    this.workoutRemindersEnabled = true,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.pushAiEnabled = true,
    this.pushPlanUpdatesEnabled = true,
    this.pushReengagementEnabled = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      workoutRemindersEnabled: json['workout_reminders_enabled'] as bool? ?? true,
      reminderHour: json['reminder_hour'] as int? ?? 9,
      reminderMinute: json['reminder_minute'] as int? ?? 0,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
      pushAiEnabled: json['push_ai_enabled'] as bool? ?? true,
      pushPlanUpdatesEnabled: json['push_plan_updates_enabled'] as bool? ?? true,
      pushReengagementEnabled: json['push_reengagement_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'notifications_enabled': notificationsEnabled,
      'workout_reminders_enabled': workoutRemindersEnabled,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'push_ai_enabled': pushAiEnabled,
      'push_plan_updates_enabled': pushPlanUpdatesEnabled,
      'push_reengagement_enabled': pushReengagementEnabled,
    };
  }

  NotificationPreferences copyWith({
    bool? notificationsEnabled,
    bool? workoutRemindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? pushAiEnabled,
    bool? pushPlanUpdatesEnabled,
    bool? pushReengagementEnabled,
  }) {
    return NotificationPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      workoutRemindersEnabled:
          workoutRemindersEnabled ?? this.workoutRemindersEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      pushAiEnabled: pushAiEnabled ?? this.pushAiEnabled,
      pushPlanUpdatesEnabled:
          pushPlanUpdatesEnabled ?? this.pushPlanUpdatesEnabled,
      pushReengagementEnabled:
          pushReengagementEnabled ?? this.pushReengagementEnabled,
    );
  }
}
