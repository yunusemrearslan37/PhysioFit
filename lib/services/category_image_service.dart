import '../config/supabase_config.dart';
import '../models/category_image.dart';

class CategoryImageService {
  final _supabase = SupabaseConfig.client;

  // Tüm kategori görsellerini getir
  Future<List<CategoryImage>> getAllCategoryImages() async {
    try {
      final response = await _supabase
          .from('category_images')
          .select()
          .order('category_name');

      return (response as List)
          .map((json) => CategoryImage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Kategori görselleri getirme hatası: $e');
    }
  }

  // Kategori key'e göre görsel getir
  Future<CategoryImage?> getCategoryImageByKey(String categoryKey) async {
    try {
      final response = await _supabase
          .from('category_images')
          .select()
          .eq('category_key', categoryKey)
          .single();

      return CategoryImage.fromJson(response);
    } catch (e) {
      return null; // Görsel bulunamazsa null döner
    }
  }

  // Kategori görsellerini map olarak getir (key -> imageUrl)
  Future<Map<String, String>> getCategoryImagesMap() async {
    try {
      final images = await getAllCategoryImages();
      final map = <String, String>{};
      
      for (var image in images) {
        map[image.categoryKey] = image.imageUrl;
      }
      
      return map;
    } catch (e) {
      return {};
    }
  }
}

