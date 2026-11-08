-- ============================================
-- EGZERSİZ YAPILIŞ METİNLERİ GÜNCELLEMESİ
-- ============================================
-- Sadece description ve instructions güncellenir.
-- name, category, difficulty, equipment_type DEĞİŞMEZ.
-- Supabase Dashboard > SQL Editor'de çalıştırın.
-- ============================================

BEGIN;

-- ============================================
-- FAZ 1B — ÖNCELİK 1: BACAK
-- ============================================

UPDATE public.exercises SET
  description = 'Vücut ağırlığı ile yapılan temel bacak güçlendirme hareketi. Kalça, uyluk ve core kaslarını birlikte çalıştırır; form öğrenmek için ideal başlangıç hareketidir.',
  instructions = '[
    "Ayaklar omuz genişliğinde veya biraz daha geniş açılsın; ayak parmakları hafif dışa baksın",
    "Göğsü yukarıda tutun, core sıkı olsun; kollar önde veya göğüste kavuşturulabilir",
    "Kalçayı geriye vererek dizleri bükün; dizler ayak parmaklarıyla aynı yönde kalsın",
    "Çömelme derinliğinde uyluklar yere paralel olmaya çalışın; topuklar yerden kalkmasın",
    "Nefes vererek topuklardan iterek ayağa kalkın; kalçayı öne itmeyin",
    "12-15 tekrar, 2-3 set uygulayın",
    "Dizler içe çökmemeli; beli yuvarlamayın",
    "Diz ağrısında derinliği azaltın veya hareketi durdurun"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Bodyweight Squat') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'Ön bacak ve kalça kaslarını çalıştıran adım hareketi. Denge ve tek bacak gücü için temel bir egzersizdir.',
  instructions = '[
    "Ayakta dik durun; göğüs yukarıda, core sıkı",
    "Bir adım öne atın; ön ayak tamamen yerde, arka topuk havada",
    "Ön dizinizi bükerek aşağı inin; arka diz neredeyse yere değecek kadar yaklaşsın",
    "Ön diz ayak parmak hizasını geçmesin; gövde dik kalsın",
    "Ön topuktan iterek başlangıç pozisyonuna dönün",
    "Her bacak için 10-12 tekrar, 2-3 set",
    "Öne yaslanmayın; adım çok kısa veya çok uzun olmasın",
    "Diz veya kalça ağrısında adım mesafesini kısaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Lunges') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'İleri yürüyerek yapılan lunge varyasyonu. Bacak dayanıklılığı ve koordinasyonu geliştirir.',
  instructions = '[
    "Ayakta dik başlayın; core sıkı, omuzlar gevşek",
    "Bir adım öne atıp ön dizinizi bükerek çömelin",
    "Arka diz yere yaklaşsın; gövde dik, ön diz ayak üstünde kalsın",
    "Arka ayağınızı öne getirerek bir sonraki adıma geçin",
    "Her adımda kontrollü iniş ve kalkış yapın; zıplamayın",
    "Her bacak için 10-12 adım, 2-3 tur",
    "Dizler içe kaymamalı; bel düz kalmalı",
    "Denge sorununda duvara yakın veya daha kısa adımla yapın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Walking Lunges') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'Barbell ile yapılan temel bileşik bacak hareketi. Quadriceps, kalça ve core kaslarını güçlendirir; doğru form kritiktir.',
  instructions = '[
    "Barbell''i üst sırt (trapez) üzerine yerleştirin; ayaklar omuz genişliğinde",
    "Göğsü yukarıda tutun, core sıkı; kürek kemiklerini sıkıştırın",
    "Kalçayı geriye vererek dizleri bükün; dizler ayak parmaklarıyla hizalı kalsın",
    "Uyluklar yere paralel veya biraz altına inin; topuklar yerde sabit",
    "Nefes vererek topuklardan iterek ayağa kalkın",
    "8-12 tekrar, 2-4 set; ağırlığı form bozulmayacak seviyede seçin",
    "Beli yuvarlamayın; dizleri içe çöktürmeyin",
    "Bel veya diz ağrısında ağırlığı azaltın veya squat derinliğini kısaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Barbell Squat') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'Hamstring ve kalça odaklı kalça menteşe hareketi. Bel kaslarını koruyarak arka bacak zincirini güçlendirir.',
  instructions = '[
    "Ayakta barbell''i overhand tutun; ayaklar kalça genişliğinde",
    "Dizler hafif bükük kalsın; göğüs yukarıda, sırt nötr",
    "Kalçayı geriye iterek gövdeyi öne eğin; bar bacaklara yakın insin",
    "Hamstring gerilmesini hissedene kadar inin; beli yuvarlamayın",
    "Kalçayı öne iterek dik pozisyona dönün; sırt açısını koruyun",
    "8-12 tekrar, 2-3 set",
    "Hareketi belden değil kalçadan başlatın",
    "Bel ağrısında ağırlığı azaltın veya hareket açıklığını kısaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Romanian Deadlift') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'Barbell''in ön omuzda tutulduğu squat varyasyonu. Quadriceps ve core aktivasyonu yüksektir; dik duruş gerektirir.',
  instructions = '[
    "Barbell''i ön omuzlarda (front rack) veya çapraz kollarla destekleyin",
    "Ayaklar omuz genişliğinde; dirsekler yukarıda, göğüs dik",
    "Core sıkı; kalçayı geriye vererek kontrollü çömelin",
    "Dizler ayak parmaklarıyla hizalı; uyluklar paralel veya altına inebilir",
    "Nefes vererek topuklardan iterek kalkın; göğüs yukarıda kalsın",
    "6-10 tekrar, 2-4 set",
    "Dirsekler düşmemeli; bel öne eğilmemeli",
    "Bilek veya omuz ağrısında tutuş pozisyonunu değiştirin"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Front Squat') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'Arka ayağın yükseltildiği tek bacak squat hareketi. Denge, quadriceps ve kalça gücünü artırır.',
  instructions = '[
    "Arka ayağın üst kısmını bench veya platforma yerleştirin",
    "Ön ayak önde; gövde dik, core sıkı",
    "Ön dizinizi bükerek aşağı inin; arka diz bench''e doğru insin",
    "Ön uyluk yere paralel olmaya çalışsın; ön diz ayak üzerinde kalsın",
    "Ön topuktan iterek yukarı kalkın",
    "Her bacak için 8-10 tekrar, 2-3 set; isteğe bağlı dumbbell tutulabilir",
    "Öne yaslanmayın; kalça yana kaymamalı",
    "Denge zorluğunda bench yüksekliğini azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Bulgarian Split Squat') AND category = 'Legs';

