-- ============================================
-- ÖRNEK EGZERSİZLER - ANTrenman PROGRAMLARI
-- ============================================
-- Bu dosyayı Supabase Dashboard > SQL Editor'de çalıştırın
-- Her bölge ve zorluk seviyesi için örnek egzersizler
-- ============================================

-- Not: Smith Machine gibi bazı kayıtları program/egzersiz listelerinden gizlemek için
-- `is_hidden` kolonu kullanılır. Eski veritabanlarında yoksa ekleyelim.
ALTER TABLE public.exercises
ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN NOT NULL DEFAULT false;

-- Aynı seed dosyası tekrar çalıştırılırsa kopya kayıt oluşmasın diye benzersiz indeks
-- (name + category + difficulty + equipment_type) bazında tekilleştiriyoruz.
CREATE UNIQUE INDEX IF NOT EXISTS exercises_unique_key_idx
ON public.exercises (
  lower(name),
  coalesce(category, ''),
  coalesce(difficulty, ''),
  coalesce(equipment_type, '')
);

-- GÖĞÜS (CHEST) EGZERSİZLERİ

-- Başlangıç Seviyesi
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Push-up (Şınav)', 'Temel göğüs egzersizi, vücut ağırlığı ile yapılır', 'Chest', 'bodyweight', 'beginner', 
 '["chest", "triceps", "shoulders"]'::jsonb,
 '["Yüz üstü yatın, eller omuz genişliğinde", "Vücudunuzu düz tutarak yukarı itin", "Yavaşça aşağı inin", "10-15 tekrar yapın"]'::jsonb),

('Dumbbell Chest Press', 'Dumbbell ile göğüs basma hareketi', 'Chest', 'dumbbell', 'beginner',
 '["chest", "triceps", "shoulders"]'::jsonb,
 '["Sırt üstü yatın, dumbbellları göğüs hizasında tutun", "Yukarı doğru itin", "Yavaşça indirin", "8-12 tekrar yapın"]'::jsonb),

('Incline Push-up', 'Eğimli yüzeyde şınav, daha kolay versiyon', 'Chest', 'bodyweight', 'beginner',
 '["chest", "triceps"]'::jsonb,
 '["Ellerinizi yüksek bir yüzeye koyun", "Vücudunuzu eğik tutarak şınav yapın", "10-15 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Ek: Chest Press Machine
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Chest Press Machine', 'Göğüs pres makinesi ile kontrollü göğüs itiş hareketi', 'Chest', 'machine', 'beginner',
 '["chest", "triceps", "shoulders"]'::jsonb,
 '["Makine oturuşunu ve kol/koltuk ayarını göğüs hizasına gelecek şekilde yapın", "Sırtınızı mindere yaslayın, kürek kemiklerinizi hafifçe geriye alın", "Tutacakları kavrayın, bilekleri nötr pozisyonda tutun", "Nefes vererek tutacakları ileri itin (dirsekleri tamamen kilitlemeyin)", "Nefes alarak kontrollü şekilde başlangıca dönün", "8-12 tekrar yapın; ağırlığı form bozulmayacak seviyede seçin"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Orta Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Bench Press', 'Barbell ile göğüs basma, temel güç egzersizi', 'Chest', 'barbell', 'intermediate',
 '["chest", "triceps", "shoulders"]'::jsonb,
 '["Bench''e sırt üstü yatın", "Barbell''i göğüs hizasında tutun", "Yukarı doğru itin", "Kontrollü şekilde indirin", "6-10 tekrar yapın"]'::jsonb),

('Dumbbell Flyes', 'Dumbbell ile göğüs açma hareketi', 'Chest', 'dumbbell', 'intermediate',
 '["chest"]'::jsonb,
 '["Sırt üstü yatın, dumbbellları yanlara açın", "Göğüs kaslarınızı sıkıştırarak birleştirin", "Yavaşça açın", "10-12 tekrar yapın"]'::jsonb),

