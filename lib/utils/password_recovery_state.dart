/// Şifre sıfırlama deep link'i işlenirken splash'in ana sayfaya atlamasını engeller.
bool isPasswordRecoveryPending = false;

/// Aynı anda birden fazla reset ekranı açılmasını engeller.
bool isRecoveryNavigationHandled = false;

/// Splash tamamlandıktan sonra sıcak başlatma deep link'leri işlenir.
bool isSplashFinished = false;

void resetPasswordRecoveryState() {
  isPasswordRecoveryPending = false;
  isRecoveryNavigationHandled = false;
}
