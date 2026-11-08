import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedGender;
  File? _selectedImage;
  DateTime? _selectedBirthDate;
  bool _didWarmUpPickers = false;


  @override
  void initState() {
    super.initState();
    // Picker'lar ilk kez açılırken oluşan jank'ı azaltmak için warm-up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _warmUpPickers();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _warmUpPickers() {
    if (!mounted || _didWarmUpPickers) return;
    _didWarmUpPickers = true;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final warmUpEntry = OverlayEntry(
      builder: (context) {
        // Offstage: ekranda görünmez ama widget'lar bir kez build olur (ilk açılış maliyeti burada ödenir)
        return Offstage(
          offstage: true,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                // Date picker warm-up
                SizedBox(
                  height: 200,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      primaryColor: Color(0xFF00E5FF),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime:
                          DateTime.now().subtract(const Duration(days: 365 * 25)),
                      minimumDate: DateTime(1900),
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (_) {},
                    ),
                  ),
                ),
                // Gender sheet warm-up
                const ListTile(
                  title: Text('Erkek'),
                  leading: Icon(Icons.people_outline),
                ),
                const ListTile(
                  title: Text('Kadın'),
                  leading: Icon(Icons.people_outline),
                ),
                const ListTile(
                  title: Text('Diğer'),
                  leading: Icon(Icons.people_outline),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(warmUpEntry);
    // Bir frame sonra kaldır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      warmUpEntry.remove();
    });
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  Future<void> _selectBirthDate() async {
    DateTime temp = _selectedBirthDate ??
        DateTime.now().subtract(const Duration(days: 365 * 25));

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Doğum Tarihi Seç',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      primaryColor: Color(0xFF00E5FF),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: temp,
                      minimumDate: DateTime(1900),
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (value) => temp = value,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedBirthDate = DateTime(temp.year, temp.month, temp.day);
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Seç',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectGender() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Widget item(String value) => ListTile(
              title: Text(value, style: const TextStyle(color: Colors.white)),
              trailing: _selectedGender == value
                  ? const Icon(Icons.check, color: Color(0xFF00E5FF))
                  : null,
              onTap: () => Navigator.of(context).pop(value),
            );

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cinsiyet Seç',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              item('Erkek'),
              item('Kadın'),
              item('Diğer'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedGender = selected;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEmailVerificationDialog(String email) async {
    bool isResending = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF003366),
          title: const Text(
            'E-posta Doğrulama Gerekli',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '$email adresine doğrulama e-postası gönderildi. '
            'Lütfen e-postanızı kontrol edin ve doğrulama linkine tıklayın. '
            'E-posta doğrulandıktan sonra giriş yapabilirsiniz.\n\n'
            'E-postayı bulamadıysanız spam klasörünü kontrol edin.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: isResending
                  ? null
                  : () async {
                      setDialogState(() {
                        isResending = true;
                      });
                      try {
                        await _authService.resendEmailVerification(email);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('E-posta yeniden gönderildi. Lütfen kontrol edin.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('E-posta gönderilemedi: ${e.toString().replaceFirst('Exception: ', '')}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setDialogState(() {
                          isResending = false;
                        });
                      }
                    },
              child: isResending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                      ),
                    )
                  : const Text(
                      'E-postayı Yeniden Gönder',
                      style: TextStyle(color: Colors.lightBlueAccent),
                    ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Register screen'den çık
              },
              child: const Text(
                'Tamam',
                style: TextStyle(color: Colors.lightBlueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // Doğum tarihi kontrolü
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen doğum tarihinizi seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cinsiyet kontrolü
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen cinsiyetinizi seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Profil resmi artık opsiyonel, kontrol kaldırıldı

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    User? createdUser;
    
    try {
      // Önce kullanıcıyı oluştur
      createdUser = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        birthDate: _selectedBirthDate!,
        gender: _selectedGender!,
      );

      // Profil resmini yükle (opsiyonel)
      // NOT: E-posta doğrulanmamışsa oturum kapatıldı, bu yüzden
      // profil resmi yükleme işlemi e-posta doğrulandıktan sonra yapılmalı
      if (createdUser != null && _selectedImage != null) {
        final isEmailConfirmed = createdUser.emailConfirmedAt != null;
        
        // Sadece e-posta doğrulanmışsa profil resmini yükle
        if (isEmailConfirmed) {
          try {
            final avatarUrl = await _storageService.uploadProfileImage(
              userId: createdUser.id,
              imageFile: _selectedImage!,
            );

            await _authService.updateUserProfile(
              avatarUrl: avatarUrl,
            );
          } catch (e) {
            // Resim yükleme hatası kritik değil, sadece log
            debugPrint('Profil resmi yükleme hatası detayı: $e');
            // E-posta doğrulanmışsa kullanıcıyı silme, sadece resim yüklenemedi
          }
        }
        // E-posta doğrulanmamışsa profil resmi e-posta doğrulandıktan sonra yüklenecek
      }

      if (createdUser != null && mounted) {
        // E-posta doğrulama kontrolü
        final isEmailConfirmed = createdUser.emailConfirmedAt != null;
        
        if (!isEmailConfirmed) {
          // E-posta doğrulanmamış - kullanıcıya bilgi göster
          // Oturum zaten kapatıldı (AuthService'de)
          // Trigger otomatik olarak temel profili oluşturdu
          if (mounted) {
            _showEmailVerificationDialog(createdUser.email!);
          }
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } catch (e) {
      // Herhangi bir hata durumunda kullanıcıyı sil (rollback)
      if (createdUser != null) {
        try {
          await _authService.deleteUserOnError(createdUser.id);
        } catch (deleteError) {
          debugPrint('Kullanıcı silme hatası: $deleteError');
        }
      }
      
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Arka plan için koyu mavi teknolojik bir gradient (login ile uyumlu)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003366), // Koyu Lacivert (Üst)
              Color(0xFF000B1A), // Siyaha yakın Lacivert (Alt)
            ],
          ),
        ),
        child: Stack(
          children: [
            // --- İÇERİK (Logo, Form vb.) ---
            SafeArea(
              child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- LOGO ALANI (YUKARIDA) ---
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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

                    const SizedBox(height: 10),

                   /* const Text(
                      "Kayıt Ol",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),*/

                    const SizedBox(height: 20),

                    // --- PROFİL RESMİ SEÇİMİ (OPSİYONEL) ---
                    const Text(
                      "Profil Resmi (Opsiyonel)",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white70,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Resim Ekle",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: const Text(
                            "Resmi Kaldır",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // --- FORM ALANLARI ---

                    // Ad Soyad Input
                    _buildTextField(
                      controller: _nameController,
                      label: "Ad Soyad *",
                      icon: Icons.person_outline,
                      inputType: TextInputType.name,
                      allowTurkishChars: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ad soyad gerekli';
                        }
                        if (value.trim().length < 2) {
                          return 'Ad soyad en az 2 karakter olmalı';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // E-posta Input
                    _buildTextField(
                      controller: _emailController,
                      label: "E-mail *",
                      icon: Icons.email_outlined,
                      inputType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta adresi gerekli';
                        }
                        // Gmail kontrolü
                        final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Sadece Gmail adresi kabul edilir (örn: kullanici@gmail.com)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Şifre Input
                    _buildTextField(
                      controller: _passwordController,
                      label: "Şifre *",
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

                    const SizedBox(height: 20),

                    // Şifre Tekrar Input
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: "Şifre Tekrar *",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isObscure: _obscureConfirmPassword,
                      onVisibilityToggle: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre tekrarı gerekli';
                        }
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Doğum Tarihi Seçici
                    GestureDetector(
                      onTap: _selectBirthDate,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 20,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedBirthDate == null
                                        ? "Doğum Tarihi *"
                                        : "Doğum Tarihi",
                                    style: TextStyle(
                                      color: _selectedBirthDate == null
                                          ? Colors.white70
                                          : Colors.white70.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_selectedBirthDate != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(_selectedBirthDate!),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_selectedBirthDate != null)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Cinsiyet Seçici (BottomSheet)
                    GestureDetector(
                      onTap: _selectGender,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 20,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedGender == null
                                        ? "Cinsiyet *"
                                        : "Cinsiyet",
                                    style: TextStyle(
                                      color: _selectedGender == null
                                          ? Colors.white70
                                          : Colors.white70.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_selectedGender != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedGender!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (_selectedGender != null)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              )
                            else
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white70,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- KAYIT OL BUTONU ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007ACC), // Buton mavisi
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                "Kayıt Ol",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- GİRİŞ YAP LİNKİ ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Zaten hesabınız var mı? ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "Giriş Yap",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET: TEXT FIELD ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool isObscure = false,
    bool allowTurkishChars = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    // Türkçe karakterleri de içeren formatter
    final inputFormatters = allowTurkishChars
        ? [
            FilteringTextInputFormatter.allow(
              RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ\s]'),
            ),
          ]
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white70, size: 22),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.lightBlueAccent,
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