('Incline Dumbbell Press', 'Eğimli bench''te dumbbell basma', 'Chest', 'dumbbell', 'intermediate',
 '["chest", "shoulders", "triceps"]'::jsonb,
 '["Eğimli bench''e yatın", "Dumbbellları göğüs hizasında tutun", "Yukarı doğru itin", "8-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- İleri Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Weighted Dips', 'Ağırlıklı dip hareketi', 'Chest', 'bodyweight', 'advanced',
 '["chest", "triceps", "shoulders"]'::jsonb,
 '["Dip barına tutunun", "Vücudunuzu aşağı indirin", "Güçlü şekilde yukarı itin", "Ağırlık kemeri kullanın", "6-10 tekrar yapın"]'::jsonb),

('Decline Bench Press', 'Eğimli aşağı bench press', 'Chest', 'barbell', 'advanced',
 '["chest", "triceps"]'::jsonb,
 '["Decline bench''e yatın", "Barbell''i göğüs hizasında tutun", "Yukarı doğru itin", "5-8 tekrar yapın"]'::jsonb),

('Cable Crossover', 'Kablo ile göğüs açma', 'Chest', 'cable', 'advanced',
 '["chest"]'::jsonb,
 '["Kablo makinesinin ortasında durun", "Kolları yanlardan öne doğru çekin", "Göğüs kaslarınızı sıkıştırın", "10-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- SIRT (BACK) EGZERSİZLERİ

-- Başlangıç Seviyesi
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Assisted Pull-up', 'Yardımlı çekme hareketi', 'Back', 'bodyweight', 'beginner',
 '["back", "biceps"]'::jsonb,
 '["Pull-up barına tutunun", "Yardımcı bant veya makine kullanın", "Yukarı çekilin", "8-12 tekrar yapın"]'::jsonb),

('Dumbbell Row', 'Dumbbell ile sırt çekme', 'Back', 'dumbbell', 'beginner',
 '["back", "biceps"]'::jsonb,
 '["Bir bacağınızı bench''e koyun", "Dumbbell''ı aşağıdan yukarı çekin", "Sırt kaslarınızı sıkıştırın", "10-12 tekrar yapın"]'::jsonb),

('Lat Pulldown', 'Makine ile sırt çekme', 'Back', 'machine', 'beginner',
 '["back", "biceps"]'::jsonb,
 '["Lat pulldown makinesine oturun", "Barı göğsünüze doğru çekin", "Yavaşça bırakın", "10-15 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Orta Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Pull-up', 'Klasik çekme hareketi', 'Back', 'bodyweight', 'intermediate',
 '["back", "biceps", "shoulders"]'::jsonb,
 '["Pull-up barına tutunun", "Vücudunuzu yukarı çekin", "Çeneyi barın üzerine getirin", "Yavaşça inin", "8-12 tekrar yapın"]'::jsonb),

('Barbell Row', 'Barbell ile sırt çekme', 'Back', 'barbell', 'intermediate',
 '["back", "biceps"]'::jsonb,
 '["Hafif öne eğilin", "Barbell''i göğsünüze doğru çekin", "Sırt kaslarınızı sıkıştırın", "6-10 tekrar yapın"]'::jsonb),

('T-Bar Row', 'T-bar ile sırt çekme', 'Back', 'machine', 'intermediate',
 '["back", "biceps"]'::jsonb,
 '["T-bar makinesine oturun", "Barı göğsünüze doğru çekin", "Kontrollü şekilde bırakın", "8-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- İleri Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Weighted Pull-up', 'Ağırlıklı çekme hareketi', 'Back', 'bodyweight', 'advanced',
 '["back", "biceps", "shoulders"]'::jsonb,
 '["Ağırlık kemeri takın", "Pull-up barına tutunun", "Güçlü şekilde yukarı çekin", "5-8 tekrar yapın"]'::jsonb),

('One-Arm Dumbbell Row', 'Tek kol dumbbell çekme', 'Back', 'dumbbell', 'advanced',
 '["back", "biceps"]'::jsonb,
 '["Bir bacağınızı bench''e koyun", "Tek dumbbell ile çekme yapın", "Maksimum kontraksiyon", "8-10 tekrar her kol"]'::jsonb),

