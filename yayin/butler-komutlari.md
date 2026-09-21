# itch.io yükleme komutları — ÇALIŞTIRILMADI

> Bu dosyadaki hiçbir komut çalıştırılmadı. Yükleme dışarı açılan bir işlem,
> kararı Furki'nin. (Bkz. `CLAUDE.md` → Yayın.)

## Ön koşullar

- butler kurulu ve `butler login` yapılmış (anahtar `butler_creds` içinde).
- itch.io'da `derin-kazi` adıyla bir proje sayfası **önceden açılmış** olmalı —
  butler yeni sayfa oluşturamaz, yalnız var olana dosya yükler.
- Sürüm etiketi bu turda `v0.7` (butler'a `0.7.0`).

Kullanıcı adını doğrula:

```powershell
butler status <itch-kullanici>/derin-kazi
```

## Yükleme

Proje kökünde:

```powershell
# Web (tarayıcıda oynanan sürüm)
butler push build\web <itch-kullanici>/derin-kazi:html5 --userversion 0.7.0

# Windows masaüstü
butler push build\windows <itch-kullanici>/derin-kazi:windows --userversion 0.7.0
```

Yükleme sonrası durum:

```powershell
butler status <itch-kullanici>/derin-kazi
```

## Sayfa ayarları (elle, butler yapamaz)

1. **Web kanalı** → "This file will be played in the browser" işaretle.
2. Embed boyutu **1280 × 720**, "Fullscreen button" açık.
3. **SharedArrayBuffer kutusu gerekmiyor.** Web çıktısı `thread_support` kapalı
   derlendi; itch'in özel COOP/COEP başlığı olmadan da açılıyor. (Prototip
   turunda bu kutu gerekiyordu, artık gerekmiyor.)
4. Kapak: `yayin/kapak.png` · Ekran görüntüleri: `yayin/ekran-1..4.png`,
   `yayin/ekran-5-menu.png` ve `yayin/ekran-6-derin.png` · Tanıtım GIF'i:
   `yayin/tanitim.gif` (sayfa metninin en üstüne koy, itch GIF'i oynatır)
5. Sayfa metni: `yayin/itch-sayfa.md` (önce İngilizce bölüm, altına Türkçe).

## Geri alma

Yanlış sürüm gittiyse kanalı bir öncekine döndür:

```powershell
butler status <itch-kullanici>/derin-kazi          # build numaralarını gör
butler wipe <itch-kullanici>/derin-kazi:html5        # son yüklemeyi kaldır
```

## Yerel deneme (yüklemeden önce)

Web çıktısı artık düz bir statik sunucuyla açılıyor:

```powershell
cd build\web
python -m http.server 8080
# tarayıcıda http://localhost:8080/
```

v0.7'de tarayıcıda **özellikle şuna bak** (ses açık; telefon emülasyonu 915×412
için geliştirici araçlarında dokunmatiği işaretle). Bu oturumda Playwright ile
yalnız açılış denendi (menü, konsol hatası yok); aşağıdakiler kulak ve el ister:

1. **Matkap döngü sesi.** Kazmaya başlayınca motor vızıltısı başlamalı, karo
   kırılıp araç düşerken KESİLMEMELİ (0,3 sn kuyruk), tuşu bırakınca kısa sönümle
   susmalı. Matkap Sv1 → Sv5 arasında perde tizleşir. Web'de `AudioStreamPlayer`
   döngüsü — 0,6 sn'de bir dikiş duyuluyor mu?
2. **Deprem gürültüsü.** Uyarı başlarken kısık/tiz bir sarsıntı, deprem patlarken
   tam gürültü (vuruş + uğultu + çatırtı). Patlama sesi (dinamit/gaz) ile
   karışmamalı.
3. **Yüzey ve araç.** Yüzeyde çimen üstü kırık kenarlı, gökle birleşim düz çizgi
   değil; yürürken paletler dönüyor (yavaşken yavaş), uçarken alev üç kareyle
   titriyor, kazarken matkap dişleri kayıyor.
4. **Işınlama işareti.** Yeraltında `R` (telefonda İŞARET KOY): pembe flama ve
   "İşaret N m'de" ipucu; üsse dön, `T` (Üs düğmesi) → "İşarete ışınlan — N m"
   satırı; git → işaret silinmeli; mini haritada pembe nokta. Deprem sonrası
   işarete gidince araç kayanın içinde kalmamalı.
5. **Bitiş paneli.** Çekirdeği çıkarınca döküm: bu dünya + "Toplam (bütün
   dünyalar)". Telefon oranında panel taşmamalı, alet şeridi panelin üstüne
   binmemeli.
6. **Eski kayıt.** v0.6 web sürümünde oynanmış bir tarayıcı kaydı (IndexedDB)
   v0.7'de açılmalı: tüneller, keşif, para yerinde; işaret yok; bitiş panelinde
   toplam sıfırdan başlar.
7. v0.6'dan gelenler hâlâ sağlam mı: müzik geçişleri 40/150/210 m'de kesintisiz,
   toz/kıvılcım, Derin Mod rozeti ve ayrı yuva, deprem seferi ve panosu, alet
   düğmeleri, keşif sisi, `₺ ← → ↓ ✔ ▼` simgeleri kutu değil.
