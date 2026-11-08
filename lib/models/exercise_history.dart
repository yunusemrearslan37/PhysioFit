class ExerciseHistory {
  final String id;
  final String userId;
  final String exerciseId;
  final DateTime date;
  final int? sets;
  final int? reps;
  final double? weight;
  final int? duration; // saniye cinsinden
  final String? notes;
  final DateTime createdAt;

  ExerciseHistory({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.date,
    this.sets,
    this.reps,
    this.weight,
    this.duration,
    this.notes,
    required this.createdAt,
  });

  factory ExerciseHistory.fromJson(Map<String, dynamic> json) {
    return ExerciseHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseId: json['exercise_id'] as String,
      date: DateTime.parse(json['date'] as String),
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      duration: json['duration'] as int?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_id': exerciseId,
      'date': date.toIso8601String().split('T')[0], // Sadece tarih
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'duration': duration,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

