-- ============================================
-- SUPABASE VERİTABANI ŞEMASI
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- UUID extension'ı etkinleştir
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLOLAR
-- ============================================

-- Users tablosu (Supabase Auth ile otomatik oluşur, ekstra alanlar için)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  age INTEGER,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Injuries (Sakatlık) tablosu
CREATE TABLE IF NOT EXISTS public.injuries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  injury_type TEXT NOT NULL,
  body_part TEXT,
  severity TEXT CHECK (severity IN ('low', 'medium', 'high')),
  date DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exercises (Egzersizler) tablosu
CREATE TABLE IF NOT EXISTS public.exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  equipment_type TEXT,
  -- Program/egzersiz listelerinde görünmesin (sadece ekipman tanıma vb. için)
  is_hidden BOOLEAN NOT NULL DEFAULT false,
  animation_url TEXT,
  video_url TEXT,
  muscle_groups JSONB, -- ["chest", "triceps", "shoulders"]
  instructions JSONB, -- ["Adım 1", "Adım 2"]
  difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exercise History (Egzersiz Geçmişi) tablosu
CREATE TABLE IF NOT EXISTS public.exercise_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  sets INTEGER,
  reps INTEGER,
  weight DECIMAL(5,2),
  duration INTEGER, -- saniye cinsinden
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recommendations (Öneriler) tablosu
CREATE TABLE IF NOT EXISTS public.recommendations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
  reason TEXT,
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Equipment Classifications (Ekipman Sınıflandırmaları) tablosu
CREATE TABLE IF NOT EXISTS public.equipment_classifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  equipment_type TEXT NOT NULL,
  confidence DECIMAL(3,2), -- 0.00 - 1.00
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Analytics (Kullanıcı Analitikleri) tablosu
CREATE TABLE IF NOT EXISTS public.user_analytics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_workouts INTEGER DEFAULT 0,
  total_duration INTEGER DEFAULT 0, -- saniye
  calories_burned INTEGER DEFAULT 0,
  exercises_completed JSONB, -- ["squat", "bench_press"]
  weekly_progress JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Workouts (Kullanıcı Antrenman Programları) tablosu
CREATE TABLE IF NOT EXISTS public.workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  exercises JSONB NOT NULL, -- [{"exercise_id": "...", "exercise_name": "...", "sets": 3, "reps": 10, "weight": null, "rest_seconds": 60, "notes": null}]
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workouts tablosuna yeni sütunlar ekle (eğer yoksa)
ALTER TABLE public.workouts 
ADD COLUMN IF NOT EXISTS weeks INTEGER DEFAULT 4;

ALTER TABLE public.workouts 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT false;

-- Workout Progress (Günlük Antrenman Takibi) tablosu
CREATE TABLE IF NOT EXISTS public.workout_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  workout_id UUID NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
  date DATE NOT NULL, -- Hangi gün yapıldı
  completed BOOLEAN DEFAULT false, -- O gün antrenman yapıldı mı
  notes TEXT, -- O gün için notlar
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, workout_id, date) -- Aynı gün için tek kayıt
);

-- Injury Assessments (Sakatlık Analizleri) tablosu
CREATE TABLE IF NOT EXISTS public.injury_assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  body_part TEXT NOT NULL, -- 'diz', 'omuz', 'bel', vb.
  pain_type TEXT NOT NULL, -- 'keskin', 'yanma', 'batma', vb.
  triggering_movements JSONB, -- ["squat", "koşu"]
  functionality_test JSONB, -- {"range_of_motion": "kısıtlı", "strength": "zayıf", "stability": "dengesiz"}
  risk_factors JSONB, -- ["geçmiş sakatlık", "aşırı antrenman"]
  severity_score INTEGER NOT NULL, -- 0-100 arası
  recommended_injury_type TEXT, -- Analiz sonucu önerilen sakatlık tipi
  recommended_exercise_ids JSONB, -- ["uuid1", "uuid2"]
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Strength Records (Güç Takip Kayıtları) tablosu
CREATE TABLE IF NOT EXISTS public.strength_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  exercise_type TEXT NOT NULL, -- 'bench_press', 'overhead_press', 'squat', 'deadlift'
  weight DECIMAL(5,2) NOT NULL, -- kg cinsinden (PR - Personal Record)
  date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mevcut tabloda varsa reps, sets ve notes sütunlarını kaldır
