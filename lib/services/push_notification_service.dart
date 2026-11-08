import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/supabase_config.dart';
import '../utils/push_navigation.dart';
import 'notification_service.dart';
import 'notification_preferences_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Firebase henüz yapılandırılmadıysa sessizce geç.
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final _supabase = SupabaseConfig.client;
  final _notificationPreferencesService = NotificationPreferencesService();
  final _localNotificationService = NotificationService();

  bool _initialized = false;

  bool get isSupportedPlatform {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> init() async {
    if (_initialized || !isSupportedPlatform) return;

    final firebaseReady = await _ensureFirebaseInitialized();
    if (!firebaseReady) return;

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground push alindi: ${message.messageId}');
      final title = message.notification?.title;
      final body = message.notification?.body;
      if (title != null && body != null) {
        _localNotificationService.showInstantNotification(
          title: title,
          body: body,
          data: Map<String, dynamic>.from(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      PushNavigation.handleRemoteMessageOpenedApp(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        PushNavigation.handleInitialRemoteMessage(message.data);
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) async {
        await _registerToken(token);
      },
    );

    _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        await syncTokenForCurrentUser();
      }
    });

    _initialized = true;
    await syncTokenForCurrentUser();
  }

  Future<bool> requestPermission() async {
    if (!isSupportedPlatform) return false;

    final firebaseReady = await _ensureFirebaseInitialized();
    if (!firebaseReady) return false;

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> syncTokenForCurrentUser({
    bool requestPermissionIfNeeded = false,
  }) async {
    if (!isSupportedPlatform) return;

    final firebaseReady = await _ensureFirebaseInitialized();
    if (!firebaseReady) return;

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final preferences = await _notificationPreferencesService.getPreferences();
    if (!preferences.notificationsEnabled) return;

    if (requestPermissionIfNeeded) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    await _registerToken(token);
  }

  Future<bool> _ensureFirebaseInitialized() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } catch (e) {
      debugPrint('Firebase initialize hatasi: $e');
      return false;
    }
  }

  Future<void> _registerToken(String token) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      await _supabase.functions.invoke(
        'register-device-token',
        body: {
          'token': token,
          'platform': _platformName,
        },
      );
    } catch (e) {
      debugPrint('Device token kaydetme hatasi: $e');
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }
}
