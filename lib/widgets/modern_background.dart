import 'dart:ui';
import 'package:flutter/material.dart';

class ModernBackground extends StatelessWidget {
  final Widget child;

  const ModernBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bulanık arka plan şekilleri (Modern Glassmorphism)
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x2600E5FF), // %15 Cyan
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x4D1E3A8A), // %30 Koyu Lacivert
            ),
          ),
        ),
        Positioned(
          top: 250,
          right: -150,
          child: Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x40312E81), // %25 İndigo
            ),
          ),
        ),
        // Blur filtresi
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // Ana İçerik
        child,
      ],
    );
  }
}