-- ============================================
-- FAZ 1B — ÖNCELİK 1: GÖĞÜS
-- ============================================

UPDATE public.exercises SET
  description = 'Barbell ile yapılan temel göğüs kuvvet hareketi. Göğüs, triceps ve ön omuz kaslarını birlikte çalıştırır.',
  instructions = '[
    "Düz bench''e sırt üstü yatın; ayaklar yerde sabit, bel doğal eğri korunsun",
    "Barbell''i omuz genişliğinden biraz geniş kavrayın; bilekler düz",
    "Kürek kemiklerini sıkıştırıp göğsü yukarı tutun; bar göğüs hizasında beklesin",
    "Nefes alarak barı göğüs hizasına kontrollü indirin; dirsekler ~45° açıda",
    "Göğüs hizasında kısa duraklama; bar göğse değmemeli",
    "Nefes vererek barı yukarı itin; dirsekleri tam kilitlemeyin",
    "6-10 tekrar, 2-4 set; spotter veya güvenlik çubukları önerilir",
    "Omuz veya bilek ağrısında ağırlığı azaltın veya tutuş genişliğini ayarlayın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Bench Press') AND category = 'Chest';

-- ============================================
-- FAZ 1B — ÖNCELİK 1: SIRT
-- ============================================

UPDATE public.exercises SET
  description = 'Barbell ile yapılan yatay çekme hareketi. Orta sırt, lat ve biceps kaslarını güçlendirir.',
  instructions = '[
    "Ayaklar kalça genişliğinde; hafif diz bükük, kalça geride",
    "Overhand veya underhand tutuşla barbell''i tutun; gövde ~45° öne eğik",
    "Sırt nötr, core sıkı; bar kolların uzunluğunda sarkıyor",
    "Nefes vererek kürek kemiklerini sıkıştırıp barı alt göğüs/karın hizasına çekin",
    "Üst noktada 1 saniye sıkıştırın; dirsekler vücuda yakın",
    "Nefes alarak kontrollü şekilde başlangıca indirin",
    "6-10 tekrar, 2-4 set",
    "Beli yuvarlamayın; momentumla çekmeyin"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Barbell Row') AND category = 'Back';

UPDATE public.exercises SET
  description = 'Vücut ağırlığı ile yapılan klasik çekme hareketi. Sırt genişliği ve üst vücut çekiş gücünü geliştirir.',
  instructions = '[
    "Pull-up barına omuz genişliğinde overhand tutunun; kollar tamamen uzansın",
    "Core sıkı; bacaklar hafif önde çapraz veya düz olabilir",
    "Kürek kemiklerini aşağı çekerek çeneyi barın üzerine getirin",
    "Üst noktada kısa duraklama; dirsekleri tam kilitlemeyin",
    "Nefes alarak kontrollü şekilde aşağı inin; omuzlar kulaklara çıkmasın",
    "8-12 tekrar, 2-3 set",
    "Sallanarak veya kipping yapmadan kontrollü hareket edin",
    "Omuz ağrısında assisted versiyona geçin"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Pull-up') AND category = 'Back';

UPDATE public.exercises SET
  description = 'Bant veya makine desteğiyle yapılan pull-up. Çekme formunu öğrenmek için güvenli başlangıç hareketidir.',
  instructions = '[
    "Pull-up barına tutunun; bant ayağa veya makine ağırlığına bağlı olsun",
    "Omuz genişliğinde tutuş; kollar tam uzamış başlangıç",
    "Kürek kemiklerini aktive ederek yukarı çekilin",
    "Çene bar hizasına gelene kadar kontrollü kalkın",
    "Yavaşça ve kontrollü aşağı inin; tam asılı pozisyona dönün",
    "8-12 tekrar, 2-3 set; destek miktarını kademeli azaltın",
    "Omuzları kulaklara çekmeyin",
    "Ağrıda destek miktarını artırın veya tekrar sayısını azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Assisted Pull-up') AND category = 'Back';

UPDATE public.exercises SET
  description = 'Ek ağırlıkla yapılan ileri seviye pull-up. Maksimum sırt ve çekiş gücü geliştirmek için kullanılır.',
  instructions = '[
    "Ağırlık kemeri veya dambıl ile ek yük takın",
    "Pull-up barına omuz genişliğinde overhand tutunun",
    "Core sıkı; sallanmadan kürek kemiklerini sıkıştırarak yukarı çekilin",
    "Çeneyi barın üzerine getirin; üst noktada kısa duraklama",
    "Kontrollü iniş; kollar tam uzayana kadar inin",
    "5-8 tekrar, 2-3 set; form bozulursa ağırlığı azaltın",
    "Belden momentum almayın",
    "Dirsek veya omuz ağrısında ağırlığı kaldırın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Weighted Pull-up') AND category = 'Back';

-- ============================================
-- FAZ 1B — ÖNCELİK 1: OMUZ
-- ============================================

UPDATE public.exercises SET
  description = 'Ayakta barbell ile yapılan omuz pres hareketi. Ön ve orta deltoid ile triceps ve core kaslarını çalıştırır.',
  instructions = '[
    "Ayakta ayaklar kalça genişliğinde; barbell ön omuz/clavicle hizasında",
    "Overhand tutuş, omuz genişliğinde; dirsekler barın altında",
    "Core ve kalça sıkı; bel nötr, göğüs hafif yukarı",
    "Nefes vererek barı baş üstüne doğru itin; başın önünden geçsin",
    "Üst noktada dirsekleri tam kilitlemeyin",
    "Nefes alarak kontrollü şekilde omuz hizasına indirin",
    "6-10 tekrar, 2-4 set",
    "Belden geriye yaslanmayın; omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Overhead Press') AND category = 'Shoulders';

-- ============================================
-- FAZ 1A — ZATEN İYİ OLAN MAKİNE HAREKETLERİ (description iyileştirme)
-- ============================================

UPDATE public.exercises SET
  description = 'Göğüs pres makinesi ile kontrollü göğüs itiş hareketi. Başlangıç seviyesi için güvenli ve form odaklı bir göğüs egzersizidir.',
  instructions = '[
    "Makine oturuşunu ve kol/koltuk ayarını göğüs hizasına gelecek şekilde yapın",
    "Sırtınızı mindere yaslayın, kürek kemiklerinizi hafifçe geriye alın",
    "Tutacakları kavrayın, bilekleri nötr pozisyonda tutun",
    "Nefes vererek tutacakları ileri itin; dirsekleri tamamen kilitlemeyin",
    "Nefes alarak kontrollü şekilde başlangıca dönün",
    "8-12 tekrar, 2-3 set; ağırlığı form bozulmayacak seviyede seçin",
    "Omuzları kulaklara çekmeyin; beli minderden ayırmayın",
    "Omuz veya göğüs ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Chest Press Machine') AND category = 'Chest';

