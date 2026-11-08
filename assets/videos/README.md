# Egzersiz Videoları - Assets Klasörü

Bu klasörde egzersizlerin nasıl yapılacağını gösteren videolar bulunur.

## Klasör Yapısı

Videolar kategori klasörlerine göre organize edilmelidir:

```
assets/videos/
  ├── chest/          # Göğüs egzersizleri
  │   ├── Push_Up.mp4
  │   ├── Bench_Press.mp4
  │   └── ...
  ├── shoulders/      # Omuz egzersizleri
  │   ├── Dumbell_Press.mp4
  │   ├── Lateral_Raises.mp4
  │   └── ...
  ├── back/           # Sırt egzersizleri
  ├── arms/           # Kol egzersizleri
  ├── legs/           # Bacak egzersizleri
  ├── core/           # Karın egzersizleri
  └── cardio/         # Kardiyovasküler egzersizler
```

## Dosya Adlandırma Kuralları

1. **Kategori klasörleri**: Küçük harf kullanın (`shoulders`, `chest`, vb.)
2. **Dosya adları**: 
   - Boşluklar alt çizgi (`_`) ile değiştirilir
   - Özel karakterler kaldırılır (parantez, apostrof, vb.)
   - "Dumbbell" → "Dumbell" (tek 'b') olarak yazılır
   - "Shoulder" kelimesi genellikle kaldırılır (örn: "Dumbbell Shoulder Press" → "Dumbell_Press.mp4")

## Örnek Dönüşümler

| Egzersiz Adı (Veritabanı) | Dosya Adı |
|---------------------------|-----------|
| Dumbbell Shoulder Press | `shoulders/Dumbell_Press.mp4` |
| Push-up (Şınav) | `chest/Push_Up.mp4` |
| Bench Press | `chest/Bench_Press.mp4` |
| Lateral Raises | `shoulders/Lateral_Raises.mp4` |

## Video Formatı

- **Format**: MP4 (H.264 codec önerilir)
- **Çözünürlük**: 720p veya 1080p
- **Süre**: Kısa ve öz (10-30 saniye arası önerilir)
- **Boyut**: Mümkün olduğunca küçük tutun (5-10 MB arası)

## Notlar

- Video dosyaları uygulamanın boyutunu artırır, bu yüzden sadece gerekli videoları ekleyin
- Dosya adları büyük/küçük harf duyarlıdır
- Eğer bir video bulunamazsa, placeholder gösterilir