('Cable Row', 'Kablo ile sırt çekme', 'Back', 'cable', 'advanced',
 '["back", "biceps"]'::jsonb,
 '["Kablo makinesine oturun", "Barı göğsünüze doğru çekin", "Sırt kaslarınızı sıkıştırın", "8-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- BACAK (LEGS) EGZERSİZLERİ

-- Başlangıç Seviyesi
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Bodyweight Squat', 'Vücut ağırlığı ile çömelme', 'Legs', 'bodyweight', 'beginner',
 '["quadriceps", "glutes", "hamstrings"]'::jsonb,
 '["Ayaklar omuz genişliğinde", "Dizlerinizi bükerek çömelin", "Kalçalarınızı geriye itin", "Yukarı kalkın", "12-15 tekrar yapın"]'::jsonb),

('Lunges', 'Adım atarak çömelme', 'Legs', 'bodyweight', 'beginner',
 '["quadriceps", "glutes"]'::jsonb,
 '["Bir adım öne atın", "Ön dizinizi bükün", "Arka diziniz neredeyse yere değsin", "Her bacak için 10-12 tekrar"]'::jsonb),

('Leg Press', 'Makine ile bacak basma', 'Legs', 'machine', 'beginner',
 '["quadriceps", "glutes"]'::jsonb,
 '["Leg press makinesine oturun", "Ayaklarınızı platforma yerleştirin", "Yukarı doğru itin", "Yavaşça indirin", "12-15 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Ek: Leg Extension (Machine)
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Leg Extension', 'Ön bacak (quadriceps) odaklı leg extension makinesi hareketi', 'Legs', 'machine', 'beginner',
 '["quadriceps"]'::jsonb,
 '["Makine oturuşunu ayarlayın; diz eklemi dönme noktasına hizalansın", "Ayak bileği pedini alt kaval kemiğine gelecek şekilde yerleştirin", "Sırtınızı mindere yaslayın, core sıkı", "Nefes vererek dizinizi açıp ağırlığı yukarı kaldırın (dizleri kilitlemeyin)", "Üst noktada 1 saniye quadriceps sıkıştırın", "Nefes alarak kontrollü şekilde aşağı indirin", "10-15 tekrar yapın; momentumla savurmayın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Ek: Leg Curl Machine (Hamstring)
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Leg Curl Machine', 'Arka bacak (hamstring) odaklı leg curl makinesi hareketi', 'Legs', 'machine', 'beginner',
 '["hamstrings"]'::jsonb,
 '["Makine tipine göre ayarlayın (seated/lying); diz eklemi dönme noktasına hizalansın", "Pedleri topuk/ayak bileği hizasına yerleştirin", "Kalçayı ve gövdeyi sabitleyin, bel boşluğunu aşırı artırmayın", "Nefes vererek dizinizi büküp ağırlığı kontrollü çekin", "Alt noktada 1 saniye hamstring sıkıştırın", "Nefes alarak kontrollü şekilde başlangıca dönün", "10-15 tekrar yapın; hareketi belden değil dizden üretin"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Orta Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Barbell Squat', 'Barbell ile çömelme', 'Legs', 'barbell', 'intermediate',
 '["quadriceps", "glutes", "hamstrings"]'::jsonb,
 '["Barbell''i omuzlarınıza yerleştirin", "Ayaklar omuz genişliğinde", "Dizlerinizi bükerek çömelin", "Güçlü şekilde kalkın", "8-12 tekrar yapın"]'::jsonb),

('Romanian Deadlift', 'RDL hareketi, hamstring odaklı', 'Legs', 'barbell', 'intermediate',
 '["hamstrings", "glutes", "back"]'::jsonb,
 '["Barbell''i tutun, dizler hafif bükük", "Kalçalarınızı geriye itin", "Göğsünüzü yukarı tutun", "8-12 tekrar yapın"]'::jsonb),

('Walking Lunges', 'Yürüyerek lunge', 'Legs', 'bodyweight', 'intermediate',
 '["quadriceps", "glutes"]'::jsonb,
 '["Bir adım öne atın ve çömelin", "Arka ayağınızı öne getirin", "Devam edin", "Her bacak için 10-12 adım"]'::jsonb)
ON CONFLICT DO NOTHING;

