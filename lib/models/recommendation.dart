class Recommendation {
  final String id;
  final String userId;
  final String exerciseId;
  final String? reason;
  final int priority;
  final DateTime createdAt;

  Recommendation({
    required this.id,
    required this.userId,
    required this.exerciseId,
    this.reason,
    this.priority = 0,
    required this.createdAt,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      exerciseId: json['exercise_id'] as String,
      reason: json['reason'] as String?,
      priority: json['priority'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_id': exerciseId,
      'reason': reason,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

