# E-posta Doğrulama Kurulum Rehberi

## 📧 Supabase Dashboard'da E-posta Doğrulama Etkinleştirme

Gerçek Gmail hesaplarının doğrulanması için Supabase'de e-posta doğrulama özelliğini etkinleştirmeniz gerekiyor.

### Adım 1: Authentication Ayarları

1. Supabase Dashboard'a giriş yapın
2. Sol menüden **Authentication** > **Settings** sekmesine gidin
3. **Email Auth** bölümünde:
   - ✅ **Enable email confirmations** seçeneğini işaretleyin
   - ✅ **Enable email change confirmations** seçeneğini işaretleyin (opsiyonel)

### Adım 2: E-posta Şablonunu Özelleştirme (Opsiyonel)

1. **Authentication** > **Email Templates** sekmesine gidin
2. **Confirm signup** şablonunu seçin
3. E-posta içeriğini Türkçe'ye çevirebilirsiniz:

**Subject (Konu):**
```
FitPhysio - E-posta Doğrula
```

**Body (İçerik):**
```
Merhaba,

FitPhysio hesabınızı oluşturmak için e-posta adresinizi doğrulamanız gerekiyor.

Doğrulama linkine tıklayın: {{ .ConfirmationURL }}

Eğer bu e-postayı siz istemediyseniz, lütfen görmezden gelin.

Teşekkürler,
FitPhysio Ekibi
```

### Adım 3: SMTP Ayarları (Önemli!)

Varsayılan olarak Supabase kendi SMTP sunucusunu kullanır, ancak daha güvenilir e-posta gönderimi için kendi SMTP sunucunuzu kullanabilirsiniz:

1. **Settings** > **Auth** > **SMTP Settings** sekmesine gidin
2. **Enable Custom SMTP** seçeneğini işaretleyin
3. SMTP bilgilerinizi girin (Gmail SMTP kullanabilirsiniz):
   - **Host**: `smtp.gmail.com`
   - **Port**: `587`
   - **Username**: Gmail adresiniz
   - **Password**: Gmail uygulama şifreniz (2FA aktifse)
   - **Sender email**: Gönderen e-posta adresi
   - **Sender name**: FitPhysio

**Not:** Gmail kullanıyorsanız, 2FA aktifse "Uygulama Şifresi" oluşturmanız gerekir:
1. Google Hesabınız > Güvenlik > 2 Adımlı Doğrulama
2. Uygulama şifreleri > Yeni uygulama şifresi oluştur
3. Oluşturulan şifreyi SMTP ayarlarına girin

### Adım 4: Test Etme

1. Uygulamada yeni bir kullanıcı kaydı oluşturun
2. Gmail hesabınızı kontrol edin
3. Doğrulama e-postasını bulun ve linke tıklayın
4. E-posta doğrulandıktan sonra uygulamada giriş yapabilmelisiniz

### Adım 5: E-posta Doğrulama Kontrolü

E-posta doğrulanmadan giriş yapılmaya çalışıldığında, uygulama otomatik olarak "E-posta adresinizi doğrulamanız gerekiyor" mesajını gösterecektir.

## 🔒 Güvenlik Notları

- E-posta doğrulama zorunlu tutulmalıdır (Enable email confirmations: ✅)
- Spam koruması için rate limiting ayarlarını kontrol edin
- E-posta şablonlarını özelleştirerek kullanıcı deneyimini iyileştirin

## 📝 SQL ile E-posta Doğrulama Zorunluluğu

Eğer SQL ile e-posta doğrulama zorunluluğunu ayarlamak isterseniz:

```sql
-- E-posta doğrulanmadan giriş yapılmasını engelle
-- Bu ayar Supabase Dashboard'dan yapılmalı, SQL ile doğrudan yapılamaz
-- Authentication > Settings > Email Auth > Enable email confirmations
```

## ⚠️ Önemli

- E-posta doğrulama etkinleştirildikten sonra, yeni kayıt olan kullanıcılar e-postalarını doğrulamadan giriş yapamazlar
- Mevcut kullanıcılar etkilenmez (sadece yeni kayıtlar için geçerlidir)
- E-posta gönderimi için Supabase'in ücretsiz planında günlük limit vardır (200 e-posta/gün)