-- İleri Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Front Squat', 'Ön squat, barbell önde', 'Legs', 'barbell', 'advanced',
 '["quadriceps", "glutes", "core"]'::jsonb,
 '["Barbell''i ön omuzlarınıza yerleştirin", "Dizlerinizi bükerek çömelin", "Göğsünüzü yukarı tutun", "6-10 tekrar yapın"]'::jsonb),

('Bulgarian Split Squat', 'Tek bacak çömelme', 'Legs', 'dumbbell', 'advanced',
 '["quadriceps", "glutes"]'::jsonb,
 '["Arka ayağınızı yüksek bir yere koyun", "Ön dizinizi bükerek çömelin", "Dumbbell tutabilirsiniz", "Her bacak için 8-10 tekrar"]'::jsonb),

('Hack Squat', 'Hack squat makinesi', 'Legs', 'machine', 'advanced',
 '["quadriceps", "glutes"]'::jsonb,
 '["Hack squat makinesine girin", "Omuzlarınızı yastıklara yerleştirin", "Çömelin ve kalkın", "8-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- KOL (ARMS) EGZERSİZLERİ

-- Başlangıç Seviyesi
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Dumbbell Bicep Curl', 'Dumbbell ile biceps curl', 'Arms', 'dumbbell', 'beginner',
 '["biceps"]'::jsonb,
 '["Dumbbellları yanlarınızda tutun", "Dirseklerinizi sabit tutun", "Yukarı doğru kıvırın", "Yavaşça indirin", "10-15 tekrar yapın"]'::jsonb),

('Tricep Dips (Assisted)', 'Yardımlı triceps dip', 'Arms', 'bodyweight', 'beginner',
 '["triceps", "shoulders"]'::jsonb,
 '["Bench''e ellerinizi koyun", "Bacaklarınızı öne uzatın", "Vücudunuzu aşağı indirin", "Yukarı itin", "10-12 tekrar yapın"]'::jsonb),

('Hammer Curl', 'Çekiç curl, ön kol odaklı', 'Arms', 'dumbbell', 'beginner',
 '["biceps", "forearms"]'::jsonb,
 '["Dumbbellları yanlarınızda tutun", "Avuç içleri birbirine baksın", "Yukarı doğru kıvırın", "10-15 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Ek: Arm Curl Machine
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Arm Curl Machine', 'Biceps kaslarını izole etmeye yardımcı olan kol curl makinesi hareketi', 'Arms', 'machine', 'beginner',
 '["biceps", "forearms"]'::jsonb,
 '["Makine oturuşunu ayarlayın; dirsek eklemi makinenin dönme noktasına hizalansın", "Üst kol pedlere sabit; omuzları yukarı çekmeden nötr tutun", "Tutacakları kavrayın ve nefes vererek dirsekten bükerek yukarı kıvırın", "Üst noktada 1 saniye biceps sıkıştırın", "Nefes alarak kontrollü şekilde aşağı indirin (tam bırakıp eklemi zorlamayın)", "10-15 tekrar yapın; gövdeyi sallamayın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Orta Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Barbell Bicep Curl', 'Barbell ile biceps curl', 'Arms', 'barbell', 'intermediate',
 '["biceps"]'::jsonb,
 '["Barbell''i omuz genişliğinde tutun", "Dirseklerinizi sabit tutun", "Yukarı doğru kıvırın", "8-12 tekrar yapın"]'::jsonb),

('Close-Grip Bench Press', 'Dar tutuş bench press, triceps odaklı', 'Arms', 'barbell', 'intermediate',
 '["triceps", "chest"]'::jsonb,
 '["Bench''e yatın", "Ellerinizi dar tutun", "Yukarı doğru itin", "8-12 tekrar yapın"]'::jsonb),

('Cable Bicep Curl', 'Kablo ile biceps curl', 'Arms', 'cable', 'intermediate',
 '["biceps"]'::jsonb,
 '["Kablo makinesinin önünde durun", "Barı yukarı doğru çekin", "Biceps kaslarınızı sıkıştırın", "10-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- İleri Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Preacher Curl', 'Preacher bench''te biceps curl', 'Arms', 'barbell', 'advanced',
 '["biceps"]'::jsonb,
 '["Preacher bench''e oturun", "Kollarınızı yastığa yerleştirin", "Barbell''i kıvırın", "6-10 tekrar yapın"]'::jsonb),

