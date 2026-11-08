-- ============================================
-- PROFİL RESMİ İÇİN AVATAR_URL SÜTUNU EKLEME
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- user_profiles tablosuna avatar_url sütunu ekle
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- ============================================
-- STORAGE BUCKET OLUŞTURMA
-- ============================================
-- Supabase Dashboard > Storage > Create bucket
-- 
-- Bucket Ayarları:
-- - Name: profile-images
-- - Public bucket: ✅ Evet (profil resimleri herkese açık olabilir)
-- - File size limit: 2 MB
-- - Allowed MIME types: image/jpeg, image/png, image/webp
-- ============================================

