# Envanter

Evindeki her seyin faturasi, garantisi ve bakim tarihi tek yerde.

> Bu klasor, ana repodaki Unity oyunundan **bagimsiz** bir Flutter
> uygulamasidir. Kendi reposuna tasinmasi planlaniyor.

## Durum

Çalışır durumda:

- Yerel SQLite veritabanı (odalar, eşyalar, belgeler, bakım kayıtları)
- Alt menülü kabuk: Odalar · Arama · Ekle · Garanti · Ayarlar
- Oda filtresi, oda özeti (eşya sayısı + tahmini değer), sıralama
- Eşya ekleme / düzenleme / silme, kameradan veya galeriden fotoğraf
- Eşya detayı: garanti geri sayımı, ilerleme çubuğu, künye, seri no kopyalama
- Garanti & bakım takvimi: acil olanlar ve garantisi güvende olanlar
- Arama: ad, marka, model, seri no, satıcı, not
- Ayarlar: oda yönetimi
- "Warm Haven" tasarım sistemi (Stitch), Plus Jakarta Sans, açık + koyu tema

- **Bildirimler**: garanti bitişinden 30 gün, 7 gün önce ve bitiş günü
  saat 10.00'da yerel bildirim. Ayarlardan açılır, izin istenir, envanter
  değiştikçe kendini yeniler, telefon yeniden başlatılsa da kaybolmaz.

Henüz yok:

- Fatura fotoğrafından yapay zekâ ile alan doldurma
- PDF / CSV dışa aktarma (sigorta için)
- Belge ve bakım kaydı arayüzü (veri katmanı hazır, ekranları yok)

Bilinen sınır: arama SQLite `LIKE` kullanıyor; büyük/küçük harf eşleşmesi
yalnızca ASCII harflerde çalışır ("İ" ile "i" eşleşmez). Düzeltmesi
normalize edilmiş bir arama alanı eklemek.

## Mimari

```
lib/
├── domain/      saf Dart, Flutter bağımlılığı yok -> birim testli
├── data/        modeller, SQLite, veri kaynağı arayüzü, store
├── ui/          ekranlar ve widget'lar
├── theme/       tasarım sistemi (renk, tipografi, bileşen stilleri)
└── util/        Türkçe tarih / para / büyük harf
```

**Veri cihazda kalır.** Hesap yok, sunucu yok, bulut yok. Fotoğraflar
uygulamanın belge klasöründe; veritabanında mutlak yol değil *göreli* yol
tutulur (iOS her güncellemede mutlak yolu değiştirir).

Veri kaynağı (`InventoryDataSource`) ve fotoğraf deposu (`PhotoStore`) arayüz
arkasında: uygulamada SQLite ve dosya sistemi, testlerde bellek içi
uygulamaları kullanılır. Bu sayede bütün ekranlar cihaz olmadan test edilir.

Türkçe büyük harf `turkishUpper()` ile yapılır: Dart'ın `toUpperCase()`'i
yerelden bağımsızdır ve 'i' harfini 'I'ya çevirir ("KÜNYESI").

## Calistirma

```bash
flutter pub get
flutter run
```

## Doğrulama

```bash
flutter analyze   # statik analiz
flutter test      # birim testleri + ekran görüntüsü karşılaştırması
```

### Ekran görüntüleri

Cihaz veya emülatör olmadan arayüzü görmek için:

```bash
flutter test --update-goldens test/screenshots_test.dart
```

`test/goldens/` altına her ekranın PNG'si düşer. Bu dosyalar aynı zamanda
görsel regresyon testidir: tasarımı bozan bir değişiklik `flutter test`
sırasında fark edilir.
