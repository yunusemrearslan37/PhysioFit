# Kategori Görselleri - Supabase Storage Kurulum Rehberi

## 📋 Adımlar

### 1. Veritabanı Tablosunu Oluşturma

1. Supabase Dashboard → **SQL Editor**
2. `database/add_category_images.sql` dosyasını açın
3. İçeriği kopyalayıp SQL Editor'e yapıştırın
4. **Run** butonuna tıklayın

### 2. Storage Bucket Oluşturma

1. Supabase Dashboard → **Storage**
2. **Create bucket** butonuna tıklayın
3. Ayarlar:
   - **Name**: `exercise-images`
   - **Public bucket**: ✅ Evet
   - **File size limit**: 5 MB
   - **Allowed MIME types**: `image/jpeg, image/png, image/webp`

### 3. Klasör Yapısı Oluşturma

Storage bucket içinde şu klasör yapısını oluşturun:

```
exercise-images/
  └── categories/
      ├── chest.jpg (veya .png)
      ├── back.jpg
      ├── legs.jpg
      ├── arms.jpg
      ├── shoulders.jpg
      ├── core.jpg
      └── cardio.jpg
```

### 4. Görselleri Yükleme

Her kategori için görsel yükleyin:

1. **Storage** → **exercise-images** bucket'ına gidin
2. **Upload file** butonuna tıklayın
3. Görseli seçin
4. **Upload to folder**: `categories/` klasörüne yükleyin
5. Dosya adını kategori key'i ile eşleştirin:
   - `chest.jpg` → Chest kategorisi
   - `back.jpg` → Back kategorisi
   - `legs.jpg` → Legs kategorisi
   - `arms.jpg` → Arms kategorisi
   - `shoulders.jpg` → Shoulders kategorisi
   - `core.jpg` → Core kategorisi
   - `cardio.jpg` → Cardio kategorisi

### 5. Public URL'leri Alma

Her görsel için public URL'i alın:

1. Görsele tıklayın
2. **Copy URL** butonuna tıklayın
3. URL formatı şöyle olacak:
   ```
   https://YOUR_PROJECT.supabase.co/storage/v1/object/public/exercise-images/categories/chest.jpg
   ```

### 6. Veritabanına URL'leri Ekleme

1. Supabase Dashboard → **SQL Editor**
2. Şu SQL'i çalıştırın (URL'leri kendi URL'lerinizle değiştirin):

```sql
UPDATE public.category_images 
SET image_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/exercise-images/categories/chest.jpg'
WHERE category_key = 'Chest';

UPDATE public.category_images 
SET image_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/exercise-images/categories/back.jpg'
WHERE category_key = 'Back';

UPDATE public.category_images 
SET image_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/exercise-images/categories/legs.jpg'
WHERE category_key = 'Legs';

UPDATE public.category_images 
SET image_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/exercise-images/categories/arms.jpg'
WHERE category_key = 'Arms';

UPDATE public.category_images 
SET image_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/exercise-images/categories/shoulders.jpg'
WHERE category_key = 'Shoulders';

UPDATE public.category_images 
SET image_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/exercise-images/categories/core.jpg'
WHERE category_key = 'Core';

UPDATE public.category_images 
SET image_url = 'https://YOUR_PROJECT.supabase.co/storage/v1/object/public/exercise-images/categories/cardio.jpg'
WHERE category_key = 'Cardio';
```

### 7. Test Etme

1. Uygulamayı yeniden başlatın
2. Egzersizler ekranına gidin
3. Kategori kartlarında görseller görünmeli

## 🎨 Görsel Önerileri

- **Format**: JPG veya PNG
- **Boyut**: 800x600 px (veya benzer oran)
- **Dosya boyutu**: 200-500 KB arası (optimize edilmiş)
- **İçerik**: Her kategori için uygun egzersiz görseli

## 🔧 Sorun Giderme

### Görseller görünmüyor
- URL'lerin doğru olduğundan emin olun
- Bucket'ın public olduğunu kontrol edin
- Uygulamayı yeniden başlatın

### Hata: "Failed to load image"
- URL formatını kontrol edin
- Görselin gerçekten yüklendiğinden emin olun
- Storage bucket izinlerini kontrol edin

### Görseller yavaş yükleniyor
- Görselleri optimize edin (sıkıştırın)
- `cached_network_image` paketi otomatik cache yapar

## 📝 Notlar

- Görseller otomatik olarak cache'lenir
- İnternet bağlantısı gereklidir (ilk yükleme için)
- Görsel yoksa placeholder ikon gösterilir

