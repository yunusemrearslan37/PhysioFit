/// Kırmızı bayrak semptomları — herhangi biri işaretlenirse acil yönlendirme.
const List<Map<String, String>> injuryRedFlags = [
  {
    'id': 'numbness',
    'title': 'Uyuşma veya karıncalanma',
    'description': 'Kol/bacakta veya bölgede his kaybı',
  },
  {
    'id': 'night_pain',
    'title': 'Gece ağrısı',
    'description': 'Uyurken artan veya uyandıran ağrı',
  },
  {
    'id': 'fever_swelling',
    'title': 'Ateş veya şiddetli şişlik',
    'description': 'Bölgede belirgin şişlik, kızarıklık veya ateş',
  },
  {
    'id': 'weight_bearing',
    'title': 'Ağırlık verememe',
    'description': 'Travma sonrası basamama veya ciddi güç kaybı',
  },
  {
    'id': 'sudden_severe',
    'title': 'Ani şiddetli ağrı',
    'description': 'Bir hareketle başlayan çok şiddetli ağrı',
  },
];

class RehabDayPlan {
  final int day;
  final String focus;
  final List<String> exerciseNames;

  const RehabDayPlan({
    required this.day,
    required this.focus,
    required this.exerciseNames,
  });
}

class InjuryGuidance {
  final List<String> recommendedDos;
  final List<String> recommendedDonts;
  final String recoveryEstimate;
  final String doctorAdvice;
  final List<RehabDayPlan> rehabPlan;

  const InjuryGuidance({
    required this.recommendedDos,
    required this.recommendedDonts,
    required this.recoveryEstimate,
    required this.doctorAdvice,
    required this.rehabPlan,
  });
}

class InjuryAssessmentGuidance {
  static InjuryGuidance redFlagGuidance() {
    return const InjuryGuidance(
      recommendedDos: [
        'Bölgeyi zorlamayın ve dinlenin',
        'Buz uygulayın (15-20 dk, günde birkaç kez)',
        'En kısa sürede sağlık uzmanına başvurun',
      ],
      recommendedDonts: [
        'Ağrılı hareketleri tekrarlamayın',
        'Kendi kendinize ağır egzersiz yapmayın',
        'Ağrı kesiciyle sadece belirtileri gizleyip spor yapmayın',
      ],
      recoveryEstimate: 'Acil değerlendirme önerilir',
      doctorAdvice:
          'Belirttiğiniz belirtiler ciddi olabilir. Lütfen doktor veya fizyoterapiste başvurun.',
      rehabPlan: [],
    );
  }

  static InjuryGuidance build({
    required String bodyPart,
    required String riskLevel,
    required int severityScore,
  }) {
    final normalized = _normalizeBodyPart(bodyPart);
    final dos = _dosFor(normalized, riskLevel);
    final donts = _dontsFor(normalized, riskLevel);
    final recovery = _recoveryFor(riskLevel, severityScore);
    final doctor = _doctorAdviceFor(riskLevel);
    return InjuryGuidance(
      recommendedDos: dos,
      recommendedDonts: donts,
      recoveryEstimate: recovery,
      doctorAdvice: doctor,
      rehabPlan: const [],
    );
  }

  static String severityToLimitationLevel(String riskLevel) {
    switch (riskLevel) {
      case 'Yüksek Risk':
        return 'high';
      case 'Orta Risk':
        return 'medium';
      default:
        return 'low';
    }
  }

  static String severityToInjuryLevel(String riskLevel) {
    switch (riskLevel) {
      case 'Yüksek Risk':
        return 'high';
      case 'Orta Risk':
        return 'medium';
      default:
        return 'low';
    }
  }

