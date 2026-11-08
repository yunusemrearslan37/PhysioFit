import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class StorageService {
  final _supabase = SupabaseConfig.client;

  // Ekipman görseli yükle
  Future<String> uploadEquipmentImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from('equipment-images')
          .upload(filePath, imageFile);

      final publicUrl = _supabase.storage
          .from('equipment-images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Görsel yükleme hatası: $e');
    }
  }

  // Egzersiz animasyonu yükle
  Future<String> uploadExerciseAnimation({
    required String exerciseId,
    required File animationFile,
  }) async {
    try {
      final fileName = 'animation.json';
      final filePath = '$exerciseId/$fileName';

      await _supabase.storage
          .from('exercise-animations')
          .upload(filePath, animationFile);

      final publicUrl = _supabase.storage
          .from('exercise-animations')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Animasyon yükleme hatası: $e');
    }
  }

  // Kullanıcı dosyası yükle
  Future<String> uploadUserFile({
    required String userId,
    required File file,
    required String fileName,
  }) async {
    try {
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from('user-uploads')
          .upload(filePath, file);

      final publicUrl = _supabase.storage
          .from('user-uploads')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Dosya yükleme hatası: $e');
    }
  }

  // Profil resmi yükle
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';

      // Eski profil resmini sil (varsa)
      try {
        // Klasör yoksa veya boşsa hata vermemesi için kontrol et
        final existingFiles = await _supabase.storage
            .from('profile-images')
            .list(path: userId);
        
        if (existingFiles.isNotEmpty) {
          for (var file in existingFiles) {
            if (file.name.startsWith('profile_')) {
              try {
                await _supabase.storage
                    .from('profile-images')
                    .remove(['$userId/${file.name}']);
              } catch (removeError) {
                // Silme hatası kritik değil, devam et
                debugPrint('Eski profil resmi silinirken hata: $removeError');
              }
            }
          }
        }
      } catch (e) {
        // Klasör yoksa veya list hatası varsa devam et (yeni kullanıcı olabilir)
        debugPrint('Eski profil resmi kontrol edilirken hata (normal olabilir): $e');
      }

      // Yeni resmi yükle
      try {
        await _supabase.storage
            .from('profile-images')
            .upload(filePath, imageFile, fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ));
      } catch (uploadError) {
        debugPrint('Upload hatası detayı: $uploadError');
        // Daha açıklayıcı hata mesajı
        if (uploadError.toString().contains('Bucket not found')) {
          throw Exception('Profil resmi depolama alanı bulunamadı. Lütfen yöneticiye başvurun.');
        } else if (uploadError.toString().contains('new row violates row-level security')) {
          throw Exception('Profil resmi yükleme izni yok. Lütfen yöneticiye başvurun.');
        } else if (uploadError.toString().contains('File size')) {
          throw Exception('Resim çok büyük. Lütfen daha küçük bir resim seçin (max 2MB).');
        } else {
          throw Exception('Profil resmi yüklenirken hata oluştu: ${uploadError.toString()}');
        }
      }

      final publicUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      // Zaten formatlanmış hata mesajı varsa direkt fırlat
      if (e.toString().contains('Profil resmi')) {
        rethrow;
      }
      throw Exception('Profil resmi yükleme hatası: $e');
    }
  }

  // Dosya sil
  Future<void> deleteFile({
    required String bucket,
    required String filePath,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([filePath]);
    } catch (e) {
      throw Exception('Dosya silme hatası: $e');
    }
  }

  // Kategori isimlerini klasör isimlerine çevir
  static String _getCategoryFolder(String category) {
    final categoryLower = category.toLowerCase();
    switch (categoryLower) {
      case 'chest':
        return 'chest';
      case 'back':
        return 'back';
      case 'legs':
        return 'leg';
      case 'shoulders':
        return 'shoulder';
      case 'arms':
        return 'arm';
      case 'core':
        return 'core';
      default:
        return categoryLower;
    }
  }

  // Manuel video yolu mapping'i - Özel durumlar için
  // Egzersiz adı -> Asset path
  static final Map<String, String> _manualVideoPaths = {
    // Chest
    'Bench Press': 'assets/videos/chest/Bench_Press.mp4',
    'Push-up (Şınav)': 'assets/videos/chest/Push_Up.mp4',
    'Incline Push-up': 'assets/videos/chest/Incline_Push_Up.mp4',
    'Dumbbell Chest Press': 'assets/videos/chest/Dumbbell_Chest_Press.mp4',
    'Dumbbell Flyes': 'assets/videos/chest/Dumbbel_Flyes.mp4',
    'Decline Bench Press': 'assets/videos/chest/Decline_Bench_Press.mp4',
    'Cable Crossover': 'assets/videos/chest/Cable_Crossover.mp4',
    'Dips': 'assets/videos/chest/Dips.mp4',
    'Weighted Dips': 'assets/videos/chest/Dips.mp4',
    'Incline Dumbbell Press': 'assets/videos/chest/Incline_Dumbell_Press.mp4',
    'Assisted Tricep Dips': 'assets/videos/chest/assisted_tricep_dips.mp4',
    'Chest Press Machine': 'assets/videos/chest/chest_press_machine.mp4',
  
    // Back
    'Assisted Pull-up': 'assets/videos/back/Assisted_Pull_Up.mp4',
    'Dumbbell Row': 'assets/videos/back/Dumbell_Row.mp4',
    'Lat Pulldown': 'assets/videos/back/Lat_Pulldown.mp4',
    'Pull-up': 'assets/videos/back/Pull_Up.mp4',
    'Barbell Row': 'assets/videos/back/Barbell_Row.mp4',
    'T-Bar Row': 'assets/videos/back/T_Bar_Row.mp4',
    'Weighted Pull-up': 'assets/videos/back/Pull_Up.mp4',
    'One-Arm Dumbbell Row': 'assets/videos/back/One_Arm_Dumbbell_Row.mp4',
    'Cable Row': 'assets/videos/back/Cable_Row.mp4',
    'Upright Row': 'assets/videos/back/Upright_Row.mp4',

    // Shoulders
    'Arnold Press': 'assets/videos/shoulder/Arnold_Press.mp4',
    'Barbell Shoulder Press': 'assets/videos/shoulder/Barbell_Shoulder_Press.mp4',
    'Dumbbell Press': 'assets/videos/shoulder/Dumbell_Press.mp4',
    'Dumbbell Shoulder Press': 'assets/videos/shoulder/Dumbell_Shoulder_Press.mp4',
    'Face Pull': 'assets/videos/shoulder/Face_Pull.mp4',
    'Front Raises': 'assets/videos/shoulder/Front_Raises.mp4',
    'Lateral Raises': 'assets/videos/shoulder/Lateral_Raises.mp4',
    'Overhead Press': 'assets/videos/shoulder/Overherad_Press.mp4',
    'Lateral Raise Machine': 'assets/videos/shoulder/lateral_raises_machine.mp4',
    'Pike Push-up': 'assets/videos/shoulder/pike_push_up.mp4',
    // Arms
    'Barbell Bicep Curl': 'assets/videos/arm/barbell_bicep_curl.mp4',
    'Cable Bicep Curl': 'assets/videos/arm/cable_bicep_curl.mp4',
    'Cable Tricep Extension': 'assets/videos/arm/cable_tricep_extension.mp4',
    'Dumbbell Bicep Curl': 'assets/videos/arm/dumbell_bicep_curl.mp4',
    'Hammer Curl': 'assets/videos/arm/hammer_curl.mp4',
    'Preacher Curl': 'assets/videos/arm/preacher_curl.mp4',
    'Arm Curl Machine': 'assets/videos/arm/arm_curl.mp4',
    'Close-Grip Bench Press': 'assets/videos/arm/close_grip_benchpress.mp4',
    'Tricep Dips (Assisted)': 'assets/videos/arm/assisted_dips.mp4',
    
    // Legs
    'Barbell Squat': 'assets/videos/leg/Barbell_Squat.mp4',
    'Bodyweight Squat': 'assets/videos/leg/Bodyweight_Squat.mp4',
    'Bulgarian Split Squat': 'assets/videos/leg/Bulgarian_Split_Squat.mp4',
    'Front Squat': 'assets/videos/leg/Front_Squat.mp4',
    'Hack Squat': 'assets/videos/leg/Hack_Squat.mp4',
    'Leg Press': 'assets/videos/leg/Leg_Press.mp4',
    'Lunges': 'assets/videos/leg/Lunges.mp4',
    'Romanian Deadlift': 'assets/videos/leg/Romanian_Deadlift.mp4',
    'Walking Lunges': 'assets/videos/leg/Walking_Lunges.mp4',
    'Leg Extension': 'assets/videos/leg/leg_extension.mp4',
    'Leg Curl Machine': 'assets/videos/leg/leg_curl.mp4',
    // Core
    'Crunches': 'assets/videos/core/crunches.mp4',
    'Dead Bug': 'assets/videos/core/dead_bug.mp4',
    'Dragon Flag': 'assets/videos/core/dragon_flag.mp4',
    'Leg Raise': 'assets/videos/core/leg_Raise.mp4',
    'Leg Raises': 'assets/videos/core/leg_Raise.mp4', // Çoğul versiyonu
    'Hanging Leg Raises': 'assets/videos/core/leg_Raise.mp4', // Asılı versiyonu
    'Plank': 'assets/videos/core/plank.mp4',
    'Russian Twist': 'assets/videos/core/russian_twist.mp4',
    'Russian Twists': 'assets/videos/core/russian_twist.mp4', // Çoğul versiyonu
    'Mountain Climbers': 'assets/videos/core/mountain_climbers.mp4',
    'Ab Wheel Rollout': 'assets/videos/core/ab_wheel.mp4',
    // Push-up varyasyonları
    'Push-up': 'assets/videos/chest/Push_Up.mp4', // Tire olmadan
    'Push up': 'assets/videos/chest/Push_Up.mp4', // Boşluklu
  };

  // Egzersiz animasyonu asset path'ini al (assets klasöründen)
  // Önce manuel mapping'e bakar, yoksa otomatik oluşturur
  String? getExerciseAnimationAssetPath({
    String? exerciseName,
    String? category,
  }) {
    if (exerciseName == null || category == null) {
      return null;
    }
    
    try {
      // Önce manuel mapping'e bak
      if (_manualVideoPaths.containsKey(exerciseName)) {
        final manualPath = _manualVideoPaths[exerciseName];
        debugPrint('Manuel yol bulundu: $exerciseName -> $manualPath');
        return manualPath;
      }
      
      // Manuel mapping yoksa otomatik oluştur
      final categoryFolder = _getCategoryFolder(category);
      final exerciseFileName = _convertExerciseNameToFileName(exerciseName);
      
      // Olası dosya yollarını dene (kategori klasörü ile)
      final possiblePaths = [
        'assets/videos/$categoryFolder/$exerciseFileName.mp4',
        'assets/videos/$categoryFolder/${exerciseFileName.toLowerCase()}.mp4',
        'assets/videos/$categoryFolder/${_convertToSnakeCase(exerciseName)}.mp4',
        'assets/videos/$categoryFolder/${_convertToSnakeCase(exerciseName).toLowerCase()}.mp4',
      ];
      
      // İlk path'i döndür (en olası format)
      final selectedPath = possiblePaths.first;
      debugPrint('Egzersiz: $exerciseName, Kategori: $category');
      debugPrint('Kategori klasörü: $categoryFolder');
      debugPrint('Oluşturulan dosya adı: $exerciseFileName');
      debugPrint('Seçilen asset path: $selectedPath');
      return selectedPath;
    } catch (e) {
      debugPrint('Egzersiz animasyon asset path alınırken hata: $e');
      return null;
    }
  }
  
  // İsimi snake_case formatına çevir (Pull-up -> Pull_Up)
  String _convertToSnakeCase(String name) {
    return name
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll("'", '');
  }

  // Egzersiz adını dosya adı formatına çevir
  // "Dumbbell Shoulder Press" -> "Dumbell_Press"
  // "Push-up (Şınav)" -> "Push_Up"
  // "Pull-up" -> "Pull_Up"
  // "Leg Raises" -> "leg_Raise"
  // "Russian Twists" -> "russian_twist"
  String _convertExerciseNameToFileName(String exerciseName) {
    var name = exerciseName;
    
    // Özel durumlar - dosya adında "Dumbell" (tek 'b') kullanılıyor
    name = name.replaceAll('Dumbbell', 'Dumbell');
    
    // Özel durumlar - "One-Arm" -> "One_Arm"
    name = name.replaceAll('One-Arm', 'One_Arm');
    name = name.replaceAll('One Arm', 'One_Arm');
    
    // Çoğul/tekil dönüşümleri - dosya adları genelde tekil
    name = name.replaceAll('Raises', 'Raise'); // "Leg Raises" -> "Leg Raise"
    name = name.replaceAll('Twists', 'Twist'); // "Russian Twists" -> "Russian Twist"
    name = name.replaceAll('Climbers', 'Climber'); // "Mountain Climbers" -> "Mountain Climber"
    
    // "Hanging" kelimesini kaldır (dosya adında yok)
    name = name.replaceAll('Hanging ', '');
    name = name.replaceAll('Hanging_', '');
    
    // Boşlukları, tire'leri ve özel karakterleri temizle
    name = name
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll("'", '')
        .replaceAll('Şınav', ''); // Türkçe karakterleri kaldır
    
    // Fazla alt çizgileri temizle
    name = name.replaceAll('__', '_');
    name = name.replaceAll('__', '_'); // İkinci kez kontrol et
    
    // Başta ve sonda alt çizgi varsa kaldır
    if (name.startsWith('_')) {
      name = name.substring(1);
    }
    if (name.endsWith('_')) {
      name = name.substring(0, name.length - 1);
    }
    
    return name;
  }

  // Bucket'tan egzersiz animasyon dosyalarını listele
  Future<List<String>> listExerciseAnimationFiles(String exerciseId) async {
    try {
      final files = await _supabase.storage
          .from('exercise-animations')
          .list(path: exerciseId);
      
      // MP4 dosyalarını filtrele
      return files
          .where((file) => file.name.toLowerCase().endsWith('.mp4'))
          .map((file) => '$exerciseId/${file.name}')
          .toList();
    } catch (e) {
      debugPrint('Egzersiz animasyon dosyaları listelenirken hata: $e');
      return [];
    }
  }

  // Bucket'tan egzersiz animasyon URL'ini al (en uygun dosyayı bul)
  Future<String?> getExerciseAnimationUrlFromBucket(String exerciseId) async {
    try {
      // Önce dosyaları listele
      final files = await listExerciseAnimationFiles(exerciseId);
      
      if (files.isEmpty) {
        return null;
      }
      
      // İlk MP4 dosyasını al (veya öncelik sırasına göre)
      final filePath = files.first;
      final url = _supabase.storage
          .from('exercise-animations')
          .getPublicUrl(filePath);
      
      return url;
    } catch (e) {
      debugPrint('Egzersiz animasyon URL bucket\'tan alınırken hata: $e');
      return null;
    }
  }
}

