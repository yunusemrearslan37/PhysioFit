class Exercise {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? equipmentType;
  final bool isHidden;
  final String? animationUrl;
  final String? videoUrl;
  final List<String>? muscleGroups;
  final List<String>? instructions;
  final String? difficulty; // 'beginner', 'intermediate', 'advanced'
  final double? metValue; // Kardiyo/kuvvet kalori tahmini için MET
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.equipmentType,
    this.isHidden = false,
    this.animationUrl,
    this.videoUrl,
    this.muscleGroups,
    this.instructions,
    this.difficulty,
    this.metValue,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      equipmentType: json['equipment_type'] as String?,
      isHidden: (json['is_hidden'] as bool?) ?? false,
      animationUrl: json['animation_url'] as String?,
      videoUrl: json['video_url'] as String?,
      muscleGroups: json['muscle_groups'] != null
          ? List<String>.from(json['muscle_groups'] as List)
          : null,
      instructions: json['instructions'] != null
          ? List<String>.from(json['instructions'] as List)
          : null,
      difficulty: json['difficulty'] as String?,
      metValue: json['met_value'] != null
          ? (json['met_value'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'equipment_type': equipmentType,
      'is_hidden': isHidden,
      'animation_url': animationUrl,
      'video_url': videoUrl,
      'muscle_groups': muscleGroups,
      'instructions': instructions,
      'difficulty': difficulty,
      'met_value': metValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

