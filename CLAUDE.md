# CLAUDE.md — Kural Deliği proje kılavuzu

> Bu dosya her oturumun başında okunur. **Mimari, klasör yapısı, çalışma kuralları,
> yapılanlar ve sıradakiler** burada tutulur. Her aşama sonunda güncellenir.
> Oyun tasarımı ayrıntıları için `DESIGN.md`.

---

## 1. Proje künyesi

| | |
|---|---|
| Oyun | Kural Deliği (çalışma adı) |
| Motor | Unity 6 (6000.0.x LTS), URP |
| Dil | C# |
| Platform | Android öncelikli (portrait), iOS uyumlu |
| Hedef | 60 FPS, düşük donanım |
| UI dili | Türkçe (lokalizasyon tablosundan; ileride EN) |
| Branch | `claude/kural-deligi-game-4d0egb` |

---

## 2. Klasör yapısı

```
/
├── CLAUDE.md               ← bu dosya
├── DESIGN.md               ← oyun tasarım dokümanı
├── README.md               ← projeyi Unity'de açma adımları
├── .gitignore              ← Unity standart
├── Packages/manifest.json  ← URP, TMP, Input System, Test Framework
├── ProjectSettings/        ← ProjectVersion.txt + Unity'nin ürettikleri
└── Assets/_Game/
    ├── Content/            ← JSON içerik veritabanı (elle/AI ile düzenlenebilir)
    │   ├── objects.colorshape.json
    │   ├── objects.english.json
    │   ├── objects.geography.json
    │   ├── objects.trivia.json
    │   ├── rules.json
    │   ├── levels.handcrafted.json   ← override'lar
    │   └── loc.tr.json
    ├── Scripts/
    │   ├── Core/           ← SAF C# (asmdef: "No Engine References")
    │   │   ├── Content/    ← GameObjectDef, ContentDatabase, Tags
    │   │   ├── Rules/      ← Predicate ağacı, RuleSpec, RuleEvaluator
    │   │   ├── Levels/     ← LevelGenerator, LevelSpec, DifficultySettings
    │   │   ├── Save/       ← SaveData modelleri (POCO)
    │   │   └── Util/       ← DeterministicRandom, Json yardımcıları
    │   ├── Game/           ← MonoBehaviour'lar (asmdef → Core'a referans)
    │   │   ├── Hole/       ← HoleController, HoleInput, SwallowSystem
    │   │   ├── Level/      ← LevelRunner, ObjectSpawner, ObjectPool
    │   │   ├── Flow/       ← GameStateMachine, Boot/Menu/Playing/Win/Fail
    │   │   ├── UI/         ← HUD, RuleCard, WinPanel, FailPanel, Menüler
    │   │   ├── Services/   ← ISaveService, IAudioService, IAdService, IHaptics
    │   │   ├── Juice/      ← Tween (kendi yazdığımız), ScreenShake, VFX
    │   │   └── Config/     ← ScriptableObject'ler (palet, ekonomi, eğriler)
    │   └── Editor/         ← asmdef, Editor-only
    │       ├── SetupProjectTool.cs     ← Tools/KuralDeligi/Setup Project
    │       └── ValidateLevelsTool.cs   ← Tools/KuralDeligi/Validate Levels
    ├── Prefabs/  Materials/  Scenes/  Settings/
    └── Tests/EditMode/      ← Core'u test eder (asmdef)
```

**Assembly definition'lar:** `KuralDeligi.Core` (engine referansı yok) →
`KuralDeligi.Game` → `KuralDeligi.Editor` / `KuralDeligi.Tests.EditMode`.
Bu ayrım, kural değerlendirme ve bölüm üretiminin Unity olmadan test
edilebilmesini **garanti eder**.

---

## 3. Veri formatı kararları

### 3.1 Neden JSON + neden ScriptableObject? (karma yaklaşım)

| Veri türü | Format | Gerekçe |
|---|---|---|
| **İçerik** (nesneler, kurallar, lokalizasyon, el yapımı bölümler) | **JSON** (`Assets/_Game/Content/`, `TextAsset` olarak yüklenir) | Yüzlerce kayıt; git diff'i okunabilir, merge edilebilir; `.meta`/GUID çöplüğü yok; toplu düzenleme ve otomatik üretim kolay; **saf C# testlerinde Unity'siz okunabilir**; ileride sunucudan güncellenebilir. |
| **Ayar/tuning** (zorluk eğrileri, renk paleti, ekonomi, prefab referansları) | **ScriptableObject** | `AnimationCurve`, renk seçici, prefab referansı gibi şeyler Inspector'da ayarlanmalı; JSON'da AnimationCurve düzenlemek işkencedir. |

**Yükleme yolu: `Resources` değil, `TextAsset` referansı.**
`Content/` altındaki JSON'lar bir `ContentManifest` ScriptableObject'inde
`TextAsset[]` olarak tutulur. Böylece: (a) `Resources` klasörünün build boyutu
ve yükleme maliyeti cezasından kaçınırız, (b) `StreamingAssets`'in Android'de
`UnityWebRequest` ile asenkron okuma zorunluluğuna girmeyiz, (c) referans
kopması derleme/validasyon zamanında yakalanır. `SetupProjectTool` manifest'i
otomatik doldurur.