ALTER TABLE public.strength_records DROP COLUMN IF EXISTS reps;
ALTER TABLE public.strength_records DROP COLUMN IF EXISTS sets;
ALTER TABLE public.strength_records DROP COLUMN IF EXISTS notes;

-- ============================================
-- INDEX'LER (Performans için)
-- ============================================

CREATE INDEX IF NOT EXISTS idx_injuries_user_id ON public.injuries(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_history_user_id ON public.exercise_history(user_id);
CREATE INDEX IF NOT EXISTS idx_exercise_history_date ON public.exercise_history(date);
CREATE INDEX IF NOT EXISTS idx_exercise_history_user_date ON public.exercise_history(user_id, date);
CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON public.recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_equipment_classifications_user_id ON public.equipment_classifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_analytics_user_date ON public.user_analytics(user_id, date);
CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON public.workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workouts_is_active ON public.workouts(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_workout_progress_user_workout ON public.workout_progress(user_id, workout_id);
CREATE INDEX IF NOT EXISTS idx_workout_progress_date ON public.workout_progress(date);
CREATE INDEX IF NOT EXISTS idx_workout_progress_user_date ON public.workout_progress(user_id, date);
CREATE INDEX IF NOT EXISTS idx_injury_assessments_user_id ON public.injury_assessments(user_id);
CREATE INDEX IF NOT EXISTS idx_injury_assessments_created_at ON public.injury_assessments(created_at);
CREATE INDEX IF NOT EXISTS idx_strength_records_user_id ON public.strength_records(user_id);
CREATE INDEX IF NOT EXISTS idx_strength_records_exercise_type ON public.strength_records(exercise_type);
CREATE INDEX IF NOT EXISTS idx_strength_records_date ON public.strength_records(date);
CREATE INDEX IF NOT EXISTS idx_strength_records_user_exercise_date ON public.strength_records(user_id, exercise_type, date);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLİTİKALARI
-- ============================================

-- RLS'yi etkinleştir
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.injuries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_classifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.injury_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strength_records ENABLE ROW LEVEL SECURITY;

-- Egzersiz kataloğu herkese açık okunur. Yazma politikası yok;
-- ekleme ve silme yalnızca service role ile yapılır.
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

-- Mevcut politikaları sil (eğer varsa)
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

DROP POLICY IF EXISTS "Users can view own injuries" ON public.injuries;
DROP POLICY IF EXISTS "Users can insert own injuries" ON public.injuries;
DROP POLICY IF EXISTS "Users can update own injuries" ON public.injuries;
DROP POLICY IF EXISTS "Users can delete own injuries" ON public.injuries;

DROP POLICY IF EXISTS "Exercises are viewable by everyone" ON public.exercises;

DROP POLICY IF EXISTS "Users can view own exercise history" ON public.exercise_history;
DROP POLICY IF EXISTS "Users can insert own exercise history" ON public.exercise_history;
DROP POLICY IF EXISTS "Users can update own exercise history" ON public.exercise_history;
DROP POLICY IF EXISTS "Users can delete own exercise history" ON public.exercise_history;

DROP POLICY IF EXISTS "Users can view own recommendations" ON public.recommendations;
DROP POLICY IF EXISTS "Users can insert own recommendations" ON public.recommendations;

DROP POLICY IF EXISTS "Users can view own equipment classifications" ON public.equipment_classifications;
DROP POLICY IF EXISTS "Users can insert own equipment classifications" ON public.equipment_classifications;

DROP POLICY IF EXISTS "Users can view own analytics" ON public.user_analytics;
DROP POLICY IF EXISTS "Users can insert own analytics" ON public.user_analytics;
DROP POLICY IF EXISTS "Users can update own analytics" ON public.user_analytics;

DROP POLICY IF EXISTS "Users can view own workouts" ON public.workouts;
DROP POLICY IF EXISTS "Users can insert own workouts" ON public.workouts;
DROP POLICY IF EXISTS "Users can update own workouts" ON public.workouts;
DROP POLICY IF EXISTS "Users can delete own workouts" ON public.workouts;

DROP POLICY IF EXISTS "Users can view own workout progress" ON public.workout_progress;
DROP POLICY IF EXISTS "Users can insert own workout progress" ON public.workout_progress;
DROP POLICY IF EXISTS "Users can update own workout progress" ON public.workout_progress;
DROP POLICY IF EXISTS "Users can delete own workout progress" ON public.workout_progress;

DROP POLICY IF EXISTS "Users can view own injury assessments" ON public.injury_assessments;
DROP POLICY IF EXISTS "Users can insert own injury assessments" ON public.injury_assessments;

DROP POLICY IF EXISTS "Users can view own strength records" ON public.strength_records;
DROP POLICY IF EXISTS "Users can insert own strength records" ON public.strength_records;
DROP POLICY IF EXISTS "Users can update own strength records" ON public.strength_records;
DROP POLICY IF EXISTS "Users can delete own strength records" ON public.strength_records;

-- User Profiles politikaları
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Injuries politikaları
CREATE POLICY "Users can view own injuries" ON public.injuries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own injuries" ON public.injuries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own injuries" ON public.injuries
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own injuries" ON public.injuries
  FOR DELETE USING (auth.uid() = user_id);

-- Exercises politikaları (herkes görebilir)
CREATE POLICY "Exercises are viewable by everyone" ON public.exercises
  FOR SELECT USING (true);

-- Exercise History politikaları
CREATE POLICY "Users can view own exercise history" ON public.exercise_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own exercise history" ON public.exercise_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own exercise history" ON public.exercise_history
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own exercise history" ON public.exercise_history
  FOR DELETE USING (auth.uid() = user_id);

-- Recommendations politikaları
CREATE POLICY "Users can view own recommendations" ON public.recommendations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recommendations" ON public.recommendations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Equipment Classifications politikaları
CREATE POLICY "Users can view own equipment classifications" ON public.equipment_classifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own equipment classifications" ON public.equipment_classifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User Analytics politikaları
CREATE POLICY "Users can view own analytics" ON public.user_analytics
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analytics" ON public.user_analytics
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own analytics" ON public.user_analytics
  FOR UPDATE USING (auth.uid() = user_id);

-- Workouts politikaları
CREATE POLICY "Users can view own workouts" ON public.workouts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workouts" ON public.workouts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workouts" ON public.workouts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workouts" ON public.workouts
  FOR DELETE USING (auth.uid() = user_id);

-- Workout Progress politikaları
CREATE POLICY "Users can view own workout progress" ON public.workout_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own workout progress" ON public.workout_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own workout progress" ON public.workout_progress
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own workout progress" ON public.workout_progress
  FOR DELETE USING (auth.uid() = user_id);

-- Injury Assessments politikaları
CREATE POLICY "Users can view own injury assessments" ON public.injury_assessments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own injury assessments" ON public.injury_assessments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Strength Records politikaları
CREATE POLICY "Users can view own strength records" ON public.strength_records
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own strength records" ON public.strength_records
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own strength records" ON public.strength_records
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own strength records" ON public.strength_records
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- ÖRNEK VERİ EKLEME (İsteğe bağlı)
-- ============================================

-- Örnek egzersizler eklemek için (test amaçlı)
-- INSERT INTO public.exercises (name, category, equipment_type, difficulty) VALUES
-- ('Bench Press', 'Chest', 'barbell', 'intermediate'),
-- ('Squat', 'Legs', 'barbell', 'intermediate'),
-- ('Deadlift', 'Back', 'barbell', 'advanced'),
-- ('Dumbbell Curl', 'Arms', 'dumbbell', 'beginner');