('Weighted Dips', 'Ağırlıklı triceps dip', 'Arms', 'bodyweight', 'advanced',
 '["triceps", "shoulders", "chest"]'::jsonb,
 '["Ağırlık kemeri takın", "Dip barına tutunun", "Vücudunuzu aşağı indirin", "Güçlü şekilde yukarı itin", "6-10 tekrar yapın"]'::jsonb),

('Cable Tricep Extension', 'Kablo ile triceps extension', 'Arms', 'cable', 'advanced',
 '["triceps"]'::jsonb,
 '["Kablo makinesinin önünde durun", "Rope tutun", "Aşağı doğru itin", "Triceps kaslarınızı sıkıştırın", "10-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- OMUZ (SHOULDERS) EGZERSİZLERİ

-- Başlangıç Seviyesi
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Dumbbell Shoulder Press', 'Dumbbell ile omuz basma', 'Shoulders', 'dumbbell', 'beginner',
 '["shoulders", "triceps"]'::jsonb,
 '["Dumbbellları omuz hizasında tutun", "Yukarı doğru itin", "Yavaşça indirin", "10-12 tekrar yapın"]'::jsonb),

('Lateral Raises', 'Yan omuz kaldırma', 'Shoulders', 'dumbbell', 'beginner',
 '["shoulders"]'::jsonb,
 '["Dumbbellları yanlarınızda tutun", "Kolları yanlara doğru kaldırın", "Omuz hizasına kadar", "10-15 tekrar yapın"]'::jsonb),

('Front Raises', 'Ön omuz kaldırma', 'Shoulders', 'dumbbell', 'beginner',
 '["shoulders"]'::jsonb,
 '["Dumbbellları önünüzde tutun", "Kolları öne doğru kaldırın", "Omuz hizasına kadar", "10-15 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Ek: Lateral Raise Machine
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Lateral Raise Machine', 'Omuz yan deltoid odaklı makine ile lateral raise hareketi', 'Shoulders', 'machine', 'beginner',
 '["shoulders"]'::jsonb,
 '["Makinede oturuş ve kol pedlerini omuz hizasına gelecek şekilde ayarlayın", "Göğsünüz dik, core sıkı; omuzları yukarı çekmeden nötr tutun", "Pedleri/kolu yanlara doğru kaldırın (dirsekler hafif bükülü)", "Üst noktada 1 saniye sıkıştırın", "Kontrollü şekilde başlangıca indirin", "10-15 tekrar yapın; hareketi sallanarak değil omuzla yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Orta Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Barbell Shoulder Press', 'Barbell ile omuz basma', 'Shoulders', 'barbell', 'intermediate',
 '["shoulders", "triceps"]'::jsonb,
 '["Barbell''i omuz hizasında tutun", "Yukarı doğru itin", "Kontrollü şekilde indirin", "8-12 tekrar yapın"]'::jsonb),

('Arnold Press', 'Arnold press, rotasyonlu omuz basma', 'Shoulders', 'dumbbell', 'intermediate',
 '["shoulders", "triceps"]'::jsonb,
 '["Dumbbellları önde tutun, avuç içleri size baksın", "Basarken döndürün", "Yukarı doğru itin", "8-12 tekrar yapın"]'::jsonb),

('Upright Row', 'Dik çekme, omuz odaklı', 'Shoulders', 'barbell', 'intermediate',
 '["shoulders", "traps"]'::jsonb,
 '["Barbell''i dar tutun", "Yukarı doğru çekin", "Dirsekler yukarı", "8-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- İleri Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Overhead Press', 'Ayakta overhead press', 'Shoulders', 'barbell', 'advanced',
 '["shoulders", "triceps", "core"]'::jsonb,
 '["Barbell''i omuz hizasında tutun", "Ayakta durun", "Yukarı doğru itin", "Core''unuzu sıkın", "6-10 tekrar yapın"]'::jsonb),

('Pike Push-up', 'Ters V şınav, omuz odaklı', 'Shoulders', 'bodyweight', 'advanced',
 '["shoulders", "triceps"]'::jsonb,
 '["Ters V pozisyonu alın", "Başınızı yere doğru indirin", "Yukarı itin", "8-12 tekrar yapın"]'::jsonb),

