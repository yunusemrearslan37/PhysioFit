class UserMetric {
  final String? id;
  final String userId;
  final double? height; // cm
  final double? weight; // kg
  final double? bodyFatPercentage;
  final DateTime recordedAt;
  final DateTime createdAt;

  UserMetric({
    this.id,
    required this.userId,
    this.height,
    this.weight,
    this.bodyFatPercentage,
    required this.recordedAt,
    required this.createdAt,
  });

  double? get bmi {
    if (height == null || weight == null || height! <= 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final value = bmi;
    if (value == null) return 'Bilinmiyor';
    if (value < 18.5) return 'Zayıf';
    if (value < 25) return 'Normal';
    if (value < 30) return 'Fazla Kilolu';
    return 'Obez';
  }

  factory UserMetric.fromJson(Map<String, dynamic> json) {
    return UserMetric(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      bodyFatPercentage: json['body_fat_percentage'] != null
          ? (json['body_fat_percentage'] as num).toDouble()
          : null,
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'height': height,
      'weight': weight,
      'body_fat_percentage': bodyFatPercentage,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
