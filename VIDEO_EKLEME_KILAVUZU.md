# Video Ekleme Kılavuzu

## 🎯 Hızlı Başlangıç

Yeni bir video eklemek için 3 adım:

### 1️⃣ Egzersiz Bilgilerini Öğrenin

Supabase'de veya uygulamada egzersizin:
- **Adı**: Örn: "Bench Press"
- **Kategorisi**: Örn: "Chest"

### 2️⃣ Dosya Adını Oluşturun

Sistem otomatik olarak egzersiz adından dosya adı oluşturur:

**Kurallar:**
- Boşluklar → `_` (alt çizgi)
- Özel karakterler kaldırılır: `(`, `)`, `'`, `-`
- "Dumbbell" → "Dumbell" (tek 'b')
- "Shoulder" kelimesi kaldırılır

**Örnekler:**
- "Bench Press" → `Bench_Press.mp4`
- "Push-up (Şınav)" → `Push_Up.mp4`
- "Dumbbell Shoulder Press" → `Dumbell_Press.mp4`
- "Lateral Raises" → `Lateral_Raises.mp4`
- "Incline Push-up" → `Incline_Push_Up.mp4`

### 3️⃣ Dosyayı Yerleştirin

Video dosyasını şu iki yerden birine koyun:

**Seçenek A: Doğrudan videos klasörüne (Önerilen)**
```
assets/videos/Bench_Press.mp4
```

**Seçenek B: Kategori klasörüne**
```
assets/videos/chest/Bench_Press.mp4
```

**Kategori klasör adları (küçük harf):**
- `chest` - Göğüs
- `shoulders` - Omuz
- `back` - Sırt
- `arms` - Kol
- `legs` - Bacak
- `core` - Karın
- `cardio` - Kardiyovasküler

### 4️⃣ Uygulamayı Yeniden Derleyin

```bash
flutter clean
flutter run
```

**ÖNEMLİ:** Yeni dosya ekledikten sonra mutlaka uygulamayı yeniden derleyin!

## 📝 Örnek Senaryo

**Egzersiz:** "Barbell Shoulder Press"  
**Kategori:** "Shoulders"

**Adımlar:**
1. Dosya adı: `Barbell_Press.mp4` (sistem otomatik oluşturur)
2. Dosyayı kaydedin: `Barbell_Press.mp4`
3. Yerleştirin: `assets/videos/shoulders/Barbell_Press.mp4` veya `assets/videos/Barbell_Press.mp4`
4. Uygulamayı yeniden derleyin
5. ✅ Video görünecek!

## 🔍 Dosya Adını Test Etmek

Eğer dosya adının doğru olup olmadığından emin değilseniz:

1. Uygulamayı çalıştırın
2. Console log'larını kontrol edin (VS Code terminal)
3. Şu log'ları arayın:
   ```
   Egzersiz: [Egzersiz Adı], Kategori: [Kategori]
   Oluşturulan dosya adı: [Dosya Adı]
   Seçilen asset path: assets/videos/[Dosya Adı].mp4
   ```

Bu log'lar hangi dosya adının arandığını gösterir. Dosyanızı bu adla kaydedin.

## ⚠️ Sorun Giderme

### Video Görünmüyor?

1. **Dosya adını kontrol edin**
   - Console log'larında "Oluşturulan dosya adı" ile gerçek dosya adını karşılaştırın
   - Büyük/küçük harf uyumunu kontrol edin

2. **Dosya yerleşimini kontrol edin**
   - Dosya `assets/videos/` klasöründe mi?
   - Kategori klasörü kullanıyorsanız, klasör adı küçük harf mi?

3. **Uygulamayı yeniden derleyin**
   - `flutter clean` yapın
   - `flutter run` ile yeniden başlatın

4. **pubspec.yaml kontrolü**
   - `assets/videos/` tanımlı mı? (Zaten tanımlı ✅)

## 💡 İpucu

Eğer dosya adı eşleşmiyorsa, console log'larındaki "Seçilen asset path" değerini kullanarak dosyanızı yeniden adlandırın.