('Face Pull', 'Yüz çekme, arka omuz odaklı', 'Shoulders', 'cable', 'advanced',
 '["shoulders", "back"]'::jsonb,
 '["Kablo makinesinin önünde durun", "Rope''u yüzünüze doğru çekin", "Arka omuz kaslarınızı sıkıştırın", "12-15 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- KARIN (CORE) EGZERSİZLERİ

-- Başlangıç Seviyesi
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Plank', 'Düz duruş, karın güçlendirme', 'Core', 'bodyweight', 'beginner',
 '["core", "shoulders"]'::jsonb,
 '["Yüz üstü yatın, dirsekler yerde", "Vücudunuzu düz tutun", "30-60 saniye tutun"]'::jsonb),

('Crunches', 'Mekik, karın kası çalıştırma', 'Core', 'bodyweight', 'beginner',
 '["core"]'::jsonb,
 '["Sırt üstü yatın, dizler bükük", "Omuzlarınızı yukarı kaldırın", "Karın kaslarınızı sıkın", "15-20 tekrar yapın"]'::jsonb),

('Leg Raises', 'Bacak kaldırma', 'Core', 'bodyweight', 'beginner',
 '["core"]'::jsonb,
 '["Sırt üstü yatın", "Bacaklarınızı yukarı kaldırın", "Yavaşça indirin", "10-15 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Orta Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Russian Twists', 'Rus dönüşü, yan karın', 'Core', 'bodyweight', 'intermediate',
 '["core", "obliques"]'::jsonb,
 '["Oturun, dizler bükük", "Gövdenizi döndürün", "Her iki yana", "20-30 tekrar yapın"]'::jsonb),

('Mountain Climbers', 'Dağ tırmanışı hareketi', 'Core', 'bodyweight', 'intermediate',
 '["core", "shoulders", "legs"]'::jsonb,
 '["Plank pozisyonu alın", "Dizlerinizi göğsünüze çekin", "Hızlı hareket", "20-30 tekrar yapın"]'::jsonb),

('Dead Bug', 'Ölü böcek hareketi', 'Core', 'bodyweight', 'intermediate',
 '["core"]'::jsonb,
 '["Sırt üstü yatın, kollar ve bacaklar yukarı", "Karşı kol ve bacağı indirin", "Alternatif yapın", "10-12 tekrar her taraf"]'::jsonb)
ON CONFLICT DO NOTHING;

-- İleri Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Hanging Leg Raises', 'Asılı bacak kaldırma', 'Core', 'bodyweight', 'advanced',
 '["core"]'::jsonb,
 '["Pull-up barına asılın", "Bacaklarınızı yukarı kaldırın", "Dizlerinizi göğsünüze çekin", "10-15 tekrar yapın"]'::jsonb),

('Dragon Flag', 'Ejderha bayrağı', 'Core', 'bodyweight', 'advanced',
 '["core"]'::jsonb,
 '["Bench''e sırt üstü yatın, eller başın arkasında", "Vücudunuzu düz tutarak kaldırın", "Yavaşça indirin", "5-8 tekrar yapın"]'::jsonb),

('Ab Wheel Rollout', 'Karın tekerleği', 'Core', 'bodyweight', 'advanced',
 '["core", "shoulders"]'::jsonb,
 '["Ab wheel''i tutun, dizleriniz yerde", "Öne doğru yuvarlayın", "Maksimum gerilme", "Yavaşça geri gelin", "8-12 tekrar yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- KARDİYOVASKÜLER (CARDIO) EGZERSİZLERİ

-- Başlangıç Seviyesi
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Yürüyüş', 'Tempolu yürüyüş, düşük yoğunluk', 'Cardio', 'bodyweight', 'beginner',
 '["legs", "cardio"]'::jsonb,
 '["Düz bir yolda yürüyün", "Hızlı tempoda", "20-30 dakika süreyle", "Nefes alışverişinizi kontrol edin"]'::jsonb),

('Jumping Jacks', 'Kolları açıp kapatma', 'Cardio', 'bodyweight', 'beginner',
 '["cardio", "legs", "shoulders"]'::jsonb,
 '["Ayakta durun", "Zıplayarak kolları açın", "Tekrar kapatın", "30-50 tekrar yapın"]'::jsonb),

