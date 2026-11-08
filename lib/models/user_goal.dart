class UserGoal {
  final String? id;
  final String userId;
  final String goalType; // 'weight_loss', 'muscle_gain', 'physiotherapy', 'general_fitness'
  final double? targetWeight;
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final int workoutDaysPerWeek;
  final List<int> workoutDays; // 1=Pazartesi ... 7=Pazar
  final int programWeeks;
  final String experienceLevel; // 'beginner', 'intermediate', 'advanced'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserGoal({
    this.id,
    required this.userId,
    required this.goalType,
    this.targetWeight,
    this.activityLevel = 'moderate',
    this.workoutDaysPerWeek = 3,
    this.workoutDays = const [],
    this.programWeeks = 6,
    this.experienceLevel = 'beginner',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    return UserGoal(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      goalType: json['goal_type'] as String,
      targetWeight: json['target_weight'] != null
          ? (json['target_weight'] as num).toDouble()
          : null,
      activityLevel: json['activity_level'] as String? ?? 'moderate',
      workoutDaysPerWeek: json['workout_days_per_week'] as int? ?? 3,
      workoutDays: json['workout_days'] != null
          ? (json['workout_days'] as List<dynamic>).map((e) => e as int).toList()
          : const [],
      programWeeks: json['program_weeks'] as int? ?? 6,
      experienceLevel: json['experience_level'] as String? ?? 'beginner',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'goal_type': goalType,
      'target_weight': targetWeight,
      'activity_level': activityLevel,
      'workout_days_per_week': workoutDaysPerWeek,
      'workout_days': workoutDays,
      'program_weeks': programWeeks,
      'experience_level': experienceLevel,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get goalTypeDisplayName {
    switch (goalType) {
      case 'weight_loss':
        return 'Kilo Verme';
      case 'muscle_gain':
        return 'Kas Yapma';
      case 'physiotherapy':
        return 'Fizyoterapi';
      case 'general_fitness':
        return 'Genel Fitness';
      default:
        return goalType;
    }
  }

  String get activityLevelDisplayName {
    switch (activityLevel) {
      case 'sedentary':
        return 'Hareketsiz';
      case 'light':
        return 'Hafif Aktif';
      case 'moderate':
        return 'Orta Aktif';
      case 'active':
        return 'Aktif';
      case 'very_active':
        return 'Çok Aktif';
      default:
        return activityLevel;
    }
  }

  String get experienceLevelDisplayName {
    switch (experienceLevel) {
      case 'beginner':
        return 'Başlangıç';
      case 'intermediate':
        return 'Orta';
      case 'advanced':
        return 'İleri';
      default:
        return experienceLevel;
    }
  }

  String get workoutDaysDisplayName {
    if (workoutDays.isEmpty) return '';
    const dayNames = {1: 'Pzt', 2: 'Sal', 3: 'Çar', 4: 'Per', 5: 'Cum', 6: 'Cmt', 7: 'Paz'};
    final sorted = List<int>.from(workoutDays)..sort();
    return sorted.map((d) => dayNames[d] ?? '').join(', ');
  }

  UserGoal copyWith({
    String? id,
    String? userId,
    String? goalType,
    double? targetWeight,
    String? activityLevel,
    int? workoutDaysPerWeek,
    List<int>? workoutDays,
    int? programWeeks,
    String? experienceLevel,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      workoutDays: workoutDays ?? this.workoutDays,
      programWeeks: programWeeks ?? this.programWeeks,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
