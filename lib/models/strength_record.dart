class StrengthRecord {
  final String id;
  final String userId;
  final String exerciseType; // 'bench_press', 'overhead_press', 'squat', 'deadlift'
  final double weight; // kg cinsinden (PR - Personal Record)
  final DateTime date;
  final DateTime createdAt;

  StrengthRecord({
    required this.id,
    required this.userId,
    required this.exerciseType,
    required this.weight,
    required this.date,
    required this.createdAt,
  });

  factory StrengthRecord.fromJson(Map<String, dynamic> json) {
    return StrengthRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseType: json['exercise_type'] as String,
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_type': exerciseType,
      'weight': weight,
      'date': date.toIso8601String().split('T')[0], // Sadece tarih
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Egzersiz tipini Türkçe'ye çevir
  String get exerciseTypeName {
    switch (exerciseType) {
      case 'bench_press':
        return 'Bench Press';
      case 'overhead_press':
        return 'Overhead Press';
      case 'squat':
        return 'Squat';
      case 'deadlift':
        return 'Deadlift';
      default:
        return exerciseType;
    }
  }
}

