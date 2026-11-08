# Örnek Egzersizler - Kurulum Rehberi

## 📋 Açıklama

Bu dosya, her bölge (Göğüs, Sırt, Bacak, Kol, Omuz, Karın, Kardiyovasküler) ve her zorluk seviyesi (Başlangıç, Orta, İleri) için örnek antrenman programları içerir.

## 🎯 İçerik

### Her Bölge için 3 Zorluk Seviyesi:
- **Başlangıç (Beginner)**: 3 egzersiz
- **Orta (Intermediate)**: 3 egzersiz  
- **İleri (Advanced)**: 3 egzersiz

### Toplam:
- **7 Bölge** × **3 Seviye** × **3 Egzersiz** = **63 Egzersiz**

## 📝 Kurulum Adımları

### 1. Supabase Dashboard'a Gidin
- https://supabase.com/dashboard
- Projenizi seçin

### 2. SQL Editor'e Gidin
- Sol menüden **SQL Editor** sekmesine tıklayın
- **New Query** butonuna tıklayın

### 3. SQL Dosyasını Çalıştırın
- `database/sample_exercises.sql` dosyasını açın
- Tüm içeriği kopyalayın (Ctrl+A, Ctrl+C)
- SQL Editor'e yapıştırın (Ctrl+V)
- **Run** butonuna tıklayın (veya Ctrl+Enter)

### 4. Kontrol Edin
- Sol menüden **Table Editor** → **exercises** tablosuna gidin
- 63 egzersiz görünmeli

## ✅ Başarı Mesajı

Eğer başarılı olursanız şu mesajı görmelisiniz:
```
Success. No rows returned
```

## 🎨 Egzersiz Yapısı

Her egzersiz şu bilgileri içerir:
- **İsim**: Egzersiz adı
- **Açıklama**: Kısa açıklama
- **Kategori**: Bölge (Chest, Back, Legs, vb.)
- **Ekipman**: Gerekli ekipman türü
- **Zorluk**: Başlangıç, Orta, İleri
- **Kas Grupları**: Hedef kaslar
- **Talimatlar**: Adım adım nasıl yapılır

## 📊 Örnek Kullanım

Uygulamada:
1. **Egzersizler** ekranına gidin
2. Bir bölge seçin (örn: Göğüs)
3. Bir zorluk seviyesi seçin (Kolay, Orta, Zor)
4. O kategori ve seviyeye göre filtrelenmiş egzersizleri görün

## 🔄 Güncelleme

Daha fazla egzersiz eklemek için:
- SQL dosyasına yeni INSERT komutları ekleyin
- Supabase'de tekrar çalıştırın

## ⚠️ Notlar

- Aynı egzersizleri tekrar eklemek hata verebilir (UNIQUE constraint)
- Egzersizleri silmek için: `DELETE FROM exercises WHERE ...`
- Tüm egzersizleri silmek için: `DELETE FROM exercises;`

## 🆘 Sorun Giderme

### Hata: "duplicate key value"
- Egzersiz zaten var, normal bir durum
- Devam edebilirsiniz

### Hata: "relation does not exist"
- Önce `supabase_schema.sql` dosyasını çalıştırdığınızdan emin olun
- Tablolar oluşturulmuş olmalı

### Egzersizler görünmüyor
- Uygulamayı yeniden başlatın
- Veritabanı bağlantısını kontrol edin

