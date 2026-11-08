-- ============================================
-- OTOMATİK PROFİL OLUŞTURMA TRIGGER'ı
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- Bu trigger, yeni kullanıcı kaydı olduğunda otomatik olarak profil oluşturur
-- ============================================

-- Önce mevcut trigger'ı sil (varsa)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Trigger fonksiyonu oluştur
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Yeni kullanıcı için profil oluştur
  -- NOT: Bu fonksiyon auth.users tablosunda çalıştığı için
  -- RLS politikası bypass edilir (service_role kullanır)
  INSERT INTO public.user_profiles (
    id, 
    email, 
    name, 
    birth_date,
    gender,
    created_at, 
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    CASE 
      WHEN NEW.raw_user_meta_data->>'birth_date' IS NOT NULL 
      THEN (NEW.raw_user_meta_data->>'birth_date')::date
      ELSE NULL
    END,
    CASE 
      WHEN NEW.raw_user_meta_data->>'gender' IS NOT NULL 
      THEN NEW.raw_user_meta_data->>'gender'
      ELSE NULL
    END,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = COALESCE(EXCLUDED.name, user_profiles.name),
    birth_date = COALESCE(EXCLUDED.birth_date, user_profiles.birth_date),
    gender = COALESCE(EXCLUDED.gender, user_profiles.gender),
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger oluştur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- NOT: Bu trigger çalıştıktan sonra,
-- AuthService'deki manuel insert işlemini
-- kaldırabilir veya sadece güncelleme yapabilirsiniz
-- ============================================

