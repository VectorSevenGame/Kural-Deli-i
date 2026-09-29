# Envanter

Evindeki her seyin faturasi, garantisi ve bakim tarihi tek yerde.

> Bu klasor, ana repodaki Unity oyunundan **bagimsiz** bir Flutter
> uygulamasidir. Kendi reposuna tasinmasi planlaniyor.

## Durum: 1. hafta iskeleti

Calisir durumda olanlar:

- Yerel SQLite veritabani (odalar, esyalar, belgeler, bakim kayitlari)
- Oda oda esya listesi, garanti durumu rozetiyle
- Esya ekleme / duzenleme / silme, fotograf cekme veya galeriden secme
- Garanti hesabi ve durum siniflandirmasi (birim testli)
- Turkce arayuz, Material 3, acik + koyu tema

Henuz yok (2.-3. hafta):

- Fatura fotografindan AI ile alan doldurma
- Bildirimler (garanti bitisi, bakim zamani)
- Arama ekrani, PDF/CSV disa aktarma
- Belge ve bakim kaydi arayuzu (veri katmani hazir, ekranlari yok)

## Mimari

```
lib/
├── domain/      saf Dart, Flutter bagimliligi yok -> birim testli
├── data/        modeller, SQLite, repository, ChangeNotifier store
├── ui/          ekranlar ve widget'lar
├── theme/       Material 3 tokenlari
└── util/        Turkce tarih/para bicimlendirme
```

**Veri cihazda kalir.** Hesap yok, sunucu yok, bulut yok. Fotograflar
uygulamanin belge klasorunde; veritabaninda mutlak yol degil *goreli* yol
tutulur (iOS her guncellemede mutlak yolu degistirir).

## Calistirma

```bash
flutter pub get
flutter run
```

## Dogrulama

```bash
flutter analyze   # statik analiz
flutter test      # domain birim testleri
```
