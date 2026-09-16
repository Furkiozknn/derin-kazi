# itch.io yükleme komutları — ÇALIŞTIRILMADI

> Bu dosyadaki hiçbir komut çalıştırılmadı. Yükleme dışarı açılan bir işlem,
> kararı Furki'nin. (Bkz. `CLAUDE.md` → Yayın.)

## Ön koşullar

- butler kurulu ve `butler login` yapılmış (anahtar `butler_creds` içinde).
- itch.io'da `derin-kazi` adıyla bir proje sayfası **önceden açılmış** olmalı —
  butler yeni sayfa oluşturamaz, yalnız var olana dosya yükler.
- Sürüm etiketi bu turda `v0.4`.

Kullanıcı adını doğrula:

```powershell
butler status furkiozknn/derin-kazi
```

## Yükleme

Proje kökünde (`D:\Repolar\derin-kazi`):

```powershell
# Web (tarayıcıda oynanan sürüm)
butler push build\web furkiozknn/derin-kazi:web --userversion 0.4

# Windows masaüstü
butler push build\windows furkiozknn/derin-kazi:windows --userversion 0.4
```

Yükleme sonrası durum:

```powershell
butler status furkiozknn/derin-kazi
```

## Sayfa ayarları (elle, butler yapamaz)

1. **Web kanalı** → "This file will be played in the browser" işaretle.
2. Embed boyutu **1280 × 720**, "Fullscreen button" açık.
3. **SharedArrayBuffer kutusu gerekmiyor.** Web çıktısı `thread_support` kapalı
   derlendi; itch'in özel COOP/COEP başlığı olmadan da açılıyor. (Prototip
   turunda bu kutu gerekiyordu, artık gerekmiyor.)
4. Kapak: `yayin/kapak.png` · Ekran görüntüleri: `yayin/ekran-1..4.png` ve
   `yayin/ekran-5-menu.png` · Tanıtım GIF'i: `yayin/tanitim.gif` (sayfa metninin
   en üstüne koy, itch GIF'i oynatır)
5. Sayfa metni: `yayin/itch-sayfa.md` (önce İngilizce bölüm, altına Türkçe).

## Geri alma

Yanlış sürüm gittiyse kanalı bir öncekine döndür:

```powershell
butler status furkiozknn/derin-kazi          # build numaralarını gör
butler wipe furkiozknn/derin-kazi:web        # son yüklemeyi kaldır
```

## Yerel deneme (yüklemeden önce)

Web çıktısı artık düz bir statik sunucuyla açılıyor:

```powershell
cd build\web
python -m http.server 8080
# tarayıcıda http://localhost:8080/
```

v0.4'te tarayıcıda **özellikle şuna bak** (tarayıcının geliştirici araçlarında
telefon emülasyonunu aç, dokunmatiği işaretle):

1. **Alt ipucu tuş anlatmamalı.** Telefonda "E — Üs • T — ışınlanma • M — harita"
   yerine "Üs düğmesi — sat, geliştir, yakıt • Harita düğmesi" yazmalı.
   v0.3 web yapısında kalan tek açık kusur buydu.
2. **Deprem geri sayımı.** 15 m'den derine in, 5 sefer tamamla: alt satırda
   "DEPREM x.x sn — … (+… ₺) ya da derinde kal (… hasar)" belirmeli.
3. **Maden zemini.** Toprak katmanındaki bakır damarı kahverengi zeminde
   durmalı, mavi-gri kare gibi değil.
4. v0.3'ten gelenler hâlâ sağlam mı: `₺ ← → ↓ ✔` kutu değil simge; menü arka
   planı ekranın altını dolduruyor.
