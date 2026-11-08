class UserLimitation {
  final String? id;
  final String userId;
  final String bodyPart;
  final String limitationType; // 'sakatlık', 'ameliyat', 'kronik ağrı', 'hareket kısıtlılığı'
  final String severity; // 'low', 'medium', 'high'
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserLimitation({
    this.id,
    required this.userId,
    required this.bodyPart,
    required this.limitationType,
    this.severity = 'medium',
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserLimitation.fromJson(Map<String, dynamic> json) {
    return UserLimitation(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      bodyPart: json['body_part'] as String,
      limitationType: json['limitation_type'] as String,
      severity: json['severity'] as String? ?? 'medium',
      notes: json['notes'] as String?,
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
      'body_part': bodyPart,
      'limitation_type': limitationType,
      'severity': severity,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get severityDisplayName {
    switch (severity) {
      case 'low':
        return 'Hafif';
      case 'medium':
        return 'Orta';
      case 'high':
        return 'Ağır';
      default:
        return severity;
    }
  }

  UserLimitation copyWith({
    String? id,
    String? userId,
    String? bodyPart,
    String? limitationType,
    String? severity,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserLimitation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bodyPart: bodyPart ?? this.bodyPart,
      limitationType: limitationType ?? this.limitationType,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
