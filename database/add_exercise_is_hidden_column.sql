-- ============================================
-- exercises tablosuna is_hidden kolonu ekleme
-- ============================================
-- Mevcut projelerde geriye dönük uyumluluk için.
-- Supabase Dashboard > SQL Editor'de çalıştırın.

ALTER TABLE public.exercises
ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS exercises_is_hidden_idx ON public.exercises (is_hidden);


