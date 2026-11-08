# PhysioFit

Kullanıcının hedefine, vücut ölçülerine ve sakatlık kısıtlarına göre antrenman ve rehabilitasyon programı üreten Flutter mobil uygulaması.

## Özellikler

- E-posta ve Google ile giriş, şifre sıfırlama
- Kilo verme, kas yapma, fizyoterapi ve genel fitness hedeflerine göre program önerisi
- Egzersiz kütüphanesi, video anlatımlar ve günlük antrenman takibi
- Sakatlık analizi ve rehabilitasyon planı
- Güç kaydı grafikleri, kronometre ve kalori takibi
- Kameradan spor ekipmanı tanıma
- Kullanıcı bağlamını kullanan yapay zekâ koçu
- Antrenman hatırlatmaları ve push bildirimleri

## Teknolojiler

- **Mobil:** Flutter, Dart, Material 3
- **Backend:** Supabase, PostgreSQL, SQL, Row Level Security
- **API:** Supabase Edge Functions (Deno, TypeScript), REST
- **Kimlik:** Supabase Auth, Google OAuth, PKCE
- **Yapay zekâ:** Gemini, cihaz üzerinde TensorFlow Lite
- **Görüntü:** YOLO modelinin TensorFlow Lite formatında telefonda çalıştırılması
- **Bildirim:** Firebase Cloud Messaging, yerel bildirimler
- **Sürüm kontrolü:** Git

Ekipman tanıma modeli YOLO ile eğitilip `assets/models/best_integer_quant.tflite` olarak uygulamaya alınır. Çıkarım telefonda, `tflite_flutter` ile yapılır.

## Çalıştırma

```bash
flutter pub get
flutter run
```

Supabase adresi ve anon anahtar repoda yoktur. `lib/config/supabase_secrets.example.dart` dosyasını `lib/config/supabase_secrets.dart` adıyla kopyalayıp kendi proje bilgilerinizi yazın. Android bildirimleri için `android/app/google-services.json` dosyasını Firebase konsolundan indirip aynı konuma koyun. Bu iki dosya Git tarafından yok sayılır.

Veritabanı tabloları `database/supabase_schema.sql` ile oluşturulur. Ayrıntılı kurulum `README_SUPABASE.md` dosyasındadır.

`exercises` tablosunda Row Level Security şemada tanımlıdır. Canlı veritabanında daha önce açılmadıysa şu komutu SQL Editor'de bir kez çalıştırın:

```sql
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
```

## Proje yapısı

- `lib/screens` — ekranlar
- `lib/services` — kimlik, antrenman, kalori, yapay zekâ ve bildirim servisleri
- `lib/models` — veri modelleri
- `database` — SQL şeması
- `supabase/functions` — yapay zekâ koçu ve push bildirim fonksiyonları
- `assets/models` — TensorFlow Lite modeli ve sınıf etiketleri