### 3.2 Nesne formatı (`objects.*.json`)

```json
{
  "pack": "colorshape",
  "objects": [
    {
      "id": "cs_red_cube",
      "text": "",
      "shape": "cube",
      "color": "red",
      "tags": ["colorshape", "color.red", "shape.cube"]
    },
    {
      "id": "en_cat",
      "text": "cat",
      "shape": "cube",
      "color": "auto",
      "tags": ["english", "word", "noun", "animal"],
      "props": { "tr": "kedi" }
    },
    {
      "id": "geo_japan",
      "text": "Japonya",
      "shape": "cylinder",
      "color": "auto",
      "tags": ["geography", "country", "continent.asia"],
      "props": { "capital": "Tokyo" }
    }
  ]
}
```

- `id` benzersiz; `shape` ∈ `cube|sphere|cylinder|capsule`;
  `color` bir palet anahtarı veya `auto` (rastgele, kural renge bağlı değilse).
- `tags` düz string listesi, nokta ile ad alanı (`color.red`, `continent.asia`).
- `props` isteğe bağlı string→string sözlüğü (`tr`, `antonym`, `capital`...).
- **Sayılar JSON'da yoktur** — `NumberObjectFactory` bir sayıdan nesneyi ve
  etiketlerini (`even`, `prime`, `multipleOf3`, `square`…) deterministik üretir.
- `ambiguous` etiketi taşıyan nesneler asla doğru/yanlış ayrımına sokulmaz
  (bkz. DESIGN.md §4.3–4.4).

### 3.3 Kural formatı (`rules.json`)

```json
{
  "rules": [
    { "id": "r_even",  "textKey": "rule.even",  "packs": ["numbers"],
      "predicate": { "op": "tag", "value": "even" } },

    { "id": "r_gt50",  "textKey": "rule.greaterThan", "textArgs": ["50"],
      "packs": ["numbers"], "complexity": 2,
      "predicate": { "op": "cmp", "field": "value", "cmp": "gt", "number": 50 } },

    { "id": "r_m3_lt20", "textKey": "rule.and",
      "textArgKeys": ["rule.multipleOf3", "rule.lessThan20"],
      "packs": ["numbers"], "complexity": 3,
      "predicate": { "op": "and", "nodes": [
        { "op": "tag", "value": "multipleOf3" },
        { "op": "cmp", "field": "value", "cmp": "lt", "number": 20 } ] } },

    { "id": "r_nonred_sphere", "textKey": "rule.and",
      "textArgKeys": ["rule.notRed", "rule.sphere"],
      "packs": ["colorshape"], "complexity": 3,
      "predicate": { "op": "and", "nodes": [
        { "op": "not", "nodes": [ { "op": "tag", "value": "color.red" } ] },
        { "op": "tag", "value": "shape.sphere" } ] } }
  ]
}
```

**Predicate düğüm tipleri:** `tag` · `and` · `or` · `not` · `cmp`
(`gt|gte|lt|lte|eq|neq`, `field: "value"`) · `between` · `prop`
(`{"op":"prop","key":"tr","equals":"elma"}`) · `always`.

Değerlendirme saf C#'tır: `bool RuleEvaluator.Matches(Predicate p, GameObjectDef o)`.
Yan etkisiz, allocation'sız, test edilebilir.

### 3.4 Bölüm formatı (`LevelSpec` — üretilir, JSON ile override edilebilir)

```json
{
  "index": 30,
  "worldId": 2,
  "ruleId": "r_m3_lt20",
  "packs": ["numbers"],
  "objectCount": 22,
  "correctCount": 12,
  "targetCorrect": 9,
  "timeLimit": 40,
  "lives": 3,
  "motion": "drift",
  "arenaSize": { "x": 9.0, "y": 16.0 },
  "holeStartRadius": 0.55,
  "isBoss": true,
  "midLevelSwitch": { "atProgress": 0.5, "ruleId": "r_even" },
  "seed": 918273
}
```

`levels.handcrafted.json` içinde aynı şemada, `index` ile eşleşen kayıtlar
üreticinin çıktısını **kısmen** ezer (yalnızca verilen alanlar).

### 3.5 Bölüm üreteci sözleşmesi

```csharp
LevelSpec LevelGenerator.Generate(int levelIndex, int seed, DifficultySettings d,
                                  ContentDatabase db, RuleDatabase rules);
```
- **Deterministik:** aynı `(levelIndex, seed)` → bit birebir aynı bölüm
  (nesne yerleşimi dahil). `System.Random` yerine kendi `DeterministicRandom`
  (xorshift) sınıfımız kullanılır — platformlar arası tutarlılık için.
- Üretici garantileri: `correctCount >= targetCorrect`, kural metni boş değil,
  havuzda yeterli yanıltıcı var, `ambiguous` nesne yok, tüm nesneler arena içinde
  ve birbirine değmiyor.
- Günlük meydan okuma: `seed = int(yyyyMMdd)`, `levelIndex` = o günün zorluğu.

