/// Cinsiyet değerlerini Türkçe ve İngilizce arasında dönüştüren yardımcı sınıf
class GenderHelper {
  /// Türkçe cinsiyet değerlerini İngilizce'ye çevirir (veritabanı için)
  static String? toEnglish(String? turkishGender) {
    if (turkishGender == null || turkishGender.isEmpty) {
      return null;
    }
    
    switch (turkishGender) {
      case 'Erkek':
        return 'male';
      case 'Kadın':
        return 'female';
      case 'Diğer':
        return 'other';
      default:
        // Eğer zaten İngilizce ise olduğu gibi döndür
        if (turkishGender == 'male' || turkishGender == 'female' || turkishGender == 'other') {
          return turkishGender;
        }
        return null;
    }
  }

  /// İngilizce cinsiyet değerlerini Türkçe'ye çevirir (UI için)
  static String? toTurkish(String? englishGender) {
    if (englishGender == null || englishGender.isEmpty) {
      return null;
    }
    
    switch (englishGender) {
      case 'male':
        return 'Erkek';
      case 'female':
        return 'Kadın';
      case 'other':
        return 'Diğer';
      default:
        // Eğer zaten Türkçe ise olduğu gibi döndür
        if (englishGender == 'Erkek' || englishGender == 'Kadın' || englishGender == 'Diğer') {
          return englishGender;
        }
        return null;
    }
  }
}

