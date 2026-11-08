-- ============================================
-- SUPABASE STORAGE RLS POLİTİKALARI
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- ============================================
-- PROFILE-IMAGES BUCKET POLİTİKALARI
-- ============================================

-- 1. Authenticated kullanıcılar kendi klasörlerine dosya yükleyebilir
CREATE POLICY "Kullanıcılar kendi profil resimlerini yükleyebilir"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. Authenticated kullanıcılar kendi klasörlerindeki dosyaları güncelleyebilir
CREATE POLICY "Kullanıcılar kendi profil resimlerini güncelleyebilir"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Authenticated kullanıcılar kendi klasörlerindeki dosyaları silebilir
CREATE POLICY "Kullanıcılar kendi profil resimlerini silebilir"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Herkes profil resimlerini okuyabilir (public bucket için)
CREATE POLICY "Herkes profil resimlerini okuyabilir"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- ============================================
-- EXERCISE-IMAGES BUCKET POLİTİKALARI
-- ============================================

-- Herkes egzersiz görsellerini okuyabilir
CREATE POLICY "Herkes egzersiz görsellerini okuyabilir"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'exercise-images');

-- ============================================
-- EQUIPMENT-IMAGES BUCKET POLİTİKALARI
-- ============================================

-- Herkes ekipman görsellerini okuyabilir
CREATE POLICY "Herkes ekipman görsellerini okuyabilir"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'equipment-images');

-- ============================================
-- USER-UPLOADS BUCKET POLİTİKALARI
-- ============================================

-- Authenticated kullanıcılar kendi klasörlerine dosya yükleyebilir
CREATE POLICY "Kullanıcılar kendi dosyalarını yükleyebilir"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-uploads' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Authenticated kullanıcılar kendi klasörlerindeki dosyaları okuyabilir
CREATE POLICY "Kullanıcılar kendi dosyalarını okuyabilir"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-uploads' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Authenticated kullanıcılar kendi klasörlerindeki dosyaları silebilir
CREATE POLICY "Kullanıcılar kendi dosyalarını silebilir"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-uploads' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- EXERCISE-ANIMATIONS BUCKET POLİTİKALARI
-- ============================================

-- Herkes egzersiz animasyonlarını okuyabilir
CREATE POLICY "Herkes egzersiz animasyonlarını okuyabilir"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'exercise-animations');

-- ============================================
-- NOT: Eğer policy zaten varsa hata alırsanız,
-- önce mevcut policy'leri silin:
-- ============================================
-- DROP POLICY IF EXISTS "Kullanıcılar kendi profil resimlerini yükleyebilir" ON storage.objects;
-- DROP POLICY IF EXISTS "Kullanıcılar kendi profil resimlerini güncelleyebilir" ON storage.objects;
-- DROP POLICY IF EXISTS "Kullanıcılar kendi profil resimlerini silebilir" ON storage.objects;
-- DROP POLICY IF EXISTS "Herkes profil resimlerini okuyabilir" ON storage.objects;
-- ============================================

