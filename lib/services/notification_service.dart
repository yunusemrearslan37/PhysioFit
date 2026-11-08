import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Antrenman hatırlatıcıları: haftanın günü (1–7).
  static const int workoutReminderIdMin = 1;
  static const int workoutReminderIdMax = 7;

  /// Günlük su hatırlatıcısı. Antrenman bildirimleriyle aynı kimliği kullanmaz.
  static const int dailyWaterReminderNotificationId = 3000;

  Future<void> init({
    void Function(String? payload)? onDidReceiveNotificationTap,
  }) async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onDidReceiveNotificationTap?.call(response.payload);
      },
    );
    _initialized = true;
  }

  Future<void> cancelWorkoutRemindersOnly() async {
    await init();
    for (var id = workoutReminderIdMin; id <= workoutReminderIdMax; id++) {
      await _plugin.cancel(id);
    }
  }

  Future<void> cancelDailyWaterReminder() async {
    await init();
    await _plugin.cancel(dailyWaterReminderNotificationId);
  }

  Future<void> scheduleDailyWaterReminder({
    required int hour,
    required int minute,
  }) async {
    await init();

    final granted = await requestPermission();
    if (!granted) {
      debugPrint('Su hatirlaticisi: bildirim izni yok.');
      return;
    }

    await _plugin.cancel(dailyWaterReminderNotificationId);

    final scheduledDate = _nextInstanceOfDailyTime(hour, minute);
    final timeLabel =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    final androidDetails = AndroidNotificationDetails(
      'water_reminders',
      'Su Hatırlatıcısı',
      channelDescription: 'Günlük su içme hatırlatması',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      dailyWaterReminderNotificationId,
      'Su hatırlatması 💧',
      'Bugün yeterince su içtin mi? Bir bardak daha iyi gelebilir.',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('Su hatirlaticisi kuruldu: her gun $timeLabel');
  }

  tz.TZDateTime _nextInstanceOfDailyTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Antrenman günleri için haftalık tekrarlı bildirimler kur
  /// [workoutDays]: 1=Pazartesi ... 7=Pazar
  Future<void> scheduleWorkoutReminders({
    required List<int> workoutDays,
    int hour = 9,
    int minute = 0,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    await init();
    await cancelWorkoutRemindersOnly();

    for (final dayOfWeek in workoutDays) {
      await _scheduleWeeklyNotification(
        id: dayOfWeek,
        dayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
        title: 'Antrenman Zamanı! 💪',
        body: _getMotivationMessage(dayOfWeek),
        playSound: playSound,
        enableVibration: enableVibration,
      );
    }

    debugPrint('Bildirimler kuruldu: ${workoutDays.length} gün');
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required int dayOfWeek,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required bool playSound,
    required bool enableVibration,
  }) async {
    final scheduledDate = _nextInstanceOfWeekday(dayOfWeek, hour, minute);

    final androidDetails = AndroidNotificationDetails(
      'workout_reminders',
      'Antrenman Hatırlatıcıları',
      channelDescription: 'Antrenman günlerinde hatırlatma bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      playSound: playSound,
      enableVibration: enableVibration,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfWeekday(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  String _getMotivationMessage(int dayOfWeek) {
    const messages = [
      'Bugün antrenman günün! Hedefine bir adım daha yaklaş.',
      'Harika bir antrenman günü seni bekliyor!',
      'Bugün ter dökme zamanı! Programına sadık kal.',
      'Unutma, tutarlılık başarının anahtarı. Haydi başla!',
      'Vücudun sana teşekkür edecek. Antrenmanını aksatma!',
      'Güçlü hissetmek istiyorsan bugün antrenman yap!',
      'Her antrenman seni bir adım ileriye taşır.',
    ];
    return messages[(dayOfWeek - 1) % messages.length];
  }

  Future<void> cancelAllNotifications() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await init();

    final workoutId = data?['workoutId']?.toString();
    final payload = (workoutId != null && workoutId.isNotEmpty)
        ? jsonEncode({'workoutId': workoutId})
        : null;

    const androidDetails = AndroidNotificationDetails(
      'push_notifications',
      'Push Bildirimleri',
      channelDescription: 'Sunucudan gelen push bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }
}
