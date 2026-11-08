class RehabPlanExercise {
  final String exerciseName;
  final String description;
  final int sets;
  final int? reps;
  final String? notes;

  const RehabPlanExercise({
    required this.exerciseName,
    required this.description,
    this.sets = 2,
    this.reps = 10,
    this.notes,
  });

  factory RehabPlanExercise.fromJson(Map<String, dynamic> json) {
    return RehabPlanExercise(
      exerciseName: json['exercise_name'] as String,
      description: json['description'] as String? ?? '',
      sets: json['sets'] as int? ?? 2,
      reps: json['reps'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      'description': description,
      'sets': sets,
      if (reps != null) 'reps': reps,
      if (notes != null) 'notes': notes,
    };
  }

  RehabPlanExercise copyWith({
    int? sets,
    int? reps,
    String? notes,
  }) {
    return RehabPlanExercise(
      exerciseName: exerciseName,
      description: description,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      notes: notes ?? this.notes,
    );
  }
}

class RehabPlan {
  final String id;
  final String userId;
  final String? assessmentId;
  final String bodyPart;
  final String name;
  final List<RehabPlanExercise> exercises;
  final int totalDays;
  final String recoveryStatus;
  final DateTime? recoveryCheckedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RehabPlan({
    required this.id,
    required this.userId,
    this.assessmentId,
    required this.bodyPart,
    required this.name,
    required this.exercises,
    required this.totalDays,
    this.recoveryStatus = 'aktif',
    this.recoveryCheckedAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRecovered => recoveryStatus == 'geçti';

  String get recoveryStatusDisplay {
    switch (recoveryStatus) {
      case 'geçti':
        return 'Geçti';
      case 'devam_ediyor':
        return 'Devam Ediyor';
      default:
        return 'Aktif';
    }
  }

  factory RehabPlan.fromJson(Map<String, dynamic> json) {
    return RehabPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assessmentId: json['assessment_id'] as String?,
      bodyPart: json['body_part'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => RehabPlanExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalDays: json['total_days'] as int? ?? 7,
      recoveryStatus: json['recovery_status'] as String? ?? 'aktif',
      recoveryCheckedAt: json['recovery_checked_at'] != null
          ? DateTime.parse(json['recovery_checked_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
