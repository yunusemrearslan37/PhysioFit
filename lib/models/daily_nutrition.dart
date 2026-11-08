class DailyNutrition {
  final String? id;
  final String userId;
  final DateTime date;
  final int caloriesConsumed;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyNutrition({
    this.id,
    required this.userId,
    required this.date,
    required this.caloriesConsumed,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyNutrition.fromJson(Map<String, dynamic> json) {
    return DailyNutrition(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      caloriesConsumed: json['calories_consumed'] as int? ?? 0,
      notes: json['notes'] as String?,
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
      'date': date.toIso8601String().split('T')[0],
      'calories_consumed': caloriesConsumed,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