('Stationary Bike', 'Sabit bisiklet', 'Cardio', 'machine', 'beginner',
 '["legs", "cardio"]'::jsonb,
 '["Bisiklete oturun", "Rahat tempoda pedal çevirin", "20-30 dakika süreyle", "Nabzınızı takip edin"]'::jsonb)
ON CONFLICT DO NOTHING;

-- Orta Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Koşu', 'Orta tempolu koşu', 'Cardio', 'bodyweight', 'intermediate',
 '["legs", "cardio"]'::jsonb,
 '["Rahat bir tempoda koşun", "20-30 dakika süreyle", "Nefes alışverişinizi kontrol edin", "Hızınızı ayarlayın"]'::jsonb),

('Burpees', 'Burpee, tam vücut kardiyo', 'Cardio', 'bodyweight', 'intermediate',
 '["cardio", "legs", "chest", "shoulders"]'::jsonb,
 '["Çömelin, eller yerde", "Plank pozisyonuna geçin", "Şınav yapın", "Geri zıplayın", "Yukarı zıplayın", "10-15 tekrar yapın"]'::jsonb),

('High Knees', 'Yüksek diz kaldırma', 'Cardio', 'bodyweight', 'intermediate',
 '["cardio", "legs", "core"]'::jsonb,
 '["Ayakta durun", "Dizlerinizi göğsünüze çekin", "Hızlı hareket", "30-60 saniye yapın"]'::jsonb)
ON CONFLICT DO NOTHING;

-- İleri Seviye
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions) VALUES
('Sprint Intervals', 'Hız aralıklı koşu', 'Cardio', 'bodyweight', 'advanced',
 '["legs", "cardio"]'::jsonb,
 '["30 saniye maksimum hızda koşun", "60 saniye yürüyün", "5-8 tur tekrarlayın", "Toplam 15-20 dakika"]'::jsonb),

('Box Jumps', 'Kutu zıplama', 'Cardio', 'bodyweight', 'advanced',
 '["legs", "cardio", "glutes"]'::jsonb,
 '["Bir kutu veya platform önünde durun", "Yukarı zıplayın, kutuya inin", "Geri atlayın", "10-15 tekrar yapın"]'::jsonb),

('Rowing Machine', 'Kürek çekme makinesi', 'Cardio', 'machine', 'advanced',
 '["cardio", "back", "legs", "shoulders"]'::jsonb,
 '["Kürek makinesine oturun", "Ayaklarınızı sabitleyin", "Güçlü şekilde çekin", "20-30 dakika süreyle"]'::jsonb)
ON CONFLICT DO NOTHING;

-- ============================================
-- EKİPMAN (SADECE TANIMA) - SMITH MACHINE
-- ============================================
-- Not: Bu kayıt program/egzersiz listelerinde görünmesin diye is_hidden = true.
INSERT INTO public.exercises (name, description, category, equipment_type, difficulty, muscle_groups, instructions, is_hidden) VALUES
('Smith Machine', 'Smith machine (sabit raylı bar) üzerinde güvenlik kilitleri ile yapılan çok amaçlı ekipman. Bu sayfa ekipmanın genel kullanımını ve yaygın varyasyonlarını içerir.', 'Equipment', 'machine', 'beginner',
 '["full_body"]'::jsonb,
 '["Genel kullanım: Bar yüksekliğini ayarlayın ve güvenlik stoplarını (safety) doğru seviyeye getirin", "Barı kavrayın, barı döndürerek kilidi açın ve başlangıç pozisyonunu alın", "Hareketi kontrollü eksende yapın; eklemleri kilitlemeyin ve nefesi kontrol edin", "Tekrar bitince barı yukarı getirip döndürerek kilitleyin", "Varyasyon: Smith Machine Squat", "Varyasyon: Smith Machine Incline Press", "Varyasyon: Smith Machine Shoulder Press", "Varyasyon: Smith Machine Romanian Deadlift", "Varyasyon: Smith Machine Calf Raise", "Varyasyon: Smith Machine Hip Thrust"]'::jsonb,
 true)
ON CONFLICT DO NOTHING;

