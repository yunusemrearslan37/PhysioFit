-- ============================================
-- KİŞİSELLEŞTİRME VE AI TABLOLARI
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- Mevcut şemayı bozmaz, sadece yeni tablolar ekler
-- ============================================

-- ============================================
-- 1) USER_GOALS - Kullanıcı Hedefleri
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  goal_type TEXT NOT NULL CHECK (goal_type IN ('weight_loss', 'muscle_gain', 'physiotherapy', 'general_fitness')),
  target_weight DECIMAL(5,2),            -- Hedef kilo (opsiyonel)
  activity_level TEXT NOT NULL DEFAULT 'moderate' CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
  workout_days_per_week INTEGER DEFAULT 3 CHECK (workout_days_per_week BETWEEN 1 AND 7),
  experience_level TEXT DEFAULT 'beginner' CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2) USER_METRICS - Kullanıcı Fiziksel Metrikleri
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  height DECIMAL(5,2),          -- cm cinsinden
  weight DECIMAL(5,2),          -- kg cinsinden
  body_fat_percentage DECIMAL(4,1),  -- % cinsinden (opsiyonel)
  recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3) USER_LIMITATIONS - Kullanıcı Fiziksel Kısıtlamaları
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_limitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  body_part TEXT NOT NULL,       -- 'diz', 'omuz', 'bel', vb.
  limitation_type TEXT NOT NULL,  -- 'sakatlık', 'ameliyat', 'kronik ağrı', 'hareket kısıtlılığı'
  severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high')),
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4) AI_CHAT_MESSAGES - AI Sohbet Geçmişi
-- ============================================
CREATE TABLE IF NOT EXISTS public.ai_chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  context JSONB,                 -- Mesaj bağlamı (hedef, metrikler, kısıtlamalar vb.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- user_profiles tablosuna onboarding_completed kolonu ekle
-- ============================================
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT false;

-- ============================================
-- INDEX'LER
-- ============================================
CREATE INDEX IF NOT EXISTS idx_user_goals_user_id ON public.user_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_user_goals_active ON public.user_goals(user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_user_metrics_user_id ON public.user_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_metrics_recorded_at ON public.user_metrics(user_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_limitations_user_id ON public.user_limitations(user_id);
CREATE INDEX IF NOT EXISTS idx_user_limitations_active ON public.user_limitations(user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_user_id ON public.ai_chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_created_at ON public.ai_chat_messages(user_id, created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- RLS etkinleştir
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_limitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_chat_messages ENABLE ROW LEVEL SECURITY;

-- user_goals politikaları
CREATE POLICY "Users can view own goals" ON public.user_goals
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own goals" ON public.user_goals
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own goals" ON public.user_goals
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own goals" ON public.user_goals
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- user_metrics politikaları
CREATE POLICY "Users can view own metrics" ON public.user_metrics
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own metrics" ON public.user_metrics
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own metrics" ON public.user_metrics
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own metrics" ON public.user_metrics
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- user_limitations politikaları
CREATE POLICY "Users can view own limitations" ON public.user_limitations
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own limitations" ON public.user_limitations
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own limitations" ON public.user_limitations
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own limitations" ON public.user_limitations
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ai_chat_messages politikaları
CREATE POLICY "Users can view own chat messages" ON public.ai_chat_messages
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chat messages" ON public.ai_chat_messages
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own chat messages" ON public.ai_chat_messages
  FOR DELETE TO authenticated USING (auth.uid() = user_id);