UPDATE public.exercises SET
  description = 'Ön bacak (quadriceps) odaklı leg extension makinesi hareketi. Quadriceps izolasyonu için etkili ve kontrollü bir makine egzersizidir.',
  instructions = '[
    "Makine oturuşunu ayarlayın; diz eklemi dönme noktasına hizalansın",
    "Ayak bileği pedini alt kaval kemiğine gelecek şekilde yerleştirin",
    "Sırtınızı mindere yaslayın, core sıkı",
    "Nefes vererek dizinizi açıp ağırlığı yukarı kaldırın; dizleri kilitlemeyin",
    "Üst noktada 1 saniye quadriceps sıkıştırın",
    "Nefes alarak kontrollü şekilde aşağı indirin",
    "10-15 tekrar, 2-3 set; momentumla savurmayın",
    "Diz ağrısında açıklığı veya ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Leg Extension') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'Arka bacak (hamstring) odaklı leg curl makinesi hareketi. Hamstring güçlendirme ve diz arkası kas dengesi için kullanılır.',
  instructions = '[
    "Makine tipine göre ayarlayın (seated/lying); diz eklemi dönme noktasına hizalansın",
    "Pedleri topuk/ayak bileği hizasına yerleştirin",
    "Kalçayı ve gövdeyi sabitleyin; bel boşluğunu aşırı artırmayın",
    "Nefes vererek dizinizi büküp ağırlığı kontrollü çekin",
    "Alt noktada 1 saniye hamstring sıkıştırın",
    "Nefes alarak kontrollü şekilde başlangıca dönün",
    "10-15 tekrar, 2-3 set; hareketi belden değil dizden üretin",
    "Bel veya diz ağrısında hareketi durdurun"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Leg Curl Machine') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'Biceps kaslarını izole etmeye yardımcı olan kol curl makinesi hareketi. Dirsek sabitliği sayesinde form kontrolü kolaydır.',
  instructions = '[
    "Makine oturuşunu ayarlayın; dirsek eklemi makinenin dönme noktasına hizalansın",
    "Üst kol pedlere sabit; omuzları yukarı çekmeden nötr tutun",
    "Tutacakları kavrayın ve nefes vererek dirsekten bükerek yukarı kıvırın",
    "Üst noktada 1 saniye biceps sıkıştırın",
    "Nefes alarak kontrollü şekilde aşağı indirin; eklemi zorlamayın",
    "10-15 tekrar, 2-3 set; gövdeyi sallamayın",
    "Dirsekleri pedden kaldırmayın",
    "Dirsek ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Arm Curl Machine') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Omuz yan deltoid odaklı makine ile lateral raise hareketi. Yan omuz kaslarını kontrollü şekilde hedefler.',
  instructions = '[
    "Makinede oturuş ve kol pedlerini omuz hizasına gelecek şekilde ayarlayın",
    "Göğsünüz dik, core sıkı; omuzları yukarı çekmeden nötr tutun",
    "Pedleri/kolu yanlara doğru kaldırın; dirsekler hafif bükülü",
    "Üst noktada 1 saniye sıkıştırın",
    "Kontrollü şekilde başlangıca indirin",
    "10-15 tekrar, 2-3 set; hareketi sallanarak değil omuzla yapın",
    "Ağırlığı fazla seçip trapeze kaymayın",
    "Omuz ağrısında açıklığı veya ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Lateral Raise Machine') AND category = 'Shoulders';

-- ============================================
-- FAZ 1C — ÖNCELİK 2: GÖĞÜS
-- ============================================

UPDATE public.exercises SET
  description = 'Vücut ağırlığı ile yapılan temel göğüs egzersizi. Triceps ve ön omuz kaslarını da çalıştırır; her yerde yapılabilir.',
  instructions = '[
    "Yüz üstü yatın; eller omuz genişliğinde, parmaklar hafif dışa",
    "Vücut baştan topuklara düz bir çizgi oluştursun; core sıkı",
    "Nefes alarak göğse yakın kontrollü inin; dirsekler ~45° açıda",
    "Nefes vererek kolları tam uzatmadan yukarı itin",
    "10-15 tekrar, 2-3 set",
    "Kalça düşmemeli; bel çökmemeli",
    "Bilek ağrısında el pozisyonunu ayarlayın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Push-up (Şınav)') AND category = 'Chest';

UPDATE public.exercises SET
  description = 'Dumbbell ile yapılan göğüs pres hareketi. Her kol bağımsız çalışır; denge ve stabilite geliştirir.',
  instructions = '[
    "Düz bench''e sırt üstü yatın; ayaklar yerde sabit",
    "Dumbbellları göğüs hizasında tutun; avuç içleri öne baksın",
    "Kürek kemiklerini sıkıştırın; dirsekler hafif açılı",
    "Nefes vererek dumbbellları yukarı itin; üstte hafifçe yaklaşsınlar",
    "Nefes alarak kontrollü şekilde göğüs hizasına indirin",
    "8-12 tekrar, 2-3 set",
    "Dirsekleri tam kilitlemeyin; omuzları benchten kaldırmayın",
    "Omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Dumbbell Chest Press') AND category = 'Chest';

UPDATE public.exercises SET
  description = 'Eller yüksekte olan eğimli şınav varyasyonu. Klasik şınava göre daha kolaydır; göğüs formu öğrenmek için idealdir.',
  instructions = '[
    "Ellerinizi bench, duvar veya stabil yüksek yüzeye omuz genişliğinde yerleştirin",
    "Vücudu düz tutun; ayaklar geride, core sıkı",
    "Nefes alarak göğse yakın kontrollü inin",
    "Nefes vererek başlangıç pozisyonuna itin",
    "10-15 tekrar, 2-3 set",
    "Kalça sarkmasın; boyun nötr kalsın",
    "Bilek rahatsızlığında el açısını değiştirin"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Incline Push-up') AND category = 'Chest';

UPDATE public.exercises SET
  description = 'Dumbbell ile göğüs açma (fly) hareketi. Göğüs kaslarında gerilme ve sıkıştırma odaklı izolasyon egzersizidir.',
  instructions = '[
    "Düz bench''e sırt üstü yatın; dumbbelllar göğüs üzerinde, hafif bükük dirsek",
    "Kolları yanlara kontrollü açın; dirsek açısı sabit kalsın",
    "Göğüs hizasında hafif gerilme hissedin; omuzları zorlamayın",
    "Göğüs kaslarını sıkıştırarak dumbbellları yukarı birleştirin",
    "10-12 tekrar, 2-3 set",
    "Ağırlığı fazla seçip omuz eklemini zorlamayın",
    "Omuz ağrısında açıklığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Dumbbell Flyes') AND category = 'Chest';