---

## 4. Mimari kararlar

- **Yutma mekaniği fiziksiz.** Mesafe kontrolü + tween. Deterministik, ucuz,
  Unity'de çalıştırmadan doğru yazılabilir. `Rigidbody`/`Collider` kullanılmaz.
- **Kamera:** kaydırmalı arena. `CameraRig` deliği `SmoothDamp` ile takip eder,
  arena sınırlarına clamp'lenir. Kural HUD'da kalıcı şerit olarak durduğu için
  kamera hareketi planlamayı bozmaz. Ekran dışı nesneler güncellenmez.
- **State machine:** `Boot → Menu → Playing → Win/Fail → Menu`.
  `GameStateMachine` + `IGameState` (Enter/Tick/Exit). Sahne değişimi yok;
  tek `Game` sahnesi + `Boot` sahnesi, paneller açılıp kapanır (yükleme süresi 0).
- **Servisler arayüz arkasında:** `ISaveService`, `IAudioService`, `IAdService`,
  `IHapticService`, `ILocalizationService`. Basit bir `ServiceLocator` ile
  bağlanır (DI framework bağımlılığı yok).
- **Kaydetme:** POCO `SaveData` → JSON → `PlayerPrefs` tek anahtar altında
  (`kd.save.v1`). Sürüm alanı ile ileri göç. İçerik: bölüm ilerlemesi + yıldızlar,
  para, upgrade kademeleri, skinler, ayarlar, günlük meydan okuma kaydı.
- **Tween:** DOTween yerine **kendi minimal tween sistemimiz** (`Juice/Tween.cs`,
  struct tabanlı, allocation'sız, coroutine'siz, tek `TweenRunner` update'i).
  Dış paket bağımlılığını sıfıra indirir.
- **Object pooling:** nesneler, partiküller ve TMP etiketleri havuzlanır.
  Oynanış sırasında `Instantiate`/`Destroy` yok.
- **Giriş:** Input System paketi, tek `press + position` action'ı. Eski
  `Input.GetMouseButton` API'si kullanılmaz.

---

## 5. Çalışma kuralları (her oturumda geçerli)

1. **Bulutta Unity Editor yok** — kod çalıştırılamaz. Bu yüzden: using'ler,
   namespace'ler ve API imzaları elle doğrulanır; şüpheli API kullanılmaz.
   Unity 6 (6000.x) API'si hedeflenir.
2. **Sahne (.unity) ve prefab YAML'ları elle yazılmaz.** Bunun yerine
   `Tools/KuralDeligi/Setup Project` editor scripti her şeyi kurar ve
   **idempotent**tir (tekrar çalıştırılabilir, bozmaz).
3. **Görsel/ses asseti üretilmez.** Primitive + materyal. Görseller sonradan
   kolay değiştirilebilir olmalı (materyal ve prefab referansları config'te).
4. **Magic number yok.** Her ayar ScriptableObject veya `[SerializeField]`.
5. **Aşama akışı:** her aşama sonunda dur, özet ver, onay bekle.
   İlk iskelet dışında her özellik ayrı branch + küçük commit'ler + PR.
   PR açıklaması: *ne değişti · Unity'de ne yapmalıyım · nasıl test ederim*.
6. **Testler:** `Core` katmanının tamamı EditMode testleriyle kaplanır
   (kural değerlendirme, bölüm üretimi determinizmi, içerik doğrulama).
7. **Doğruluk:** coğrafya/genel kültür verisi kaynak kontrollü girilir;
   tartışmalı olan her şey `ambiguous` etiketi alır.
8. Emin olunmayan tasarım kararları kullanıcıya sorulur.

---

## 6. Durum

### Yapılanlar
- **Aşama 0 (tamamlandı):** `DESIGN.md` ve `CLAUDE.md` yazıldı; mimari,
  veri formatları (nesne / kural / bölüm) ve format gerekçeleri belirlendi;
  4 temel tasarım kararı kullanıcı onayıyla kesinleşti.

### Sıradakiler
- **Aşama 1:** Proje iskeleti (manifest, ProjectVersion, .gitignore, README),
  `Setup Project` editor aracı, delik kontrolü + yutma, Renk/Şekil paketiyle
  10 oynanabilir bölüm, win/fail ekranı. → PR
- **Aşama 2:** Kural sistemi (birleşik), bölüm üreteci, zorluk eğrisi,
  `Validate Levels`, EditMode testleri. → PR
- **Aşama 3:** Tüm konu paketleri + içerik veritabanı. → PR
- **Aşama 4:** Dünyalar, boss bölümleri, kural değişimi, hareketli nesneler. → PR
- **Aşama 5:** Meta sistemler, menüler, ayarlar, lokalizasyon. → PR
- **Aşama 6:** Juice, haptic, performans, `IAdService` placeholder'ları. → PR

### Onaylanan tasarım kararları (Aşama 0)
Kaydırmalı arena + kalıcı kural şeridi · yanlışta can+küçülme · enerji sistemi yok ·
süre sonu cezasız. Ayrıntı: `DESIGN.md` §10. Kalan açık konu: `DESIGN.md` §11.
