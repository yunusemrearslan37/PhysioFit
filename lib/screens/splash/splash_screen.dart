import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../utils/password_recovery_navigation.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../config/supabase_config.dart';
import '../../utils/password_recovery_state.dart';
import '../../services/auth_service.dart';
import '../../services/notification_preferences_service.dart';
import '../../widgets/modern_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.enableAutoNavigate = true,
  });

  /// Widget testlerinde timer/push işlemlerini devre dışı bırakmak için.
  final bool enableAutoNavigate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animasyon controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade animasyonu
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Scale animasyonu
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Animasyonu başlat
    _animationController.forward();

    // 2.5 saniye sonra ana sayfaya geç
    if (widget.enableAutoNavigate) {
      _navigateToHome();
    }
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    isSplashFinished = true;

    final supabase = SupabaseConfig.client;
    final session = supabase.auth.currentSession;

    if (isPasswordRecoveryPending) {
      openPasswordRecoveryScreen(replaceEntireStack: true);
      return;
    }

    if (session == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    try {
      await NotificationPreferencesService().applyWaterReminder();
    } catch (_) {}

    // Onboarding tamamlanmış mı kontrol et
    Widget destination = const HomeScreen();
    final authService = AuthService();
    try {
      await authService.markUserActive();
      final profile = await authService.getUserProfile();
      if (profile != null && !profile.onboardingCompleted) {
        destination = const OnboardingScreen();
      }
    } catch (_) {
      // Profil alınamazsa Home'a git
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Ana sayfa (`HomeScreen`) ile aynı taban renk — logo PNG içindeki koyu kutu
  /// ile bütünleşir, eski mavi gradient köşe konturu yaratmazdı; şimdi tek tip zemin.
  static const Color _splashBg = Color(0xFF050914);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _splashBg,
      body: ModernBackground(
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00E5FF),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.22),
                                  blurRadius: 28,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo2.png',
                                width: 240,
                                height: 240,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF121A2F),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.fitness_center,
                                      size: 80,
                                      color: Color(0xFF00E5FF),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Fitness & Fizyoterapi',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.75),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

