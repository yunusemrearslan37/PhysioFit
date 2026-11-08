-- ============================================
-- USER_PROFILES RLS POLİTİKASI DÜZELTMESİ
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- Tüm mevcut politikaları sil
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

-- Yeni politikaları oluştur

-- 1. SELECT (Okuma) - Kullanıcılar kendi profillerini görebilir
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT 
  TO authenticated
  USING (auth.uid() = id);

-- 2. UPDATE (Güncelleme) - Kullanıcılar kendi profillerini güncelleyebilir
CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE 
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 3. INSERT (Ekleme) - Kullanıcılar kendi profillerini oluşturabilir
-- ÖNEMLİ: Kayıt sırasında kullanıcı authenticated olduğu için
-- auth.uid() kontrolü yapılabilir
CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = id
  );

-- Politikaları kontrol et
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

