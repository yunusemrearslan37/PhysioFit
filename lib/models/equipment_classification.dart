class EquipmentClassification {
  final String id;
  final String userId;
  final String imageUrl;
  final String equipmentType;
  final double? confidence; // 0.00 - 1.00
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  EquipmentClassification({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.equipmentType,
    this.confidence,
    this.metadata,
    required this.createdAt,
  });

  factory EquipmentClassification.fromJson(Map<String, dynamic> json) {
    return EquipmentClassification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      equipmentType: json['equipment_type'] as String,
      confidence: json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'equipment_type': equipmentType,
      'confidence': confidence,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

