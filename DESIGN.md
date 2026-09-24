# Kural Deliği — Oyun Tasarım Dokümanı (GDD)

> Sürüm: 0.1 (Aşama 0 taslağı) · Son güncelleme: 2026-09-24

---

## 1. Özet

**Kural Deliği**, yetişkinlere yönelik bir hyper-casual beyin + refleks oyunudur.
Oyuncu zeminde tek parmağıyla bir **delik** sürükler. Her bölümün başında ekranda
tek bir **KURAL** belirir (örn. *"Sadece asal sayıları yut"*). Zeminde duran
nesnelerden kurala **uyanları** yutmak, uymayanlardan **kaçınmak** gerekir.

Oyunun çekirdek gerilimi: *bilgi* (kuralı doğru anlamak) + *refleks* (süre baskısı)
+ *öz denetim* (yanlış nesneye dokunmamak).

**Reklam hook'u:** "Sadece asal sayıları yutabilir misin?" — izleyen kişi kendini
test etmek ister. Hedef kitle: 18+ yetişkinler. Çocuklara yönelik değildir
(Google Play "Designed for Families" kapsamı dışında konumlanır).

**Tek cümlelik pitch:** *hole.io'nun mekaniği + bir zekâ testinin içeriği.*

---

## 2. Çekirdek döngü

```
Bölüm başlar → KURAL kartı 2 sn ekranda → geri sayım → oynanış (30–60 sn)
   ├── Doğru nesne yutuldu  → delik büyür, combo +1, puan, para, "pop" efekti
   └── Yanlış nesne yutuldu → delik küçülür, combo sıfırlanır, can -1,
                              ekran sarsıntısı + haptic + kırmızı flash
→ Hedefe ulaşıldı  → KAZANDIN (1–3 yıldız) → ödüller → sonraki bölüm
→ 3 can bitti / süre doldu → KAYBETTİN → tekrar dene / rewarded ad ile ekstra can
```

### 2.1 Kazanma ve kaybetme koşulları
| Durum | Koşul |
|---|---|
| Kazanma | Süre dolmadan `targetCorrect` adet doğru nesneyi yutmak |
| Kaybetme (can) | 3 yanlış nesne yutmak (upgrade ile 4–5) |
| Kaybetme (süre) | Süre dolduğunda hedefe ulaşılmamış olmak |

Süre dolduğunda zeminde kalan yanlış nesneler **ceza değildir** ve bonus da vermez.
Oyuncu istemediği nesneyi yutmamakla zaten ödüllendirilmiştir. **(Karar verildi.)**

### 2.2 Yıldız sistemi
| Yıldız | Koşul |
|---|---|
| ★ | Bölümü tamamla |
| ★★ | En fazla 1 hata **ve** sürenin en az %25'i kalmış |
| ★★★ | Hatasız **ve** hedefin en az %125'i kadar doğru yutulmuş |

Yıldızlar toplanır; dünya kilitlerini açar.

### 2.3 Puan ve para
```
nesnePuanı  = temelPuan (10) × comboÇarpanı
comboÇarpanı = 1 + min(combo, 10) × 0.2      → 1.0 … 3.0
bölümParası = floor(toplamPuan / 10) + yıldız × 5
```
Tüm katsayılar Inspector'dan ayarlanır (`EconomyConfig` ScriptableObject).

---

## 3. Delik mekaniği

- **Arena:** ekrandan **büyük, kaydırmalı** bir zemin (varsayılan ~1.8× ekran alanı,
  `LevelSpec.arenaSize` ile bölüm başına ayarlanır). Kamera deliği yumuşak
  damping ile takip eder ve arena sınırlarına clamp'lenir → kenarda boşluk görünmez.
  Keşif hissi ve daha fazla nesne kapasitesi sağlar.
- **Kural her zaman ekranda:** kamera hareket ettiği için kural kartı kaybolmaz;
  bölüm başındaki büyük kart 2 sn sonra ekranın üstündeki **kalıcı ince şeride**
  (safe-area altına sabitlenmiş, yarı saydam) küçülerek yerleşir. Oyuncu kuralı
  her an okuyabilir → kaydırmalı haritanın tek gerçek riski (planlama zorluğu)
  ortadan kalkar.