UPDATE public.exercises SET
  description = 'Eğimli bench''te dumbbell pres hareketi. Üst göğüs ve ön omuz kaslarını öncelikli çalıştırır.',
  instructions = '[
    "30-45° eğimli bench''e sırt üstü yatın; ayaklar sabit",
    "Dumbbellları omuz hizasında tutun; kürek kemikleri sıkı",
    "Nefes vererek yukarı itin; dumbbelllar üstte yaklaşabilir",
    "Nefes alarak kontrollü şekilde göğüs hizasına indirin",
    "8-12 tekrar, 2-3 set",
    "Beli benchten kaldırmayın",
    "Omuz ağrısında eğimi veya ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Incline Dumbbell Press') AND category = 'Chest';

UPDATE public.exercises SET
  description = 'Decline açılı bench''te barbell pres. Alt göğüs kaslarını hedefleyen ileri seviye itiş hareketidir.',
  instructions = '[
    "Decline bench''e güvenli şekilde yatın; ayaklar sabitlensin",
    "Barbell''i göğüs alt hizasında kavrayın; bilekler düz",
    "Kürek kemiklerini sıkıştırın; göğüs yukarıda",
    "Nefes alarak kontrollü indirin; dirsekler kontrollü açılsın",
    "Nefes vererek yukarı itin; dirsekleri tam kilitlemeyin",
    "5-8 tekrar, 2-3 set; spotter önerilir",
    "Baş dönmesi veya omuz ağrısında hareketi durdurun"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Decline Bench Press') AND category = 'Chest';

UPDATE public.exercises SET
  description = 'Kablo makinesi ile göğüs crossover hareketi. Göğüs kaslarında sürekli gerilme ve sıkıştırma sağlar.',
  instructions = '[
    "Kablo makinesinin ortasında durun; kollar yanlarda, hafif bükük",
    "Bir adım öne atarak dengeyi sağlayın; core sıkı",
    "Kolları yay şeklinde öne ve aşağı doğru birleştirin",
    "Göğüs kaslarını sıkıştırın; üst noktada 1 saniye bekleyin",
    "Kontrollü şekilde başlangıca dönün",
    "10-12 tekrar, 2-3 set",
    "Omuzları öne çekmeyin; ağırlığı kademeli artırın",
    "Omuz ağrısında açıklığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Cable Crossover') AND category = 'Chest';

UPDATE public.exercises SET
  description = 'Ek ağırlıkla yapılan dip hareketi. Göğüs altı, triceps ve ön omuz kaslarını güçlendirir.',
  instructions = '[
    "Dip barına tutunun; gövde hafif öne eğik (göğüs vurgusu için)",
    "Ağırlık kemeri takılı olsun; core sıkı",
    "Nefes alarak kontrollü aşağı inin; dirsekler ~90° bükülsün",
    "Nefes vererek güçlü şekilde yukarı itin",
    "6-10 tekrar, 2-3 set",
    "Omuzları kulaklara çekmeyin",
    "Omuz ağrısında ağırlığı kaldırın veya hareket açıklığını azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Weighted Dips') AND category = 'Chest';

-- ============================================
-- FAZ 1C — ÖNCELİK 2: SIRT
-- ============================================

UPDATE public.exercises SET
  description = 'Tek kol dumbbell row hareketi. Orta sırt ve lat kaslarını çalıştıran temel çekiş egzersizidir.',
  instructions = '[
    "Bir el ve diz bench''e; diğer ayak yerde, sırt nötr",
    "Dumbbell''ı serbest elde tutun; kol tam uzamış",
    "Kürek kemiğini sıkıştırarak dumbbell''ı kalça hizasına çekin",
    "Üst noktada 1 saniye sıkıştırın; dirsek vücuda yakın",
    "Kontrollü şekilde aşağı indirin",
    "10-12 tekrar her kol, 2-3 set",
    "Beli yuvarlamayın; gövdeyi döndürerek çekmeyin",
    "Bel ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Dumbbell Row') AND category = 'Back';

UPDATE public.exercises SET
  description = 'Lat pulldown makinesi ile sırt çekme hareketi. Lat genişliği ve çekiş gücü geliştirmek için temel makine egzersizidir.',
  instructions = '[
    "Lat pulldown makinesine oturun; uyluk pedleri sıkı",
    "Barı omuz genişliğinden biraz geniş overhand kavrayın",
    "Göğsü yukarıda tutun; hafif geriye yaslanın",
    "Kürek kemiklerini aşağı çekerek barı üst göğüs/çene hizasına indirin",
    "Kontrollü şekilde kolları tam uzatmadan yukarı bırakın",
    "10-15 tekrar, 2-3 set",
    "Barı boyun arkasına çekmeyin",
    "Omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Lat Pulldown') AND category = 'Back';

UPDATE public.exercises SET
  description = 'T-bar row makinesi ile yatay çekme hareketi. Orta sırt kalınlığı ve çekiş kuvveti için etkilidir.',
  instructions = '[
    "T-bar makinesine oturun veya ayakta pozisyon alın; göğüs pedine yaslanın",
    "Tutuşu kavrayın; sırt nötr, core sıkı",
    "Kürek kemiklerini sıkıştırarak barı göğüs alt hizasına çekin",
    "Üst noktada 1 saniye sıkıştırın",
    "Kontrollü şekilde başlangıca indirin",
    "8-12 tekrar, 2-3 set",
    "Belden momentum almayın",
    "Bel ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('T-Bar Row') AND category = 'Back';

UPDATE public.exercises SET
  description = 'Tek kol dumbbell row''un ileri seviye versiyonu. Tek taraflı sırt gücü ve denge geliştirir.',
  instructions = '[
    "Bir el ve diz bench''e; sırt yere paralel, nötr",
    "Tek dumbbell ile kürek kemiğini sıkıştırarak yukarı çekin",
    "Dirseği vücuda yakın tutun; üstte maksimum sıkıştırma",
    "Kontrollü iniş; kol tam uzasın",
    "8-10 tekrar her kol, 2-3 set",
    "Gövdeyi döndürmeyin; beli yuvarlamayın",
    "Bel ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('One-Arm Dumbbell Row') AND category = 'Back';

