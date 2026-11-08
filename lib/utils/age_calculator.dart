/// Yaş hesaplama yardımcı sınıfı
class AgeCalculator {
  /// Doğum tarihinden yaşı hesaplar
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    // Eğer henüz doğum günü gelmediyse yaşı 1 azalt
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Doğum tarihinden yaşı string olarak döndürür
  static String getAgeString(DateTime birthDate) {
    return calculateAge(birthDate).toString();
  }
}

