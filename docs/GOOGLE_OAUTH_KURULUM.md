# Google OAuth Kurulum Rehberi

> **Not:** `YOUR_PROJECT_REF` yerine kendi Supabase proje kimliğinizi yazın (Dashboard → Settings → API → Project URL). Gerçek proje URL’leri bu repoda saklanmaz.

## 🔴 Hata: "Unsupported provider: provider is not enabled"

Bu hata, Supabase Dashboard'da Google OAuth provider'ının etkinleştirilmediğini gösterir. Aşağıdaki adımları takip ederek Google ile giriş özelliğini etkinleştirebilirsiniz.

## 📋 Adım 1: Google Cloud Console'da OAuth 2.0 Client ID Oluşturma

1. [Google Cloud Console](https://console.cloud.google.com/) adresine gidin
2. Yeni bir proje oluşturun veya mevcut bir projeyi seçin
3. Sol menüden **APIs & Services** > **Credentials** sekmesine gidin
4. Üstteki **+ CREATE CREDENTIALS** butonuna tıklayın
5. **OAuth client ID** seçeneğini seçin
6. Eğer OAuth consent screen yapılandırılmamışsa, önce onu yapılandırmanız istenecek:
   - **User Type**: External seçin
   - **App name**: PhysioFit (veya istediğiniz isim)
   - **User support email**: E-posta adresinizi seçin
   - **Developer contact information**: E-posta adresinizi girin
   - **Save and Continue** butonuna tıklayın
   - Scopes sayfasında **Save and Continue** butonuna tıklayın
   - Test users sayfasında **Save and Continue** butonuna tıklayın
   - Summary sayfasında **Back to Dashboard** butonuna tıklayın

7. OAuth client ID oluşturma ekranında:
   - **Application type**: Web application seçin
   - **Name**: PhysioFit OAuth (veya istediğiniz isim)
   - `YOUR_PROJECT_REF`: Supabase Dashboard → **Settings** → **API** → Project URL içindeki alt alan adı (ör. `https://xxxxx.supabase.co` → `xxxxx`)
   - **Authorized redirect URIs** bölümüne şunu ekleyin:
     ```
     https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
     ```
   - **CREATE** butonuna tıklayın

8. Oluşturulan **Client ID** ve **Client Secret** değerlerini kopyalayın (bunları Supabase'e ekleyeceksiniz)

## 📋 Adım 2: Supabase Dashboard'da Google Provider'ı Etkinleştirme

1. [Supabase Dashboard](https://app.supabase.com/) adresine gidin
2. Projenizi seçin
3. Sol menüden **Authentication** > **Providers** sekmesine gidin
4. **Google** provider'ını bulun ve üzerine tıklayın
5. **Enable Google provider** toggle'ını açın
6. Google Cloud Console'dan kopyaladığınız bilgileri girin:
   - **Client ID (for OAuth)**: Google Cloud Console'dan aldığınız Client ID
   - **Client Secret (for OAuth)**: Google Cloud Console'dan aldığınız Client Secret
7. **Save** butonuna tıklayın

## 📋 Adım 3: Redirect URL Yapılandırması

1. Supabase Dashboard'da **Authentication** > **URL Configuration** sekmesine gidin
2. **Redirect URLs** bölümüne şu URL'leri ekleyin:
   ```
   com.example.bitirme_proje://
   com.example.bitirme_proje://login-callback
   ```
   **ÖNEMLİ:** Her iki URL'yi de ekleyin (biri scheme, diğeri tam path)
3. **Site URL** bölümünde şu URL'nin olduğundan emin olun:
   ```
   com.example.bitirme_proje://
   ```
4. **Save** butonuna tıklayın

## ✅ Test Etme

1. Uygulamayı yeniden başlatın
2. Login ekranında Google ikonuna tıklayın
3. Google hesabınızla giriş yapın
4. Başarılı bir şekilde ana sayfaya yönlendirilmelisiniz

## 🔧 Sorun Giderme

### Hata: "redirect_uri_mismatch"
- Google Cloud Console'da **Authorized redirect URIs** bölümüne doğru URL'yi eklediğinizden emin olun:
  ```
  https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
  ```

### Hata: "invalid_client"
- Supabase Dashboard'da girdiğiniz **Client ID** ve **Client Secret** değerlerinin doğru olduğundan emin olun
- Google Cloud Console'dan yeni bir Client ID oluşturup tekrar deneyin

### Hata: "provider is not enabled"
- Supabase Dashboard'da Google provider'ının **Enable** toggle'ının açık olduğundan emin olun
- Sayfayı yenileyip tekrar kontrol edin

### Hata: "localhost:3000" sayfasında kalma / "ERR_CONNECTION_REFUSED"
- Supabase Dashboard'da **Authentication** > **URL Configuration** sekmesine gidin
- **Redirect URLs** bölümüne `com.example.bitirme_proje://` URL'sinin eklendiğinden emin olun
- **Site URL** bölümüne de `com.example.bitirme_proje://` ekleyin
- Uygulamayı tamamen kapatıp yeniden açın
- Eğer sorun devam ederse, Supabase Dashboard'da **Authentication** > **Providers** > **Google** sekmesinde **Redirect URL** alanını kontrol edin

### Hata: "500 - unexpected_failure" / Sunucu Hatası
Bu hata genellikle Supabase Dashboard'da yapılandırma sorunlarından kaynaklanır:

1. **Google Provider Ayarlarını Kontrol Edin:**
   - Supabase Dashboard > **Authentication** > **Providers** > **Google**
   - **Enable Google provider** toggle'ının açık olduğundan emin olun
   - **Client ID** ve **Client Secret** değerlerinin doğru girildiğinden emin olun
   - **Save** butonuna tıklayın

2. **Redirect URL'leri Kontrol Edin:**
   - Supabase Dashboard > **Authentication** > **URL Configuration**
   - **Redirect URLs** bölümünde şu URL'lerin olduğundan emin olun:
     - `com.example.bitirme_proje://`
     - `com.example.bitirme_proje://login-callback`
   - **Site URL** bölümünde: `com.example.bitirme_proje://`
   - **Save** butonuna tıklayın

3. **Google Cloud Console'u Kontrol Edin:**
   - Google Cloud Console > **APIs & Services** > **Credentials**
   - OAuth 2.0 Client ID'nizin **Authorized redirect URIs** bölümünde şu URL'nin olduğundan emin olun:
     - `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`

4. **Supabase Projesini Yeniden Başlatın:**
   - Bazen Supabase projesini duraklatıp tekrar başlatmak sorunları çözebilir
   - Supabase Dashboard > **Settings** > **General** > **Pause Project** / **Restore Project**

5. **Logları Kontrol Edin:**
   - Supabase Dashboard > **Logs** > **Postgres Logs** veya **API Logs**
   - Hata detaylarını buradan görebilirsiniz

## 📝 Notlar

- Google OAuth için OAuth consent screen'i production'a almadan önce test modunda çalışacaktır
- Production'da kullanmak için OAuth consent screen'i Google tarafından onaylanmalıdır
- Test aşamasında sadece eklediğiniz test kullanıcıları Google ile giriş yapabilir

