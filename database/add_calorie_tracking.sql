-- ============================================
-- KALORİ TAKİBİ
-- Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- 1) Egzersizlere MET değeri (kardiyo kalori hesabı için)
ALTER TABLE public.exercises
ADD COLUMN IF NOT EXISTS met_value DECIMAL(4,1);

-- Kardiyo egzersizlerine MET değerleri
UPDATE public.exercises SET met_value = 3.5
WHERE lower(name) = lower('Yürüyüş') AND category = 'Cardio';

UPDATE public.exercises SET met_value = 8.0
WHERE lower(name) = lower('Jumping Jacks') AND category = 'Cardio';

UPDATE public.exercises SET met_value = 6.0
WHERE lower(name) = lower('Stationary Bike') AND category = 'Cardio';

UPDATE public.exercises SET met_value = 9.8
WHERE lower(name) = lower('Koşu') AND category = 'Cardio';

UPDATE public.exercises SET met_value = 8.0
WHERE lower(name) = lower('Burpees') AND category = 'Cardio';

UPDATE public.exercises SET met_value = 8.0
WHERE lower(name) = lower('High Knees') AND category = 'Cardio';

UPDATE public.exercises SET met_value = 11.0
WHERE lower(name) = lower('Sprint Intervals') AND category = 'Cardio';

UPDATE public.exercises SET met_value = 8.0
WHERE lower(name) = lower('Box Jumps') AND category = 'Cardio';

UPDATE public.exercises SET met_value = 7.0
WHERE lower(name) = lower('Rowing Machine') AND category = 'Cardio';

-- Kuvvet egzersizleri için varsayılan MET (tahmini)
UPDATE public.exercises SET met_value = 4.0
WHERE category IS NOT NULL
  AND lower(category) != 'cardio'
  AND met_value IS NULL;

-- 2) Günlük beslenme kaydı (manuel kalori girişi)
CREATE TABLE IF NOT EXISTS public.daily_nutrition (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  calories_consumed INTEGER NOT NULL DEFAULT 0 CHECK (calories_consumed >= 0),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_nutrition_user_date
  ON public.daily_nutrition(user_id, date DESC);

ALTER TABLE public.daily_nutrition ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own nutrition" ON public.daily_nutrition;
DROP POLICY IF EXISTS "Users can insert own nutrition" ON public.daily_nutrition;
DROP POLICY IF EXISTS "Users can update own nutrition" ON public.daily_nutrition;
DROP POLICY IF EXISTS "Users can delete own nutrition" ON public.daily_nutrition;

CREATE POLICY "Users can view own nutrition" ON public.daily_nutrition
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own nutrition" ON public.daily_nutrition
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own nutrition" ON public.daily_nutrition
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own nutrition" ON public.daily_nutrition
  FOR DELETE TO authenticated USING (auth.uid() = user_id);
