-- ============================================
-- user_goals tablosuna workout_days ve program_weeks ekle
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- Hangi günler antrenman yapılacak (JSONB array: [1,3,5] = Pzt, Çar, Cum)
ALTER TABLE public.user_goals
ADD COLUMN IF NOT EXISTS workout_days JSONB DEFAULT '[]'::jsonb;

-- Program kaç hafta sürecek
ALTER TABLE public.user_goals
ADD COLUMN IF NOT EXISTS program_weeks INTEGER DEFAULT 6 CHECK (program_weeks BETWEEN 1 AND 52);
