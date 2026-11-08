class Injury {
  final String id;
  final String userId;
  final String injuryType;
  final String? bodyPart;
  final String? severity; // 'low', 'medium', 'high'
  final DateTime? date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Injury({
    required this.id,
    required this.userId,
    required this.injuryType,
    this.bodyPart,
    this.severity,
    this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Injury.fromJson(Map<String, dynamic> json) {
    return Injury(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      injuryType: json['injury_type'] as String,
      bodyPart: json['body_part'] as String?,
      severity: json['severity'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'injury_type': injuryType,
      'body_part': bodyPart,
      'severity': severity,
      'date': date?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