UPDATE public.exercises SET
  description = 'Kablo ile oturarak yapılan sıra çekme hareketi. Orta sırt ve lat kaslarında kontrollü çekiş sağlar.',
  instructions = '[
    "Kablo row makinesine oturun; ayaklar platformda veya yerde sabit",
    "Dizler hafif bükük; göğüs yukarıda, sırt nötr",
    "Tutuşu kavrayın; kollar önde tam uzamış",
    "Kürek kemiklerini sıkıştırarak tutuşu göğüs alt hizasına çekin",
    "Kontrollü şekilde başlangıca dönün",
    "8-12 tekrar, 2-3 set",
    "Belden momentum almayın",
    "Bel ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Cable Row') AND category = 'Back';

-- ============================================
-- FAZ 1C — ÖNCELİK 2: BACAK (kalan)
-- ============================================

UPDATE public.exercises SET
  description = 'Leg press makinesi ile bacak pres hareketi. Squat alternatifi olarak quadriceps ve kalça kaslarını güçlendirir.',
  instructions = '[
    "Leg press makinesine oturun; sırt ve baş mindere yaslı",
    "Ayakları platforma omuz genişliğinde yerleştirin",
    "Güvenlik mandallarını kontrol edin; core sıkı",
    "Nefes alarak kontrollü şekilde aşağı inin; dizler ~90° bükülsün",
    "Nefes vererek platformu itin; dizleri tam kilitlemeyin",
    "12-15 tekrar, 2-3 set",
    "Beli minderden ayırmayın; dizleri içe çöktürmeyin",
    "Diz ağrısında açıklığı veya ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Leg Press') AND category = 'Legs';

UPDATE public.exercises SET
  description = 'Hack squat makinesi ile quadriceps odaklı squat hareketi. Arka destek sayesinde kontrollü bacak çalışması sağlar.',
  instructions = '[
    "Hack squat makinesine girin; omuzlar yastıklara yerleşsin",
    "Ayaklar platformda omuz genişliğinde; sırt pede yaslı",
    "Güvenlik kontrolü yapın; core sıkı",
    "Nefes alarak kontrollü çömelin; dizler ayak parmaklarıyla hizalı",
    "Nefes vererek yukarı itin; dizleri tam kilitlemeyin",
    "8-12 tekrar, 2-3 set",
    "Dizleri içe çöktürmeyin",
    "Diz veya bel ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Hack Squat') AND category = 'Legs';

-- ============================================
-- FAZ 1D — ÖNCELİK 3: KOL
-- ============================================

UPDATE public.exercises SET
  description = 'Dumbbell ile yapılan klasik biceps curl. Ön kol kaslarını izole şekilde güçlendirir.',
  instructions = '[
    "Ayakta dik durun; dumbbelllar yanlarda, avuç içleri öne",
    "Dirsekler vücuda yakın ve sabit; omuzlar gevşek",
    "Nefes vererek dumbbellları omuz hizasına kıvırın",
    "Üst noktada 1 saniye biceps sıkıştırın",
    "Nefes alarak kontrollü şekilde indirin",
    "10-15 tekrar, 2-3 set",
    "Gövdeyi sallamayın; dirsekleri öne itmeyin",
    "Dirsek ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Dumbbell Bicep Curl') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Bench üzerinde yapılan yardımlı triceps dip. Triceps güçlendirme için başlangıç seviyesi harekettir.',
  instructions = '[
    "Bench kenarına ellerinizi omuz genişliğinde yerleştirin",
    "Bacaklar önde uzatılmış veya ayakta (zorluk ayarı)",
    "Nefes alarak dirsekleri bükerek kalçayı aşağı indirin",
    "Nefes vererek kolları düzleştirerek yukarı itin",
    "10-12 tekrar, 2-3 set",
    "Omuzları kulaklara çekmeyin",
    "Omuz ağrısında hareket açıklığını azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Tricep Dips (Assisted)') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Nötr tutuşla yapılan çekiç curl hareketi. Biceps ve ön kol (brachialis) kaslarını çalıştırır.',
  instructions = '[
    "Ayakta dik; dumbbelllar yanlarda, avuç içleri birbirine baksın",
    "Dirsekler sabit; omuzlar nötr",
    "Nefes vererek dumbbellları omuz hizasına kıvırın",
    "Kontrollü iniş; tam bırakmadan tekrarlayın",
    "10-15 tekrar, 2-3 set",
    "Gövdeyi sallamayın",
    "Dirsek ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Hammer Curl') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Barbell ile yapılan biceps curl. Her iki kolun birlikte çalıştığı klasik biceps hareketidir.',
  instructions = '[
    "Ayakta dik; barbell overhand/underhand omuz genişliğinde",
    "Dirsekler vücuda yakın sabit",
    "Nefes vererek barı göğüs alt hizasına kıvırın",
    "Nefes alarak kontrollü indirin",
    "8-12 tekrar, 2-3 set",
    "Belden momentum almayın",
    "Dirsek ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Barbell Bicep Curl') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Dar tutuş bench press ile triceps odaklı itiş hareketi. Triceps kuvveti ve kilitlenme gücü geliştirir.',
  instructions = '[
    "Düz bench''e sırt üstü yatın; ayaklar sabit",
    "Eller omuz genişliğinden dar, bar göğüs hizasında",
    "Dirsekler vücuda yakın; nefes alarak kontrollü indirin",
    "Nefes vererek yukarı itin; dirsekleri tam kilitlemeyin",
    "8-12 tekrar, 2-3 set",
    "Bilekleri nötr tutun",
    "Dirsek veya bilek ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Close-Grip Bench Press') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Kablo ile yapılan biceps curl. Kas üzerinde sürekli gerilme sağlar.',
  instructions = '[
    "Kablo makinesinin önünde durun; bar veya tutuş alçakta",
    "Dirsekler vücuda sabit; göğüs dik",
    "Nefes vererek tutuşu omuz hizasına kıvırın",
    "Üst noktada biceps sıkıştırın",
    "Kontrollü iniş",
    "10-12 tekrar, 2-3 set",
    "Dirsekleri öne kaçırmayın",
    "Dirsek ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Cable Bicep Curl') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Preacher bench''te yapılan biceps curl. Dirsek sabitliği ile biceps izolasyonu sağlar.',
  instructions = '[
    "Preacher bench''e oturun; üst kollar yastığa tam yaslı",
    "Barbell veya EZ bar''ı omuz genişliğinde kavrayın",
    "Nefes vererek kontrollü kıvırın",
    "Üst noktada sıkıştırın; dirsekleri yastıktan kaldırmayın",
    "Nefes alarak yavaşça indirin",
    "6-10 tekrar, 2-3 set",
    "Alt noktada dirseği zorlamayın",
    "Dirsek ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Preacher Curl') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Ek ağırlıkla yapılan triceps dip hareketi. Triceps, göğüs ve omuz kaslarında maksimum yük oluşturur.',
  instructions = '[
    "Ağırlık kemeri takın; dip barına tutunun",
    "Gövde dik veya hafif öne (triceps vurgusu)",
    "Nefes alarak kontrollü aşağı inin",
    "Nefes vererek güçlü şekilde yukarı itin",
    "6-10 tekrar, 2-3 set",
    "Omuzları kulaklara çekmeyin",
    "Omuz ağrısında ağırlığı kaldırın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Weighted Dips') AND category = 'Arms';

