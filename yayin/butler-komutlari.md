# itch.io yükleme komutları — ÇALIŞTIRILMADI

> Bu dosyadaki hiçbir komut çalıştırılmadı. Yükleme dışarı açılan bir işlem,
> kararı Furki'nin. (Bkz. `CLAUDE.md` → Yayın.)

## Ön koşullar

- butler kurulu ve `butler login` yapılmış (anahtar `butler_creds` içinde).
- itch.io'da `derin-kazi` adıyla bir proje sayfası **önceden açılmış** olmalı —
  butler yeni sayfa oluşturamaz, yalnız var olana dosya yükler.
- Sürüm etiketi bu turda `v0.2`.

Kullanıcı adını doğrula:

```powershell
butler status furkiozknn/derin-kazi
```

## Yükleme

Proje kökünde (`D:\Repolar\derin-kazi`):

```powershell
# Web (tarayıcıda oynanan sürüm)
butler push build\web furkiozknn/derin-kazi:web --userversion 0.2

# Windows masaüstü
butler push build\windows furkiozknn/derin-kazi:windows --userversion 0.2
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
4. Kapak: `yayin/kapak.png` · Ekran görüntüleri: `yayin/ekran-1..4.png`
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
