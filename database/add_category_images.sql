-- ============================================
-- KATEGORİ GÖRSELLERİ İÇİN ALAN EKLEME
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- ============================================

-- Exercises tablosuna image_url alanı ekle (eğer yoksa)
ALTER TABLE public.exercises 
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Kategori görselleri için ayrı bir tablo oluştur (opsiyonel - daha organize)
CREATE TABLE IF NOT EXISTS public.category_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_key TEXT UNIQUE NOT NULL,
  category_name TEXT NOT NULL,
  image_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Örnek kategori görselleri ekle (Storage URL'lerini buraya ekleyeceksiniz)
-- Storage'a görselleri yükledikten sonra URL'leri buraya ekleyin
INSERT INTO public.category_images (category_key, category_name, image_url) VALUES
('Chest', 'Göğüs', 'https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/exercise-images/categories/chest.jpg'),
('Back', 'Sırt', 'https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/exercise-images/categories/back.jpg'),
('Legs', 'Bacak', 'https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/exercise-images/categories/legs.jpg'),
('Arms', 'Kol', 'https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/exercise-images/categories/arms.jpg'),
('Shoulders', 'Omuz', 'https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/exercise-images/categories/shoulders.jpg'),
('Core', 'Karın', 'https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/exercise-images/categories/core.jpg'),
('Cardio', 'Kardiyovasküler', 'https://YOUR_SUPABASE_URL.supabase.co/storage/v1/object/public/exercise-images/categories/cardio.jpg')
ON CONFLICT (category_key) DO UPDATE SET
  image_url = EXCLUDED.image_url,
  updated_at = NOW();

-- RLS politikaları
ALTER TABLE public.category_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Category images are viewable by everyone" ON public.category_images
  FOR SELECT USING (true);