- **Yön ipucu:** ekran dışındaki nesne yoğunluğu için kenarlarda küçük ok
  göstergeleri (Aşama 4). Minimap kullanılmaz — portrait ekranda yer kaplar.
- **Kontrol:** tek parmak sürükleme. Parmak konumu ekran→zemin düzlemi
  raycast'i ile dünya konumuna çevrilir; delik bu hedefe `Lerp` ile yumuşak
  takip eder (ani sıçrama yok, düşük FPS'te bile akıcı).
- **Delik görseli:** zeminin hemen üstünde duran koyu disk mesh'i + kenar halkası.
  (Gerçek stencil/shader delik efekti Aşama 6'da opsiyonel iyileştirme.)
- **Yutma:** **fizik kullanılmaz.** Her karede, delik merkezine olan yatay uzaklığı
  `holeRadius × swallowFactor` (varsayılan 0.75) altına düşen nesne "yutuluyor"
  olarak işaretlenir ve bir tween başlar: merkeze doğru kayma + aşağı düşme +
  `scale → 0` (0.25 sn). Tween bitince nesne havuza geri döner.
  Bu yaklaşım **deterministik**tir, fizik motoru tutarsızlıklarına bağlı değildir
  ve düşük donanımda bedavaya gelir.
- **Boyut değişimi:**
  ```
  doğru   → radius += growPerCorrect (0.06), max holeMaxRadius
  yanlış  → radius -= shrinkPerWrong (0.10), min holeMinRadius
  ```
  Yarıçap değişimi 0.2 sn'lik ease-out tween ile animasyonlanır.
- **İki delik bölümleri:** ikinci delik ilk deliğin aynası olarak hareket eder
  (X ekseninde yansıma). Tek parmakla iki delik yönetmek, kural takibini zorlaştırır.

---

## 4. İçerik: konu paketleri

Her paket bir **etiket (tag) uzayı** tanımlar. Kurallar etiketler üzerinde çalışır.

### 4.1 Sayılar (`numbers`)
Nesneler üretim anında hesaplanır (JSON'da saklanmaz).
Etiketler: `number`, `even`/`odd`, `prime`/`composite`, `multipleOf3`, `multipleOf5`,
`multipleOf4`, `square`, `twoDigit`, `singleDigit`. Sayısal alan: `value`.

Örnek kurallar: *tek/çift*, *asal*, *3'ün katı*, *50'den büyük*, *tam kare*,
*"sonucu 10 olanlar"* (metin `7+3`, `value=10`, etiket `expression`).

> **Not:** 1 ne asal ne bileşiktir; 2 tek asaldır. Üreteç bunları doğru işler
> ve asal kurallarında yanıltıcı olarak 1'i özellikle kullanır.

### 4.2 İngilizce kelimeler (`english`)
Etiketler: `english`, `word`, `animal`, `food`, `furniture`, `vehicle`, `color`,
`verb`, `adjective`, `noun`, `body`, `nature`.
Ek alanlar: `props.tr` (Türkçe karşılık), `props.antonym`.

Örnek kurallar: *sadece hayvanlar*, *Türkçesi "elma" olan*, *"big"in zıttı*,
*sadece fiiller*.

### 4.3 Coğrafya (`geography`)
Etiketler: `country`, `capital`, `continent.europe/asia/africa/...`,
`neighborOfTurkey`, `city`, `flagColor.red/white/...`.
Bayrak görseli **kullanılmaz**; ülke adı + renk blokları ile soru sorulur.

> **Doğruluk notu:** Türkiye'nin kara komşuları tam olarak 8'dir: Yunanistan,
> Bulgaristan, Gürcistan, Ermenistan, Azerbaycan (Nahçıvan), İran, Irak, Suriye.
> Kıta atamalarında sınır ülkeler (Rusya, Türkiye, Mısır, Kazakistan) veri
> tabanında **çift kıta etiketi** taşır ve "sadece Avrupa ülkeleri" tipi kurallarda
> havuzdan **çıkarılır** (`ambiguous` etiketi ile işaretlenir). Belirsiz içerik
> asla oyuncuyu cezalandırmaz.

### 4.4 Genel kültür (`trivia`)
Etiketler: `fruit`, `vegetable`, `mammal`, `bird`, `fish`, `reptile`, `insect`,
`planet`, `element`, `instrument`, `sport`.

> **Doğruluk notu:** domates/salatalık/biber botanik olarak meyvedir ama mutfak
> dilinde sebzedir → `ambiguous` etiketiyle havuz dışı. Yarasa memelidir,
> penguen kuştur, yunus memelidir — bunlar bilinçli "tuzak" olarak kullanılır
> ve doğru etiketlenir. Plüton gezegen **değildir** (`dwarfPlanet`), yanıltıcı
> olarak kullanılır.

### 4.5 Renk ve şekil (`colorshape`)
Etiketler: `color.red/blue/green/yellow/purple/orange/black/white`,
`shape.cube/sphere/cylinder/capsule`.
En kolay paket → **tutorial ve ilk bölümler** buradan gelir. Okuma gerektirmez,
dil bağımsızdır, reklam görselinde anında anlaşılır.

Örnek kurallar: *sadece kırmızılar*, *sadece küpler*, *kırmızı OLMAYAN küreler*.

---

## 5. Kural sistemi

Bir kural = **etiketler üzerinde çalışan bir predicate ağacı** + **gösterim metni**.

Düğüm tipleri: `tag`, `and`, `or`, `not`, `cmp` (sayısal karşılaştırma),
`between`, `prop` (özellik eşitliği), `always`.

Zorluk kademeleri:
1. **Tek koşul:** `tag(even)` → "Sadece ÇİFT sayıları yut"
2. **Olumsuzlama:** `not(tag(red))` → "Kırmızı OLMAYANLARI yut"
3. **Birleşik (AND):** `and(tag(multipleOf3), cmp(value < 20))` → "3'ün katı AMA 20'den küçük"
4. **Birleşik (OR):** `or(tag(prime), tag(square))` → "Asal VEYA tam kare"
5. **Karma:** `and(tag(sphere), not(tag(red)))` → "Kırmızı olmayan küreler"

Metinler daima lokalizasyon tablosundan gelir (`rule.even`, `rule.and` = `"{0} AMA {1}"`).

---

## 6. Bölüm yapısı, dünyalar, zorluk eğrisi

- İlk sürümde **200+ bölüm**; sistem sınırsız ölçeklenir (bölüm = `index` + `seed`).
- **20 bölümlük dünyalar.** Her dünyanın kendi renk paleti, ağırlıklı konu paketi
  ve arka plan tonu vardır.

| Dünya | Bölüm | Tema | Ağırlıklı paket |
|---|---|---|---|
| 1 | 1–20 | Başlangıç | colorshape (tutorial 1–3) |
| 2 | 21–40 | Sayı Vadisi | numbers (tek/çift/kat) |
| 3 | 41–60 | Kelime Şehri | english |
| 4 | 61–80 | Atlas | geography |
| 5 | 81–100 | Doğa | trivia |
| 6+ | 101+ | Karma dünyalar, artan zorluk | karışık |

### 6.1 Zorluk parametreleri (hepsi `DifficultyCurve` SO'da AnimationCurve)
`ruleComplexity` · `decoyRatio` (yanıltıcı oran) · `objectCount` · `timeLimit`
· `targetRatio` · `motionType` (static → drift → rotate → bounce)
· `midLevelSwitchChance` · `dualHoleChance`

### 6.2 Boss bölümleri
Her 10. bölüm (10, 20, 30…) **meydan okuma** bölümüdür: kural karmaşıklığı +1,
süre %25 kısa, yanıltıcı oranı yüksek, bölüm ortasında kural değişimi garantili.
Ödülü 2× paradır.

### 6.3 Tutorial (Bölüm 1–3, yazısız)
1. **Bölüm 1:** Sadece kırmızı küreler var, yanlış nesne yok. Parmağın konumunu
   gösteren animasyonlu el ikonu. Yutunca kutlama. *(Kaybedilemez.)*
2. **Bölüm 2:** Kırmızı + mavi küreler. Kural "sadece kırmızı". İlk yanlış yutmada
   yavaşlatılmış geri bildirim; can gitmez.
3. **Bölüm 3:** Şekil kuralı devreye girer, canlar normal çalışır.

---

## 7. Meta sistemler

- **Para (🪙):** bölüm sonunda kazanılır, upgrade ve skinlerde harcanır.
- **Upgrade'ler** (her biri 5 kademe, artan fiyat):
  | Upgrade | Etki |
  |---|---|
  | Başlangıç boyutu | +0.05 yarıçap / kademe |
  | Ekstra can | +1 can (max 2 kademe) |
  | Ekstra süre | +3 sn / kademe |
  | Combo koruması | İlk hatada combo sıfırlanmaz (tek kademe) |
- **Skinler:** delik rengi + kenar materyali (ilk sürümde 8 adet, sadece renk/materyal).
- **Günlük meydan okuma:** `seed = yyyyMMdd` → herkese aynı bölüm, günde 1 hak,
  2× para ödülü.
- **Reklamlar (`IAdService` — Aşama 6'da sadece arayüz):**
  - Interstitial: her 3 bölümde bir, bölüm sonu ekranında.
  - Rewarded: "Ekstra can al" (fail ekranı), "2× ödül" (win ekranı).
- **Ayarlar:** ses, müzik, titreşim (haptic), dil.

---

## 8. Görsel ve his (juice)

- **Stil:** temiz, modern, flat/low-poly. Primitive mesh'ler, `Unlit`/basit `Lit`
  materyaller, gölgesiz veya tek yönlü yumuşak gölge. Nesne üstünde TextMeshPro
  ile metin.
- **Kamera:** hafif perspektif, ~50° eğimli, portrait. Deliği `SmoothDamp` ile takip
  eder, arena sınırlarına clamp'lenir. Nesneler ekran dışındayken güncellenmez
  (basit culling) → maliyet sabit arenaya yakın kalır.
- **Juice listesi:** yutma pop'u + partikül, combo sayacı zıplaması, delik büyüme
  tween'i, hatada ekran sarsıntısı + kırmızı vinyet + haptic, kural kartı
  slide-in, süre son 5 sn'de nabız atışı, kazanma ekranında yıldız pat pat.
- **Ses:** ilk sürümde asset üretilmez; `IAudioService` üzerinden çağrılar hazır
  bırakılır.

---

## 9. Teknik hedefler

Unity 6 (6000.x LTS) · URP · C# · Android öncelikli · **portrait kilidi** ·
tek parmak · **60 FPS** hedefi · düşük donanım dostu (object pooling, GC
baskısı yok, materyal sayısı düşük, batch dostu).

---

## 10. Verilen kararlar (Aşama 0 onayı)

| # | Konu | Karar |
|---|---|---|
| 1 | Arena | **Kaydırmalı geniş harita**, kamera deliği takip eder; kural ekranın üstünde kalıcı ince şeritte hep görünür |
| 2 | Yanlış yutma cezası | **Can (−1) + delik küçülmesi + combo sıfırlanması**; 3 yanlışta bölüm biter |
| 3 | Enerji sistemi | **Yok** — sınırsız deneme; gelir reklam ve upgrade'lerden |
| 4 | Süre sonu | Kalan yanlış nesneler için **ne ceza ne bonus** |
| 5 | Başarısızlıkta ilerleme kaybı | Yok, sınırsız tekrar |

## 11. Kalan açık sorular

- Süre cezası (−3 sn) ileri dünyalarda ekstra zorluk parametresi olarak açılsın mı?
  (Şu anki plan: `DifficultySettings`'te kapalı bir seçenek olarak hazır dursun.)
