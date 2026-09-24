# Kural Deliği

Yetişkinlere yönelik hyper-casual beyin + refleks oyunu. Oyuncu zeminde bir delik
sürükler; her bölümün başında çıkan **kurala uyan** nesneleri yutar, uymayanlardan
kaçınır.

- Oyun tasarımı: [`DESIGN.md`](DESIGN.md)
- Mimari, klasör yapısı, veri formatları ve yol haritası: [`CLAUDE.md`](CLAUDE.md)

---

## Gereksinimler

| | |
|---|---|
| Unity | **6000.0.x LTS** (Unity 6 LTS) |
| Modüller | **Android Build Support** (+ OpenJDK + Android SDK & NDK), IL2CPP |
| Render pipeline | URP (Universal Render Pipeline) |
| Platform | Android, portrait |

---

## Projeyi ilk kez kurma (tek seferlik)

Bu repoda Unity'nin ürettiği `ProjectSettings/` dosyaları henüz yok. En güvenli
yol, projeyi **Unity Hub'a kurdurmak** ve repoyu onun içine bağlamaktır.

### 1) Unity Hub'da boş bir URP projesi oluştur
1. Unity Hub → **Installs** → Unity **6000.0.x LTS** kurulu değilse kur.
   Kurulum sırasında **Android Build Support** modülünü işaretle.
2. Unity Hub → **Projects** → **New project**
3. Editor sürümü: **6000.0.x LTS**
4. Şablon: **Universal 3D** (bazı sürümlerde adı *3D (URP)*)
5. Proje adı: `KuralDeligi` — konum: boş bir klasör (örn. `C:\Dev\KuralDeligi`)
6. **Create project** → açılmasını bekle → sonra **Unity'yi kapat**.

### 2) Repoyu bu klasöre bağla
Oluşan proje klasörünün içinde bir terminal aç ve sırayla çalıştır:

```bash
git init
git remote add origin https://github.com/VectorSevenGame/Kural-Deli-i.git
git fetch origin
git checkout -b claude/kural-deligi-game-4d0egb origin/claude/kural-deligi-game-4d0egb
```

> Repodaki dosyalar (`CLAUDE.md`, `DESIGN.md`, `.gitignore`, `Assets/_Game/…`)
> Unity'nin ürettiği dosyalarla çakışmaz, checkout sorunsuz geçer.

### 3) Unity'nin ürettiği ayarları repoya işle
```bash
git add -A
git commit -m "Unity 6 URP proje iskeleti (Unity Hub tarafından üretildi)"
git push -u origin claude/kural-deligi-game-4d0egb
```

Bu adım önemli: `ProjectSettings/` ve `Packages/manifest.json` böylece repoya
girer ve bundan sonra ben de bu dosyalar üzerinde çalışabilirim.

### 4) Projeyi Unity'de aç
Unity Hub → **Open** → proje klasörünü seç. (Bundan sonra hep buradan açılır.)

---

## Günlük akış (her yeni özellikten sonra)

```bash
git pull origin claude/kural-deligi-game-4d0egb
```
Unity'ye geç, derlemenin bitmesini bekle, sonra:

**`Tools ▸ KuralDeligi ▸ Setup Project`**

Bu menü komutu sahneleri, kamerayı, ışığı, UI'ı, materyalleri ve prefab'ları kurar,
Build Settings'e ekler ve Android ayarlarını (portrait kilidi, IL2CPP, ARM64,
kalite ayarları) yapar. **Idempotent'tir** — kaç kez çalıştırılırsa çalıştırılsın
bir şeyi bozmaz.

Sonra `Assets/_Game/Scenes/Game.unity` sahnesini aç ve **Play**'e bas.

> Not: `Setup Project` aracı Aşama 1 ile birlikte gelecek. Şu an repoda yalnızca
> dokümanlar ve proje iskeleti var.

---

## Testler

Unity → **Window ▸ General ▸ Test Runner** → **EditMode** → **Run All**.
Kural değerlendirme ve bölüm üretimi saf C# olduğu için Unity'siz de doğrulanabilir.

---

## Build (Android)

1. `Tools ▸ KuralDeligi ▸ Setup Project` (Android ayarlarını uygular)
2. **File ▸ Build Settings** → Platform: **Android** → *Switch Platform*
3. **Build** (veya cihaz bağlıyken *Build And Run*)
