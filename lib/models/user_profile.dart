import '../utils/gender_helper.dart';
import '../utils/age_calculator.dart';

class UserProfile {
  final String id;
  final String email;
  final String? name;
  final DateTime? birthDate;
  final String? gender;
  final String? avatarUrl;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.birthDate,
    this.gender,
    this.avatarUrl,
    this.onboardingCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Yaş hesaplanmış property
  int? get age {
    if (birthDate == null) return null;
    return AgeCalculator.calculateAge(birthDate!);
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Veritabanından gelen İngilizce gender değerini Türkçe'ye çevir
    final englishGender = json['gender'] as String?;
    final birthDateStr = json['birth_date'] as String?;
    
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      birthDate: birthDateStr != null ? DateTime.parse(birthDateStr) : null,
      gender: GenderHelper.toTurkish(englishGender),
      avatarUrl: json['avatar_url'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'avatar_url': avatarUrl,
      'onboarding_completed': onboardingCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

