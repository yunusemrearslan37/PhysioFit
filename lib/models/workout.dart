class Workout {
  final String id;
  final String userId;
  final String name;
  final List<WorkoutExercise> exercises;
  final int weeks; // Kaç hafta boyunca yapılacak
  final bool isActive; // Aktif antrenman mı
  final DateTime createdAt;
  final DateTime updatedAt;

  Workout({
    required this.id,
    required this.userId,
    required this.name,
    required this.exercises,
    required this.weeks,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weeks: json['weeks'] as int? ?? 4,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'weeks': weeks,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int? reps; // Tekrar sayısı (opsiyonel)
  /// Kardiyovasküler vb. süre bazlı hareketlerde toplam süre (saniye). Doluysa set×tekrar yerine gösterilir.
  final int? durationSeconds;
  final double? weight; // Ağırlık (opsiyonel)
  final int? restSeconds; // Setler arası dinlenme süresi (saniye)
  final String? notes; // Notlar

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.reps,
    this.durationSeconds,
    this.weight,
    this.restSeconds,
    this.notes,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      restSeconds: json['rest_seconds'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      'weight': weight,
      'rest_seconds': restSeconds,
      'notes': notes,
    };
  }
}

/// Program satırında set×tekrar veya süre özeti (TR).
String workoutExerciseVolumeText(WorkoutExercise ex) {
  final d = ex.durationSeconds;
  if (d != null && d > 0) {
    return formatDurationSecondsTurkish(d);
  }
  if (ex.reps != null) {
    return '${ex.sets} set × ${ex.reps} tekrar';
  }
  return '${ex.sets} set';
}

String formatDurationSecondsTurkish(int totalSeconds) {
  if (totalSeconds < 60) return '$totalSeconds sn';
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  if (s == 0) return '$m dk';
  return '$m dk $s sn';
}