UPDATE public.exercises SET
  description = 'Kablo ile triceps extension (pushdown) hareketi. Triceps izolasyonu için en yaygın egzersizlerden biridir.',
  instructions = '[
    "Kablo makinesinin önünde durun; rope veya bar üstte",
    "Dirsekler vücuda sabit; üst kollar hareketsiz",
    "Nefes vererek tutuşu aşağı doğru itin; kolları tam uzatın",
    "Alt noktada triceps sıkıştırın",
    "Kontrollü şekilde başlangıca dönün",
    "10-12 tekrar, 2-3 set",
    "Dirsekleri öne itmeyin",
    "Dirsek ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Cable Tricep Extension') AND category = 'Arms';

-- ============================================
-- FAZ 1D — ÖNCELİK 3: OMUZ
-- ============================================

UPDATE public.exercises SET
  description = 'Oturarak veya ayakta dumbbell omuz pres hareketi. Deltoid ve triceps kaslarını güçlendirir.',
  instructions = '[
    "Oturun veya ayakta; dumbbelllar omuz hizasında, avuç içleri öne",
    "Core sıkı; bel nötr",
    "Nefes vererek dumbbellları baş üstüne doğru itin",
    "Üstte dumbbelllar yaklaşabilir; dirsekleri tam kilitlemeyin",
    "Nefes alarak kontrollü omuz hizasına indirin",
    "10-12 tekrar, 2-3 set",
    "Belden geriye yaslanmayın",
    "Omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Dumbbell Shoulder Press') AND category = 'Shoulders';

UPDATE public.exercises SET
  description = 'Yan dumbbell kaldırma hareketi. Orta deltoid (yan omuz) kaslarını izole eder.',
  instructions = '[
    "Ayakta dik; dumbbelllar yanlarda, avuç içleri vücuda",
    "Dirsekler hafif bükük; omuzlar gevşek",
    "Kolları yanlara omuz hizasına kadar kaldırın",
    "Üst noktada 1 saniye bekleyin",
    "Kontrollü şekilde indirin",
    "10-15 tekrar, 2-3 set",
    "Ağırlığı fazla seçip trapeze kaymayın",
    "Omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Lateral Raises') AND category = 'Shoulders';

UPDATE public.exercises SET
  description = 'Ön dumbbell kaldırma hareketi. Ön deltoid kaslarını hedefler.',
  instructions = '[
    "Ayakta dik; dumbbelllar önde, avuç içleri arkaya",
    "Dirsekler hafif bükük; core sıkı",
    "Kolları öne omuz hizasına kadar kaldırın",
    "Kontrollü şekilde indirin",
    "10-15 tekrar, 2-3 set",
    "Belden momentum almayın",
    "Omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Front Raises') AND category = 'Shoulders';

UPDATE public.exercises SET
  description = 'Oturarak barbell omuz pres hareketi. Omuz ve triceps kuvveti geliştirmek için temel harekettir.',
  instructions = '[
    "Bench''e sırt destekli oturun; barbell omuz hizasında",
    "Overhand tutuş omuz genişliğinde",
    "Nefes vererek barı baş üstüne itin",
    "Nefes alarak kontrollü omuz hizasına indirin",
    "8-12 tekrar, 2-3 set",
    "Beli benchten ayırmayın",
    "Omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Barbell Shoulder Press') AND category = 'Shoulders';

UPDATE public.exercises SET
  description = 'Rotasyonlu dumbbell omuz pres (Arnold Press). Tüm deltoid başlarını çalıştıran çok yönlü omuz hareketidir.',
  instructions = '[
    "Oturun; dumbbelllar önde, avuç içleri size baksın, dirsekler bükük",
    "Pres yaparken avuç içlerini döndürerek yukarı itin",
    "Üstte avuç içleri öne baksın",
    "Ters rotasyonla kontrollü indirin",
    "8-12 tekrar, 2-3 set",
    "Belden momentum almayın",
    "Omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Arnold Press') AND category = 'Shoulders';

UPDATE public.exercises SET
  description = 'Barbell upright row hareketi. Orta deltoid ve trapezius kaslarını çalıştırır.',
  instructions = '[
    "Ayakta dik; barbell overhand dar tutuş, önde",
    "Dirsekleri yukarı ve dışa doğru çekerek barı çene altına getirin",
    "Üst noktada 1 saniye bekleyin",
    "Kontrollü şekilde indirin",
    "8-12 tekrar, 2-3 set",
    "Barı çene hizasından yukarı çekmeyin (omuz sıkışması riski)",
    "Omuz ağrısında hareketi durdurun"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Upright Row') AND category = 'Shoulders';

UPDATE public.exercises SET
  description = 'Ters V pozisyonunda yapılan şınav varyasyonu. Omuz ve triceps kaslarını vücut ağırlığı ile çalıştırır.',
  instructions = '[
    "Kalça yukarıda ters V pozisyonu alın; eller omuz genişliğinde",
    "Baş ve gövde kollar arasında; core sıkı",
    "Nefes alarak başı yere doğru kontrollü indirin",
    "Nefes vererek başlangıç pozisyonuna itin",
    "8-12 tekrar, 2-3 set",
    "Boynu zorlamayın",
    "Omuz ağrısında ayakları daha yakına alın (daha kolay açı)"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Pike Push-up') AND category = 'Shoulders';

UPDATE public.exercises SET
  description = 'Kablo face pull hareketi. Arka omuz, rotator cuff ve üst sırt kaslarını güçlendirir; omuz sağlığı için önerilir.',
  instructions = '[
    "Kablo makinesinde rope üst seviyede; geri adım atın",
    "Kollar uzatılmış; göğüs yukarıda",
    "Dirsekleri yukarı ve dışa çekerek rope''u yüz hizasına getirin",
    "Dış rotasyon yapın; kürek kemiklerini sıkıştırın",
    "Kontrollü şekilde başlangıca dönün",
    "12-15 tekrar, 2-3 set",
    "Belden momentum almayın",
    "Omuz ağrısında ağırlığı azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Face Pull') AND category = 'Shoulders';

