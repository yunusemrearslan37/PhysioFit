# Supabase Veritabanı Kurulum Rehberi

## 📋 Adımlar

### 1. Supabase Projesi Oluşturma

1. https://supabase.com adresine gidin
2. "Start your project" ile kayıt olun veya giriş yapın
3. "New Project" butonuna tıklayın
4. Proje bilgilerini doldurun:
   - **Name**: `fitness-app` (veya istediğiniz isim)
   - **Database Password**: Güçlü bir şifre belirleyin (kaydedin!)
   - **Region**: En yakın bölgeyi seçin (örn: `West Europe`)
5. Proje oluşturulana kadar bekleyin (2-3 dakika)

### 2. Veritabanı Şemasını Oluşturma

1. Supabase Dashboard'da **SQL Editor** sekmesine gidin
2. **New Query** butonuna tıklayın
3. `database/supabase_schema.sql` dosyasının içeriğini kopyalayıp yapıştırın
4. **Run** butonuna tıklayın
5. Başarılı mesajını görmelisiniz

### 3. Storage Bucket'larını Oluşturma

1. Supabase Dashboard'da **Storage** sekmesine gidin
2. **Create bucket** butonuna tıklayın

#### Bucket 1: `equipment-images`
- **Name**: `equipment-images`
- **Public bucket**: ✅ Evet
- **File size limit**: 5 MB
- **Allowed MIME types**: `image/jpeg, image/png, image/webp`

#### Bucket 2: `exercise-animations`
- **Name**: `exercise-animations`
- **Public bucket**: ✅ Evet
- **File size limit**: 10 MB
- **Allowed MIME types**: `application/json, image/gif`

#### Bucket 3: `user-uploads`
- **Name**: `user-uploads`
- **Public bucket**: ❌ Hayır (kullanıcılar sadece kendi dosyalarını görebilir)
- **File size limit**: 5 MB

### 4. API Bilgilerini Alma

1. Supabase Dashboard'da **Settings** > **API** sekmesine gidin
2. Şu bilgileri kopyalayın:
   - **Project URL** (örn: `https://xxxxx.supabase.co`)
   - **anon public key** (uzun bir string)

### 5. Flutter Projesine Bilgileri Ekleme

1. `lib/config/supabase_secrets.example.dart` dosyasını `lib/config/supabase_secrets.dart` adıyla kopyalayın
2. `url` alanına Project URL'i yazın
3. `anonKey` alanına anon public key'i yazın

`supabase_secrets.dart` Git tarafından yok sayılır. Anahtarları `supabase_config.dart` içine yazmayın.

### 6. Paketleri Yükleme

Terminal'de şu komutu çalıştırın:

```bash
flutter pub get
```

### 7. Test Etme

Uygulamayı çalıştırın:

```bash
flutter run
```

Eğer "Supabase Bağlantısı Başarılı!" mesajını görüyorsanız, kurulum tamamlanmıştır! ✅

## 🔒 Güvenlik Notları

- `anon key` public olabilir, ancak RLS (Row Level Security) politikaları verilerinizi korur
- Kullanıcılar sadece kendi verilerini görebilir
- Storage bucket'larında da güvenlik politikaları ayarlanmıştır

## 📚 Sonraki Adımlar

1. Authentication ekranlarını oluşturun
2. Egzersiz listesi ekranını oluşturun
3. Kamera modülünü entegre edin
4. Öneri motorunu geliştirin

## 🆘 Sorun Giderme

### Hata: "Invalid API key"
- Supabase URL ve key'lerin doğru kopyalandığından emin olun
- Dashboard'dan tekrar kopyalayın

### Hata: "relation does not exist"
- SQL şemasını çalıştırdığınızdan emin olun
- SQL Editor'de tabloların oluşturulduğunu kontrol edin

### Hata: "permission denied"
- RLS politikalarının doğru ayarlandığından emin olun
- Kullanıcının giriş yaptığından emin olun

## 📞 Yardım

Sorun yaşarsanız:
1. Supabase Dashboard'da **Logs** sekmesini kontrol edin
2. Flutter console'da hata mesajlarını kontrol edin
3. Supabase dokümantasyonunu inceleyin: https://supabase.com/docs

