import 'package:flutter/material.dart';

class NavigationHelper {
  /// Yumuşak slide animasyonu ile sayfa geçişi
  static PageRouteBuilder<T> createSlideRoute<T extends Object?>(
    Widget page, {
    Offset begin = const Offset(1.0, 0.0),
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: begin, end: Offset.zero).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Fade animasyonu ile sayfa geçişi
  static PageRouteBuilder<T> createFadeRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: curve),
          ),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Ana sayfadan çıkış için özel animasyon (fade + scale)
  /// Geri dönüş için de aynı fade + scale animasyonu kullanılır
  static PageRouteBuilder<T> createHomeExitRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Hem ileri gidiş hem geri dönüş için fade + scale animasyonu
        // Animation reverse durumunda otomatik olarak ters yönde çalışır
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        ).animate(animation);

        final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ).animate(animation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      reverseTransitionDuration: duration, // Geri dönüş için de aynı süre
    );
  }
}

