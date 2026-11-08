class CategoryImage {
  final String id;
  final String categoryKey;
  final String categoryName;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryImage({
    required this.id,
    required this.categoryKey,
    required this.categoryName,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryImage.fromJson(Map<String, dynamic> json) {
    return CategoryImage(
      id: json['id'] as String,
      categoryKey: json['category_key'] as String,
      categoryName: json['category_name'] as String,
      imageUrl: json['image_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_key': categoryKey,
      'category_name': categoryName,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

