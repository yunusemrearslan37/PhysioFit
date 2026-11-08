-- Manuel rehabilitasyon planları
-- İlk kurulum veya düzeltme için: fix_rehab_plans_migration.sql dosyasını kullanın.
-- Supabase Dashboard > SQL Editor'de çalıştırın

ALTER TABLE public.injury_assessments
ADD COLUMN IF NOT EXISTS recovery_status TEXT DEFAULT 'aktif',
ADD COLUMN IF NOT EXISTS recovery_checked_at TIMESTAMP WITH TIME ZONE;

CREATE TABLE IF NOT EXISTS public.rehab_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  assessment_id UUID REFERENCES public.injury_assessments(id) ON DELETE SET NULL,
  body_part TEXT NOT NULL,
  name TEXT NOT NULL,
  exercises JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_days INTEGER NOT NULL DEFAULT 7 CHECK (total_days >= 1 AND total_days <= 90),
  recovery_status TEXT NOT NULL DEFAULT 'aktif',
  recovery_checked_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Eski yapı (assessment_id) varsa progress tablosunu yenile
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'rehab_plan_progress'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'rehab_plan_progress'
      AND column_name = 'rehab_plan_id'
  ) THEN
    DROP TABLE public.rehab_plan_progress;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.rehab_plan_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  rehab_plan_id UUID NOT NULL REFERENCES public.rehab_plans(id) ON DELETE CASCADE,
  day_number INTEGER NOT NULL CHECK (day_number >= 1 AND day_number <= 90),
  completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, rehab_plan_id, day_number)
);

CREATE INDEX IF NOT EXISTS idx_rehab_plans_user_active
  ON public.rehab_plans(user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_rehab_plan_progress_plan
  ON public.rehab_plan_progress(rehab_plan_id);

ALTER TABLE public.rehab_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rehab_plan_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own rehab plans" ON public.rehab_plans;
DROP POLICY IF EXISTS "Users can insert own rehab plans" ON public.rehab_plans;
DROP POLICY IF EXISTS "Users can update own rehab plans" ON public.rehab_plans;
DROP POLICY IF EXISTS "Users can delete own rehab plans" ON public.rehab_plans;

CREATE POLICY "Users can view own rehab plans" ON public.rehab_plans
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own rehab plans" ON public.rehab_plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own rehab plans" ON public.rehab_plans
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own rehab plans" ON public.rehab_plans
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own rehab progress" ON public.rehab_plan_progress;
DROP POLICY IF EXISTS "Users can insert own rehab progress" ON public.rehab_plan_progress;
DROP POLICY IF EXISTS "Users can update own rehab progress" ON public.rehab_plan_progress;

CREATE POLICY "Users can view own rehab progress" ON public.rehab_plan_progress
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own rehab progress" ON public.rehab_plan_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own rehab progress" ON public.rehab_plan_progress
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own injury assessments" ON public.injury_assessments;
CREATE POLICY "Users can update own injury assessments" ON public.injury_assessments
  FOR UPDATE USING (auth.uid() = user_id);

NOTIFY pgrst, 'reload schema';
