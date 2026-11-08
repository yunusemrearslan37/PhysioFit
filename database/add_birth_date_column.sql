-- ============================================
-- DOĞUM TARİHİ İÇİN BIRTH_DATE SÜTUNU EKLEME
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- user_profiles tablosuna birth_date sütunu ekle
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS birth_date DATE;

-- Eğer age sütunu varsa ve kaldırmak istiyorsanız (opsiyonel):
-- ALTER TABLE public.user_profiles DROP COLUMN IF EXISTS age;

-- ============================================
-- NOT: Yaş artık doğum tarihinden otomatik hesaplanacak
-- ============================================

