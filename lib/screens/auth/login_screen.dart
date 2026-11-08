import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import '../../services/auth_service.dart';
import '../../services/notification_preferences_service.dart';
import '../../config/supabase_config.dart';
import '../../utils/password_recovery_state.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // App lifecycle'ı dinle
    WidgetsBinding.instance.addObserver(this);

    // Görseli önceden cache'le (arka planda yükle)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImage();
      // Uygulama açıldığında mevcut session'ı kontrol et
      _checkExistingSession();
    });

    // OAuth akışı için auth state'i dinle
    _listenToAuthState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Uygulama geri geldiğinde (resumed) session kontrolü yap
    if (state == AppLifecycleState.resumed) {
      debugPrint('Uygulama geri geldi, session kontrol ediliyor...');
      _checkExistingSession();
    }
  }

  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    try {
      await NotificationPreferencesService().applyWaterReminder();
    } catch (_) {}
    try {
      final profile = await _authService.getUserProfile();
      if (!mounted) return;
      if (profile != null && !profile.onboardingCompleted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _checkExistingSession() async {
    if (!mounted) return;
    if (isPasswordRecoveryPending) return;

    final supabase = SupabaseConfig.client;

    try {
      final currentSession = supabase.auth.currentSession;
      if (currentSession != null) {
        await _authService.syncGoogleProfileToUserProfile();
        debugPrint('Mevcut session bulundu: ${currentSession.user.email}');
        await _navigateAfterAuth();
        return;
      }

      await supabase.auth.refreshSession();
      final refreshedSession = supabase.auth.currentSession;
      if (refreshedSession != null && mounted && !isPasswordRecoveryPending) {
        await _authService.syncGoogleProfileToUserProfile();
        debugPrint('Session yenilendi: ${refreshedSession.user.email}');
        await _navigateAfterAuth();
      }
    } catch (e) {
      debugPrint('Session kontrolü hatası: $e');
    }
  }

  void _listenToAuthState() {
    final supabase = SupabaseConfig.client;
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null || !mounted) return;

      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('Yeni session oluşturuldu: ${session.user.email}');
      await _authService.syncGoogleProfileToUserProfile();
      setState(() {
        _isLoading = false;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !isPasswordRecoveryPending) _navigateAfterAuth();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _precacheImage() async {
    if (!mounted) return;
    try {
      await precacheImage(
        const AssetImage('assets/images/wallpaper4.png'),
        context,
      );
    } catch (e) {
      // Hata durumunda sessizce devam et
      debugPrint('Görsel preload hatası: $e');
    }
  }


  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null; // Hata durumunu sıfırla
    });

    try {
      final session = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (session != null && mounted) {
        try {
          final user = _authService.currentUser;
          if (user != null) {
            final metadata = user.userMetadata;
            if (metadata != null &&
                (metadata['birth_date'] != null ||
                    metadata['gender'] != null ||
                    metadata['name'] != null)) {
              await _authService.updateProfileFromMetadata();
            }
          }
        } catch (e) {
          debugPrint('Profil güncelleme hatası (giriş sonrası): $e');
        }

        await _navigateAfterAuth();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');

        // E-posta bulunamadı hatası kontrolü
        if (errorMessage.contains('E-posta bulunamadı')) {
          setState(() {
            _emailError = 'E-posta bulunamadı';
          });
          // Form'u tekrar validate et ki hata gösterilsin
          _formKey.currentState?.validate();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF003366),
          title: const Text(
            'Şifremi Unuttum',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kayıtlı e-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.lightBlueAccent),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Geçerli bir e-posta adresi girin'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSending = true);
                      try {
                        await _authService.resetPasswordForEmail(email);
                        if (!context.mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(context).pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '$email adresine şifre sıfırlama bağlantısı gönderildi. '
                              'E-postanızı kontrol edin.',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setDialogState(() => isSending = false);
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                      ),
                    )
                  : const Text(
                      'Gönder',
                      style: TextStyle(color: Colors.lightBlueAccent),
                    ),
            ),
          ],
        ),
      ),
    );

    emailController.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // OAuth akışını başlat
      // Uygulama içinde web view açılacak ve kullanıcı Google ile giriş yapacak
      // Deep link ile geri döndüğünde, authStateChange listener session'ı yakalayacak
      await _authService.signInWithGoogle();

      // OAuth akışı başlatıldı, uygulama içinde web view açıldı
      // Session oluşturulduğunda _listenToAuthState() içindeki listener kullanıcıyı yönlendirecek
      // Burada bir şey yapmamıza gerek yok
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF000B1A), // Arka plan görselinin alt tonu (koyu lacivert)
      body: Stack(
        children: [
          // --- ARKA PLAN GÖRSELİ (YUKARI KAYDIRILMIŞ) ---
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, -70), // ← Görsel yukarı kaydırıldı
              child: Image.asset(
                'assets/images/wallpaper4.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF003366),
                        Color(0xFF000B1A),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Görsel Yüklenemedi",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- GRADIENT OVERLAY ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),

          // --- İÇERİK ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 45),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 10),
                      const Text(
                        "PhysioFit",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 3),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          label: "E-mail",
                          icon: Icons.email_outlined,
                          inputType: TextInputType.emailAddress,
                          errorText: _emailError,
                          onChanged: (value) {
                            // Kullanıcı yazmaya başladığında hatayı temizle
                            if (_emailError != null && value.isNotEmpty) {
                              setState(() {
                                _emailError = null;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'E-posta adresi gerekli';
                            }
                            if (!value.contains('@')) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                            // Eğer hata mesajı varsa göster
                            if (_emailError != null) {
                              return _emailError;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        _buildTextField(
                          controller: _passwordController,
                          label: "Şifre",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isObscure: _obscurePassword,
                          onVisibilityToggle: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre gerekli';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalı';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 1),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _showForgotPasswordDialog,
                            child: const Text(
                              "Şifremi Unuttum?",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 2),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007ACC),
                              foregroundColor: Colors.white,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text(
                              "Giriş Yap",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _isLoading ? null : _handleGoogleSignIn,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: Color(0xFF4285F4),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 25),

                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Kayıt Ol",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool isObscure = false,
    String? errorText,
    ValueChanged<String>? onChanged,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    final hasError = errorText != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: inputType,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hasError ? Colors.red : Colors.white70,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: hasError ? Colors.red : Colors.white70,
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: onVisibilityToggle,
          )
              : null,
          errorText: errorText,
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.transparent,
              width: hasError ? 1.5 : 0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.lightBlueAccent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }
}
