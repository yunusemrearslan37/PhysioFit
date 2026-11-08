-- ============================================
-- exercises tablosundaki kopya kayıtları temizleme
-- ============================================
-- Neden: sample_exercises.sql birden fazla kez çalıştırıldıysa aynı egzersizler
-- (name+category+difficulty+equipment_type) bazında tekrar eklenmiş olabilir.
--
-- Bu script:
-- 1) Bu anahtara göre kopyaları siler (en eski kaydı tutar)
-- 2) Tekrar oluşmasını engellemek için UNIQUE INDEX ekler

-- 1) Kopyaları sil (en eski created_at/id kalsın)
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY
        lower(name),
        coalesce(category, ''),
        coalesce(difficulty, ''),
        coalesce(equipment_type, '')
      ORDER BY created_at ASC, id ASC
    ) AS rn
  FROM public.exercises
)
DELETE FROM public.exercises e
USING ranked r
WHERE e.id = r.id
  AND r.rn > 1;

-- 2) Bundan sonra aynı kayıt bir daha eklenmesin
CREATE UNIQUE INDEX IF NOT EXISTS exercises_unique_key_idx
ON public.exercises (
  lower(name),
  coalesce(category, ''),
  coalesce(difficulty, ''),
  coalesce(equipment_type, '')
);