-- ============================================
-- FAZ 1E — ÖNCELİK 4: CORE
-- ============================================

UPDATE public.exercises SET
  description = 'Dirsek üzerinde sabit duruş ile core güçlendirme. Karın, bel ve stabilizasyon kaslarını çalıştırır.',
  instructions = '[
    "Dirsekler omuz altında, ön kollar paralel veya eller birleşik",
    "Vücut baştan topuklara düz çizgi; kalça ne çok yukarı ne çok aşağı",
    "Core ve kalça sıkı; nefes düzenli",
    "Pozisyonu 30-60 saniye tutun",
    "2-3 set; süreyi kademeli artırın",
    "Bel çökmesine izin vermeyin",
    "Bel ağrısında dizler yerde moduna geçin"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Plank') AND category = 'Core';

UPDATE public.exercises SET
  description = 'Klasik mekik hareketi. Üst karın kaslarını (rectus abdominis) hedefler.',
  instructions = '[
    "Sırt üstü yatın; dizler bükük, ayaklar yerde",
    "Eller başın arkasında veya göğüste; boyun nötr",
    "Karın kaslarını sıkarak omuzları yerden kaldırın",
    "Üst noktada 1 saniye sıkın",
    "Kontrollü şekilde indirin",
    "15-20 tekrar, 2-3 set",
    "Boyundan çekmeyin",
    "Bel ağrısında hareket açıklığını azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Crunches') AND category = 'Core';

UPDATE public.exercises SET
  description = 'Sırt üstü bacak kaldırma hareketi. Alt karın kaslarını güçlendirir.',
  instructions = '[
    "Sırt üstü yatın; bacaklar düz veya hafif bükük",
    "Eller yanlarda veya kalça altında destek",
    "Karın sıkı; bacakları yukarı kaldırın",
    "Kontrollü şekilde yere yaklaştırın; beli yerden kaldırmayın",
    "10-15 tekrar, 2-3 set",
    "Belden momentum almayın",
    "Bel ağrısında dizleri bükerek yapın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Leg Raises') AND category = 'Core';

UPDATE public.exercises SET
  description = 'Oturarak yapılan gövde rotasyonu. Oblique (yan karın) kaslarını çalıştırır.',
  instructions = '[
    "Yerde oturun; dizler bükük, ayaklar yerde veya havada",
    "Göğüs yukarıda; eller birleşik veya ağırlık tutun",
    "Gövdeyi sağa ve sola kontrollü döndürün",
    "Her taraf 20-30 tekrar, 2-3 set",
    "Belden değil göğüs bölgesinden dönün",
    "Bel ağrısında ağırlığı kaldırın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Russian Twists') AND category = 'Core';

UPDATE public.exercises SET
  description = 'Plank pozisyonunda dizleri göğse çekme hareketi. Core, kalça ve kardiyo bileşenli dinamik egzersizdir.',
  instructions = '[
    "Plank pozisyonu alın; eller omuz altında, vücut düz",
    "Bir dizinizi göğse doğru hızlı ama kontrollü çekin",
    "Alternatif bacakla devam edin",
    "20-30 tekrar (her bacak), 2-3 set",
    "Kalça çok yukarı kalkmasın",
    "Bilek ağrısında yavaş tempo uygulayın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Mountain Climbers') AND category = 'Core';

UPDATE public.exercises SET
  description = 'Dead bug hareketi. Core stabilizasyonu ve bel-kalça koordinasyonu geliştirmek için güvenli egzersizdir.',
  instructions = '[
    "Sırt üstü yatın; kollar tavana, dizler 90° bükük",
    "Bel yere bastırılmış; core sıkı",
    "Karşı kol ve bacağı aynı anda yere doğru uzatın",
    "Başlangıca dönün; diğer taraf",
    "10-12 tekrar her taraf, 2-3 set",
    "Bel boşluğu oluşursa hareket açıklığını azaltın",
    "Bel ağrısında sadece bacak veya kol hareketi yapın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Dead Bug') AND category = 'Core';

UPDATE public.exercises SET
  description = 'Asılı pozisyonda bacak kaldırma. Alt karın ve kalça fleksörlerini ileri seviye çalıştırır.',
  instructions = '[
    "Pull-up barına asılın; kollar tam uzamış",
    "Core sıkı; sallanmadan bacakları yukarı kaldırın",
    "Dizleri göğse çekebilir veya bacakları düz kaldırabilirsiniz",
    "Kontrollü şekilde aşağı indirin",
    "10-15 tekrar, 2-3 set",
    "Belden momentum almayın",
    "Bel ağrısında dizleri bükerek yapın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Hanging Leg Raises') AND category = 'Core';

UPDATE public.exercises SET
  description = 'İleri seviye core hareketi. Tüm karın zincirinde maksimum kontrol ve güç gerektirir.',
  instructions = '[
    "Bench''e sırt üstü yatın; eller başın arkasında bench''i kavrasın",
    "Bacaklar ve gövde birlikte düz kalksın; sadece üst sırt bench''te kalsın",
    "Kontrollü şekilde yavaşça indirin",
    "5-8 tekrar, 2-3 set",
    "Boyundan çekmeyin; beli zorlamayın",
    "Bel ağrısında hareketi durdurun"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Dragon Flag') AND category = 'Core';

UPDATE public.exercises SET
  description = 'Ab wheel ile öne yuvarlanma hareketi. Karın, bel ve omuz stabilizasyonunu birlikte çalıştırır.',
  instructions = '[
    "Dizler yerde ab wheel tutun; core sıkı",
    "Kontrollü şekilde öne yuvarlanın; bel çökmesin",
    "Maksimum güvenli açıklığa ulaşın",
    "Karın kaslarını kullanarak geri dönün",
    "8-12 tekrar, 2-3 set",
    "Bel çökerse açıklığı azaltın",
    "Bel ağrısında hareketi durdurun"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Ab Wheel Rollout') AND category = 'Core';

-- ============================================
-- FAZ 1E — ÖNCELİK 4: KARDİYO
-- ============================================

UPDATE public.exercises SET
  description = 'Düşük yoğunluklu tempolu yürüyüş. Kardiyovasküler sağlık ve yağ yakımı için güvenli başlangıç aktivitesidir.',
  instructions = '[
    "Rahat ayakkabı ve düz zemin seçin",
    "Dik duruş; omuzlar gevşek, kollar doğal sallansın",
    "Konuşabileceğiniz tempoda yürüyün (nefes nefese kalmayın)",
    "20-30 dakika sürdürün",
    "Isınma ve soğuma için ilk/son 3-5 dk yavaş tempo",
    "Nabzınızı takip edin",
    "Eklem ağrısında tempoyu veya süreyi azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Yürüyüş') AND category = 'Cardio';

