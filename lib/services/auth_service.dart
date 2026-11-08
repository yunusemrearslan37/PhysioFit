import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../utils/gender_helper.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  // Mobil doğrulama / OAuth dönüş callback'i
  // Supabase Dashboard > Authentication > URL Configuration > Redirect URLs listesine eklenmiş olmalı.
  static const String _mobileAuthCallbackUrl = 'io.supabase.flutter://login-callback';

  // Kayıt ol
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required DateTime birthDate,
    required String gender,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        // E-posta doğrulama linki uygulamaya geri dönsün
        emailRedirectTo: _mobileAuthCallbackUrl,
        // Trigger (raw_user_meta_data) bu verilerle user_profiles'u otomatik doldurur
        data: {
          'name': name,
          'birth_date': birthDate.toIso8601String(),
          'gender': GenderHelper.toEnglish(gender),
        },
        // E-posta doğrulama Supabase Dashboard'da etkinleştirilmeli
      );

      if (response.user != null) {
        // E-posta doğrulanmış mı kontrol et
        final isEmailConfirmed = response.user!.emailConfirmedAt != null;
        
        // TRIGGER ÇÖZÜMÜ: Trigger otomatik olarak profil oluşturacak
        // Trigger auth.users tablosunda AFTER INSERT çalıştığı için
        // RLS politikası bypass edilir ve profil otomatik oluşturulur
        // Profil bilgileri (name, birth_date, gender) e-posta doğrulandıktan sonra güncellenecek
        
        debugPrint('Kullanıcı oluşturuldu. Trigger otomatik olarak profil oluşturacak.');
        debugPrint('Kullanıcı ID: ${response.user!.id}');
        
        // E-posta doğrulanmışsa ve oturum açıksa, profili güncelle
        if (isEmailConfirmed) {
          try {
            final currentSession = _supabase.auth.currentSession;
            if (currentSession != null) {
              // Profil trigger ile oluşturulmuş olmalı, güncelle
              await _supabase.from('user_profiles').update({
                'email': email,
                'name': name,
                'birth_date': birthDate.toIso8601String(),
                'gender': GenderHelper.toEnglish(gender),
                'updated_at': DateTime.now().toIso8601String(),
              }).eq('id', response.user!.id);
              debugPrint('User profile güncellendi (e-posta doğrulanmış)');
            }
          } catch (e) {
            debugPrint('User profile güncelleme hatası: $e');
            // Hata kritik değil, trigger zaten temel profili oluşturdu
          }
        } else {
          // E-posta doğrulanmamışsa, profil bilgilerini geçici olarak sakla
          // Bu bilgiler e-posta doğrulandıktan sonra kullanılacak
          // Şimdilik trigger temel profili oluşturdu, bilgiler sonra güncellenecek
          debugPrint('E-posta doğrulanmamış. Profil bilgileri e-posta doğrulandıktan sonra güncellenecek.');
        }
        
        // E-posta doğrulanmamışsa, oturumu kapat (güvenlik için)
        // NOT: Trigger zaten temel profili oluşturdu
        if (!isEmailConfirmed) {
          // E-posta doğrulama e-postası gönderildi
          // Kullanıcı e-postasını kontrol etmeli
          // Oturumu kapat ki e-posta doğrulanmadan giriş yapamasın
          await _supabase.auth.signOut();
        }
      }

      return response.user;
    } on AuthException catch (e) {
      // Supabase auth hatalarını daha anlaşılır hale getir
      String errorMessage = 'Kayıt hatası: ';
      
      if (e.statusCode == '429') {
        errorMessage = 'Çok fazla deneme yaptınız. Lütfen birkaç dakika bekleyip tekrar deneyin.';
      } else if (e.message.contains('already registered')) {
        errorMessage = 'Bu e-posta adresi zaten kayıtlı. Giriş yapmayı deneyin.';
      } else if (e.message.contains('Invalid email')) {
        errorMessage = 'Geçersiz e-posta adresi. Lütfen geçerli bir e-posta girin.';
      } else if (e.message.contains('Password')) {
        errorMessage = 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
      } else {
        errorMessage = 'Kayıt hatası: ${e.message}';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Kayıt hatası: ${e.toString()}');
    }
  }

  // Giriş yap
  Future<Session?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await markUserActive();
      return response.session;
    } on AuthException catch (e) {
      // Supabase auth hatalarını daha anlaşılır hale getir
      String errorMessage = 'Giriş hatası: ';
      
      // E-posta bulunamadı kontrolü
      if (e.message.contains('Invalid login credentials') || 
          e.message.contains('Email not found') ||
          (e.statusCode == '400' && e.message.toLowerCase().contains('email'))) {
        errorMessage = 'E-posta bulunamadı';
      } else if (e.message.contains('Email not confirmed') || 
                 e.message.contains('email_not_confirmed') ||
                 e.message.contains('email address not confirmed')) {
        errorMessage = 'E-posta adresinizi doğrulamanız gerekiyor. Lütfen e-postanızı kontrol edin.';
      } else if (e.statusCode == '400' || e.message.contains('Invalid')) {
        errorMessage = 'E-posta veya şifre hatalı. Lütfen kontrol edin.';
      } else if (e.statusCode == '429') {
        errorMessage = 'Çok fazla deneme yaptınız. Lütfen birkaç dakika bekleyip tekrar deneyin.';
      } else {
        errorMessage = 'Giriş hatası: ${e.message}';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Giriş hatası: ${e.toString()}');
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Çıkış hatası: $e');
    }
  }

  // Mevcut kullanıcı
  User? get currentUser => _supabase.auth.currentUser;

  Future<void> markUserActive() async {
    try {
      final user = currentUser;
      if (user == null) return;

      await _supabase.from('user_profiles').update({
        'last_active_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Son aktiflik güncellenemedi: $e');
    }
  }

  // Kullanıcı profili getir
  Future<UserProfile?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) {
        debugPrint('getUserProfile: Kullanıcı giriş yapmamış');
        return null;
      }

      debugPrint('getUserProfile: Kullanıcı ID: ${user.id}');
      
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // single yerine maybeSingle kullan (kayıt yoksa null döner)

      if (response == null) {
        debugPrint('getUserProfile: Profil bulunamadı');
        return null;
      }

      debugPrint('getUserProfile: Profil bulundu: ${response['name']}');
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('getUserProfile hatası: $e');
      throw Exception('Profil getirme hatası: $e');
    }
  }

  // Kullanıcı profili güncelle
  Future<void> updateUserProfile({
    String? gender,
    String? avatarUrl,
    DateTime? birthDate,
    String? name,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (gender != null) {
        updateData['gender'] = GenderHelper.toEnglish(gender);
      }
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }
      if (birthDate != null) {
        updateData['birth_date'] = birthDate.toIso8601String();
      }
      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name.trim();
      }

      await _supabase.from('user_profiles').update(updateData).eq('id', user.id);
    } catch (e) {
      throw Exception('Profil güncelleme hatası: $e');
    }
  }

  bool _isGoogleUser(User user) {
    final provider = (user.appMetadata['provider'] ?? '').toString().toLowerCase();
    if (provider == 'google') return true;
    final providers = user.appMetadata['providers'];
    if (providers is List) {
      return providers.map((e) => e.toString().toLowerCase()).contains('google');
    }
    return false;
  }

  bool get canChangePassword {
    final user = currentUser;
    if (user == null) return false;
    return !_isGoogleUser(user);
  }

  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase.from('user_profiles').delete().eq('id', user.id);
      await signOut();
    } catch (e) {
      throw Exception('Hesap silme hatası: $e');
    }
  }

  // Google ile giriş sonrası isim + profil fotoğrafını user_profiles'a yaz
  Future<void> syncGoogleProfileToUserProfile() async {
    final user = currentUser;
    if (user == null) return;
    if (!_isGoogleUser(user)) return;

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final email = user.email;
    if (email == null) return;

    // Google metadata alan adları farklı gelebiliyor
    final name = (meta['full_name'] ??
            meta['name'] ??
            meta['given_name'] ??
            meta['display_name'])
        ?.toString()
        .trim();

    final avatarUrl = (meta['avatar_url'] ??
            meta['picture'] ??
            meta['avatar'] ??
            meta['photo_url'])
        ?.toString()
        .trim();

    try {
      final existing = await getUserProfile();

      final updateData = <String, dynamic>{
        'id': user.id,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Boşsa doldur (kullanıcı sonradan manuel değiştirdiyse üzerine yazmayalım)
      if ((existing?.name == null || existing!.name!.trim().isEmpty) &&
          name != null &&
          name.isNotEmpty) {
        updateData['name'] = name;
      }

      if ((existing?.avatarUrl == null || existing!.avatarUrl!.trim().isEmpty) &&
          avatarUrl != null &&
          avatarUrl.isNotEmpty) {
        updateData['avatar_url'] = avatarUrl;
      }

      // Sadece email/updated_at kaldıysa gereksiz upsert yapmayalım
      if (updateData.length <= 3) return;

      await _supabase.from('user_profiles').upsert(
            updateData,
            onConflict: 'id',
          );
    } catch (e) {
      // Kritik değil: Home ekranı yine açılır; sadece isim/pp güncellenememiş olur
      debugPrint('Google profil senkron hatası: $e');
    }
  }

  // Kayıt hatası durumunda kullanıcıyı sil (rollback)
  Future<void> deleteUserOnError(String userId) async {
    try {
      // User profile'ı sil
      await _supabase.from('user_profiles').delete().eq('id', userId);
      
      // Auth kullanıcısını sil (admin API gerekir, yoksa sadece profile silinir)
      // Not: Normal kullanıcılar kendi auth kayıtlarını silemez
      // Bu durumda user_profiles silinir ama auth.users'da kalır
      // Kullanıcı tekrar kayıt olmaya çalışırsa "already registered" hatası alır
      // Bu durumda kullanıcıya bilgi verilmeli
    } catch (e) {
      // Silme hatası kritik değil, sadece log
      debugPrint('Kullanıcı silme hatası: $e');
    }
  }

  // Metadata'dan profil bilgilerini güncelle (e-posta doğrulandıktan sonra)
  Future<void> updateProfileFromMetadata() async {
    try {
      final user = currentUser;
      if (user == null) return;
      
      final metadata = user.userMetadata;
      if (metadata == null) return;
      
      final birthDateStr = metadata['birth_date'] as String?;
      final genderStr = metadata['gender'] as String?;
      final nameStr = metadata['name'] as String?;
      
      if (birthDateStr != null || genderStr != null || nameStr != null) {
        final updateData = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (nameStr != null) {
          updateData['name'] = nameStr;
        }
        
        if (birthDateStr != null) {
          updateData['birth_date'] = birthDateStr;
        }
        
        if (genderStr != null) {
          updateData['gender'] = genderStr;
        }
        
        await _supabase.from('user_profiles').update(updateData).eq('id', user.id);
        debugPrint('Profil metadata\'dan güncellendi');
        
        // Metadata'yı temizle (artık gerekli değil)
        try {
          await _supabase.auth.updateUser(
            UserAttributes(
              data: {
                'birth_date': null,
                'gender': null,
                'name': null,
              },
            ),
          );
        } catch (e) {
          // Metadata temizleme hatası kritik değil
          debugPrint('Metadata temizleme hatası: $e');
        }
      }
    } catch (e) {
      debugPrint('Metadata\'dan profil güncelleme hatası: $e');
      // Hata kritik değil
    }
  }

  // Onboarding tamamlandı olarak işaretle
  Future<void> markOnboardingCompleted() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase.from('user_profiles').update({
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      throw Exception('Onboarding güncelleme hatası: $e');
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _mobileAuthCallbackUrl,
      );
    } on AuthException catch (e) {
      String errorMessage;
      if (e.statusCode == '429' || e.message.contains('rate limit')) {
        errorMessage =
            'Çok fazla deneme yaptınız. Lütfen birkaç dakika bekleyip tekrar deneyin.';
      } else if (e.message.contains('Invalid email')) {
        errorMessage = 'Geçersiz e-posta adresi. Lütfen geçerli bir e-posta girin.';
      } else {
        errorMessage = 'Şifre sıfırlama e-postası gönderilemedi: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Şifre sıfırlama e-postası gönderilemedi: $e');
    }
  }

  // Şifre sıfırlama linkinden sonra yeni şifre belirle
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      String errorMessage;
      if (e.message.contains('Password')) {
        errorMessage = 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
      } else if (e.statusCode == '401' || e.message.contains('session')) {
        errorMessage =
            'Şifre sıfırlama bağlantısının süresi dolmuş. Lütfen yeniden talep edin.';
      } else {
        errorMessage = 'Şifre güncellenemedi: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Şifre güncellenemedi: $e');
    }
  }

  // E-posta doğrulama e-postasını yeniden gönder
  Future<void> resendEmailVerification(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        // Yeniden gönderilen doğrulama linki de uygulamaya dönsün
        emailRedirectTo: _mobileAuthCallbackUrl,
      );
    } on AuthException catch (e) {
      String errorMessage = 'E-posta gönderilirken hata oluştu: ';
      if (e.message.contains('rate limit') || e.statusCode == '429') {
        errorMessage = 'Çok fazla deneme yaptınız. Lütfen birkaç dakika bekleyip tekrar deneyin.';
      } else {
        errorMessage = 'E-posta gönderilirken hata oluştu: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('E-posta gönderilirken hata oluştu: $e');
    }
  }
  // Google ile giriş yap
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // Supabase Flutter'ın önerdiği mobil callback (AndroidManifest'te tanımlı):
        // io.supabase.flutter://login-callback
        redirectTo: 'io.supabase.flutter://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

    } on AuthException catch (e) {
      String errorMessage;

      final msg = e.message.toLowerCase();
      if (e.statusCode == '429') {
        errorMessage =
            'Çok fazla deneme yaptınız. Lütfen birkaç dakika bekleyip tekrar deneyin.';
      } else if (msg.contains('requested path is invalid') || msg.contains('invalid')) {
        errorMessage =
            'Google giriş yönlendirmesi geçersiz. Supabase Dashboard > Authentication > URL Configuration > Redirect URLs listesine '
            '`io.supabase.flutter://login-callback` ekleyin ve Site URL\'in HTTPS olduğundan emin olun.';
      } else if (e.statusCode == '500' || msg.contains('unexpected')) {
        errorMessage =
            'Sunucu hatası oluştu. Lütfen Supabase Dashboard\'da Google OAuth ayarlarını kontrol edin.';
      } else if (msg.contains('provider is not enabled') ||
          msg.contains('unsupported provider') ||
          e.statusCode == '400') {
        errorMessage =
            'Google ile giriş şu anda kullanılamıyor. Lütfen e-posta ve şifre ile giriş yapın.';
      } else {
        errorMessage = 'Google ile giriş hatası: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Google ile giriş hatası: ${e.toString()}');
    }
  }
}

