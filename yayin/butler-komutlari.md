# itch.io yükleme komutları — ÇALIŞTIRILMADI

> Bu dosyadaki hiçbir komut çalıştırılmadı. Yükleme dışarı açılan bir işlem,
> kararı Furki'nin. (Bkz. `CLAUDE.md` → Yayın.)

## Ön koşullar

- butler kurulu ve `butler login` yapılmış (anahtar `butler_creds` içinde).
- itch.io'da `derin-kazi` adıyla bir proje sayfası **önceden açılmış** olmalı —
  butler yeni sayfa oluşturamaz, yalnız var olana dosya yükler.
- Sürüm etiketi bu turda `v0.5` (butler'a `0.5.0`).

Kullanıcı adını doğrula:

```powershell
butler status furkiozknn/derin-kazi
```

## Yükleme

Proje kökünde (`D:\Repolar\derin-kazi`):

```powershell
# Web (tarayıcıda oynanan sürüm)
butler push build\web furkiozknn/derin-kazi:web --userversion 0.5.0

# Windows masaüstü
butler push build\windows furkiozknn/derin-kazi:windows --userversion 0.5.0
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

v0.5'te tarayıcıda **özellikle şuna bak** (tarayıcının geliştirici araçlarında
telefon emülasyonunu aç, dokunmatiği işaretle, 915×412):

1. **Alet düğmeleri.** Sol ortada dikey iki düğme: `DİNAMİT n` ve `RADAR AÇ`.
   Dinamit yokken / radar alınmamışken sönük. Basınca dinamit sayacı düşmeli,
   radar sisi geçici açmalı. Düğmeler ◀ alanının üstünde, ona binmiyor.
2. **Keşif sisi.** Yeraltında aracın çevresi aydınlık, gezilmiş tünel loş,
   gezilmemiş yer kapkaranlık. Yüzeyde sis yok. Mini haritada yalnız gezilen
   yer boyalı. Oyunu kapatıp açınca keşif yerinde kalmalı.
3. **Deprem panosu.** 15 m'den derine in, 5 sefer tamamla: uyarı başlarken
   kırmızı ekran parlaması + ses; ekranın üst-ortasında üç satır:
   `DEPREM x.x sn` / `▲ UÇ ile YÜZEYE ÇIK → +… ₺ ikramiye` / `DERİNDE KAL → … hasar`.
   Son 3 saniyede sayaç yanıp söner.
4. **Mağaza metinleri.** Telefonda "F ile", "Q —", "T ile" yerine "DİNAMİT
   düğmesi ile", "RADAR düğmesi —", "Üs düğmesi ile" yazmalı.
5. v0.3–v0.4'ten gelenler hâlâ sağlam mı: `₺ ← → ↓ ✔` kutu değil simge; menü
   arka planı ekranın altını dolduruyor; alt ipucu tuş anlatmıyor; maden
   damarının zemini katmanın kayası.
