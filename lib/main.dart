import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/app_navigator.dart';
import 'utils/password_recovery_navigation.dart';
import 'utils/password_recovery_state.dart';
import 'utils/push_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i başlat
  await SupabaseConfig.initialize();

  await NotificationService().init(
    onDidReceiveNotificationTap: PushNavigation.handleLocalNotificationTap,
  );

  // Push notification altyapısını desteklenen platformlarda başlat
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    await PushNotificationService().init();
  }

  // Deep link dinleme (OAuth callback için)
  _handleDeepLinks();

  runApp(const MyApp());
}

void _handleDeepLinks() {
  final appLinks = AppLinks();
  final supabase = SupabaseConfig.client;

  Future<void> process(Uri uri) async {
    debugPrint('Deep link alındı: $uri');
    try {
      // PKCE akışında callback genelde ?code=... veya fragment içinde token döner
      final hasCode = uri.queryParameters.containsKey('code');
      final hasAccessToken = uri.queryParameters.containsKey('access_token') ||
          uri.fragment.contains('access_token');
      final isRecoveryLink = uri.queryParameters['type'] == 'recovery' ||
          uri.fragment.contains('type=recovery');

      if (!hasCode && !hasAccessToken) return;

      if (isRecoveryLink) {
        isPasswordRecoveryPending = true;
      }

      await supabase.auth.getSessionFromUrl(uri);
      debugPrint('Session deep link üzerinden işlendi');
    } catch (e) {
      debugPrint('Deep link işleme hatası: $e');
    }
  }

  // İlk link
  appLinks.getInitialLink().then((uri) {
    if (uri != null) process(uri);
  });

  // Runtime link
  appLinks.uriLinkStream.listen(process);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      if (data.event != AuthChangeEvent.passwordRecovery || data.session == null) {
        return;
      }

      isPasswordRecoveryPending = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isSplashFinished) return;
        openPasswordRecoveryScreen();
      });
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhysioFit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
    );
  }
}