  static List<String> _dosFor(String bodyPart, String riskLevel) {
    final common = <String>[
      'Isınmadan önce hafif mobilite yapın',
      'Ağrı artarsa hareketi durdurun',
      'Yeterli dinlenme ve uyku alın',
    ];

    final specific = <String, List<String>>{
      'diz': ['Quad ve hamstring germe', 'Düşük etkili bisiklet tercih edin'],
      'omuz': ['Omuz pendulum hareketi', 'Postürü düzeltin'],
      'bel': ['Core stabilizasyonu', 'Uzun süre oturmaktan kaçının'],
      'boyun': ['Boyun germe ve chin tuck', 'Ekran yüksekliğini ayarlayın'],
      'ayak bilegi': ['Bilek dairesel hareketler', 'Uygun ayakkabı kullanın'],
      'dirsek': ['Ön kol germe', 'Tekrarlı zorlayıcı kavramalardan kaçının'],
      'kalca': ['Kalça fleksör germe', 'Kalça mobilitesi çalışın'],
    };

    if (riskLevel == 'Düşük Risk') {
      return [...(specific[bodyPart] ?? []), ...common];
    }
    if (riskLevel == 'Orta Risk') {
      return [
        'Fizyoterapi egzersizlerini düşük yoğunlukta uygulayın',
        ...(specific[bodyPart] ?? []),
        ...common,
      ];
    }
    return [
      'Dinlenme ve buz uygulaması',
      'Doktor onayı olmadan spor yapmayın',
      ...common.take(1),
    ];
  }

  static List<String> _dontsFor(String bodyPart, String riskLevel) {
    final highImpact = <String>[
      'Ağır squat ve deadlift',
      'Zıplama ve sprint',
      'Ağrılı hareketi tekrarlama',
    ];

    final specific = <String, List<String>>{
      'diz': ['Derin squat', 'Koşu ve zıplama', 'Diz üzerine aşırı yük'],
      'omuz': ['Overhead press', 'Ağır bench press', 'Tam açıyla zorlayıcı kaldırma'],
      'bel': ['Ağır deadlift', 'Rotasyonlu ağırlık kaldırma', 'Uzun süre eğilme'],
      'boyun': ['Ağır overhead hareketler', 'Ani boyun rotasyonu'],
      'ayak bilegi': ['Koşu', 'Yüksekten iniş', 'Ani yön değiştirme'],
      'dirsek': ['Ağır curl/extension', 'Tekrarlı zorlayıcı kavrama'],
      'kalca': ['Ağır squat', 'Lateral zıplama', 'Uzun mesafe koşu'],
    };

    if (riskLevel == 'Yüksek Risk') {
      return [...highImpact, ...(specific[bodyPart] ?? [])];
    }
    if (riskLevel == 'Orta Risk') {
      return specific[bodyPart] ?? highImpact;
    }
    return [
      'Ağrıyı artıran hareketler',
      ...(specific[bodyPart]?.take(2) ?? []),
    ];
  }

  static String _recoveryFor(String riskLevel, int score) {
    if (riskLevel == 'Yüksek Risk') {
      return '2-6 hafta veya daha uzun — doktor değerlendirmesi gerekir';
    }
    if (riskLevel == 'Orta Risk') {
      return '2-4 hafta kontrollü rehabilitasyon önerilir';
    }
    if (score < 25) {
      return '3-7 gün hafif mobilite ile iyileşme beklenir';
    }
    return '1-2 hafta hafif egzersiz ve dinlenme';
  }

  static String _doctorAdviceFor(String riskLevel) {
    switch (riskLevel) {
      case 'Yüksek Risk':
        return 'Yüksek risk skoru. Mutlaka doktor veya fizyoterapiste danışın.';
      case 'Orta Risk':
        return 'Belirtiler 2 haftadan uzun sürerse veya kötüleşirse uzmana başvurun.';
      default:
        return 'Belirtiler 1 haftadan uzun sürerse veya artarsa uzmana danışın.';
    }
  }

  static String _normalizeBodyPart(String bodyPart) {
    final normalized = bodyPart.toLowerCase().trim();
    if (normalized.contains('ayak')) return 'ayak bilegi';
    if (normalized.contains('kal')) return 'kalca';
    return normalized
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }
}