UPDATE public.exercises SET
  description = 'Zıplayarak kolları açıp kapatan tam vücut kardiyo hareketi. Isınma ve kondisyon için kullanılır.',
  instructions = '[
    "Ayakta dik; ayaklar birleşik",
    "Hafifçe çömelip zıplayın; kolları yana ve yukarı açın",
    "İnişte yumuşak dizler; ayaklar birleşsin",
    "30-50 tekrar veya 30-60 saniye",
    "2-3 set",
    "Diz ağrısında adım adım (step) versiyon yapın",
    "Kalp rahatsızlığında doktor onayı alın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Jumping Jacks') AND category = 'Cardio';

UPDATE public.exercises SET
  description = 'Sabit bisiklet ile düşük etkili kardiyo. Diz dostu bir dayanıklılık egzersizidir.',
  instructions = '[
    "Sele yüksekliğini ayarlayın; diz hafif bükükte pedal en altta",
    "Rahat tempo ile pedal çevirin",
    "20-30 dakika; konuşabileceğiniz yoğunlukta",
    "Nabzınızı takip edin",
    "Isınma ve soğuma dahil edin",
    "Diz ağrısında direnci veya süreyi azaltın",
    "Baş dönmesinde durun"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Stationary Bike') AND category = 'Cardio';

UPDATE public.exercises SET
  description = 'Orta tempolu koşu. Kardiyovasküler dayanıklılık ve bacak kuvveti geliştirir.',
  instructions = '[
    "Isınma için 5 dakika tempolu yürüyüş",
    "Konuşabileceğiniz tempoda koşun",
    "20-30 dakika sürdürün",
    "Nefes ritmini koruyun; omuzlar gevşek",
    "Soğuma için 5 dakika yürüyüş",
    "Hızı kademeli artırın",
    "Eklem ağrısında tempoyu veya süreyi azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Koşu') AND category = 'Cardio';

UPDATE public.exercises SET
  description = 'Tam vücut kardiyo hareketi. Güç, dayanıklılık ve koordinasyonu birlikte geliştirir.',
  instructions = '[
    "Ayakta başlayın; çömelip elleri yere koyun",
    "Bacakları geriye atarak plank pozisyonuna geçin",
    "İsteğe bağlı bir şınav yapın",
    "Bacakları geri çekip çömelin ve yukarı zıplayın",
    "10-15 tekrar, 2-3 set",
    "Her fazda kontrollü hareket edin",
    "Diz veya bel ağrısında şınavı atlayın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Burpees') AND category = 'Cardio';

UPDATE public.exercises SET
  description = 'Yerinde yüksek diz kaldırma. Nabzı hızla yükselten kısa süreli kardiyo hareketidir.',
  instructions = '[
    "Ayakta dik; core sıkı",
    "Dizleri göğüs hizasına hızlı ama kontrollü çekin",
    "Kollar doğal ritimde sallansın",
    "30-60 saniye, 2-3 set",
    "Ayak parmaklarında hafif kalabilirsiniz",
    "Diz ağrısında tempo yavaşlatın",
    "Nefes nefese kalırsanız dinlenin"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('High Knees') AND category = 'Cardio';

UPDATE public.exercises SET
  description = 'Yüksek yoğunluklu aralıklı koşu (HIIT). Kondisyon ve yağ yakımı için ileri seviye kardiyo protokolüdür.',
  instructions = '[
    "5 dakika ısınma yürüyüşü/koşusu",
    "30 saniye maksimum hızda koşun",
    "60 saniye yürüyerek toparlanın",
    "5-8 tur tekrarlayın",
    "Toplam 15-20 dakika; soğuma ekleyin",
    "Başlangıçta tur sayısını azaltın",
    "Kalp rahatsızlığında doktor onayı alın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Sprint Intervals') AND category = 'Cardio';

UPDATE public.exercises SET
  description = 'Kutu veya platforma zıplama hareketi. Patlayıcı güç ve kardiyo bileşenli plyometrik egzersizdir.',
  instructions = '[
    "Sağlam kutu veya platform önünde durun; ayaklar kalça genişliğinde",
    "Dizleri büküp kolları sallayarak yukarı zıplayın",
    "Her iki ayak kutuya yumuşak iniş; dizler bükük",
    "Geri adım veya geri zıplayarak inin",
    "10-15 tekrar, 2-3 set",
    "Kutu yüksekliğini formunuza göre ayarlayın",
    "Diz ağrısında kutu yüksekliğini azaltın veya atlayın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Box Jumps') AND category = 'Cardio';

UPDATE public.exercises SET
  description = 'Kürek çekme makinesi ile tam vücut kardiyo. Bacak, sırt ve kol kaslarını koordineli çalıştırır.',
  instructions = '[
    "Makineye oturun; ayaklar pedallara sabit, dizler hafif bükük",
    "Tutuşu kavrayın; sırt düz, core sıkı",
    "Bacaklarla iterek başlayın; ardından kollarla çekişi tamamlayın",
    "Geri dönüşte kollar önce, bacaklar sonra",
    "20-30 dakika; düzenli tempo",
    "Beli yuvarlamayın",
    "Bel ağrısında süreyi veya direnci azaltın"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Rowing Machine') AND category = 'Cardio';

-- ============================================
-- FAZ 1F — SMITH MACHINE (ekipman tanıma)
-- ============================================

UPDATE public.exercises SET
  description = 'Smith machine (sabit raylı bar) üzerinde güvenlik kilitleri ile yapılan çok amaçlı ekipman. Bu sayfa ekipmanın genel kullanımını ve yaygın varyasyonlarını içerir.',
  instructions = '[
    "Bar yüksekliğini ayarlayın; güvenlik stoplarını (safety) doğru seviyeye getirin",
    "Barı kavrayın; barı döndürerek kilidi açın ve başlangıç pozisyonunu alın",
    "Hareketi kontrollü eksende yapın; eklemleri kilitlemeyin",
    "Nefes: kaldırma/itme fazında nefes verin, inişte nefes alın",
    "Tekrar bitince barı yukarı getirip döndürerek kilitleyin",
    "Varyasyonlar: Squat, Incline Press, Shoulder Press, RDL, Calf Raise, Hip Thrust",
    "Barı raydan çıkarmayın; ağırlığı form bozulmayacak seviyede seçin",
    "Omuz, bel veya diz ağrısında hareketi durdurun"
  ]'::jsonb,
  updated_at = NOW()
WHERE lower(name) = lower('Smith Machine') AND category = 'Equipment';

COMMIT;
