# itch.io yükleme komutları — ÇALIŞTIRILMADI

> Bu dosyadaki hiçbir komut çalıştırılmadı. Yükleme dışarı açılan bir işlem,
> kararı Furki'nin. (Bkz. `CLAUDE.md` → Yayın.)

## Ön koşullar

- butler kurulu ve `butler login` yapılmış (anahtar `butler_creds` içinde).
- itch.io'da `derin-kazi` adıyla bir proje sayfası **önceden açılmış** olmalı —
  butler yeni sayfa oluşturamaz, yalnız var olana dosya yükler.
- Sürüm etiketi bu turda `v0.6` (butler'a `0.6.0`).

Kullanıcı adını doğrula:

```powershell
butler status furkiozknn/derin-kazi
```

## Yükleme

Proje kökünde (`D:\Repolar\derin-kazi`):

```powershell
# Web (tarayıcıda oynanan sürüm)
butler push build\web furkiozknn/derin-kazi:web --userversion 0.6.0

# Windows masaüstü
butler push build\windows furkiozknn/derin-kazi:windows --userversion 0.6.0
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
4. Kapak: `yayin/kapak.png` · Ekran görüntüleri: `yayin/ekran-1..4.png`,
   `yayin/ekran-5-menu.png` ve `yayin/ekran-6-derin.png` · Tanıtım GIF'i:
   `yayin/tanitim.gif` (sayfa metninin en üstüne koy, itch GIF'i oynatır)
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

v0.6'da tarayıcıda **özellikle şuna bak** (ses açık; telefon emülasyonu 915×412
için geliştirici araçlarında dokunmatiği işaretle):

1. **Müzik geçişi.** 40 m, 150 m ve 210 m'yi geçerken parça değişmeli ve
   değişim **kesintisiz** olmalı (iki parça 1,6 sn üst üste çaprazlanır; takılma,
   sessiz boşluk ya da baştan başlama yok). Sınırda bir aşağı bir yukarı gidince
   parça yeniden başlamamalı. Menüden oyuna ve oyundan menüye dönüşte de geçiş
   yumuşak.
2. **Parçacık ve ton.** 8 m'den derinde havada süzülen toz (toprakta kahverengi,
   taşta gri), 150 m'den derinde yukarı doğru kıvılcım; düz arka plan sığda
   kahverengi, bazaltta mor-kızıl, çekirdek kabuğunda kızıl. Yüzeyde parçacık yok.
3. **Derin Mod.** Bir kayıtta çekirdek çıkarılmışsa menüde sağ üstte
   `▼ DERİN MOD x1 ▼` rozeti ve "Derin Mod x1" düğmesi. Girince ana dünya
   silinmemeli: menüye dönüp "Başla" eski dünyayı (tünelleriyle) açmalı, "Derin
   Mod" ise süren Derin Mod turuna "devam et" demeli. Derin Mod'da ışık 3 karo
   (dar), deprem 4 seferde bir, ilk gizli odada 7. eser ("Uyanmış Kabuk
   Parçası") çıkmalı ve ışık bir karo büyümeli; müze 7 satır.
4. **Deprem seferi.** 5 sefer (Derin Mod'da 4) tamamlayıp 15 m'den derine in:
   uyarı kendiliğinden başlar; pervaneyle çıkınca `+… ₺`, derinde kalınca `-1 can`,
   istasyondan ışınlanınca ikramiye ve hasar yok. (Sahne testi üçünü de sınıyor;
   tarayıcıda bir kez gözle görmek yeter.)
5. **Eski kayıt.** v0.5 web sürümünde oynanmış bir tarayıcı kaydı (IndexedDB) v0.6'da
   açılmalı: tüneller, keşif, para yerinde; menüde rozet yok, "Başla" sürüyor.
6. v0.5'ten gelenler hâlâ sağlam mı: alet düğmeleri (DİNAMİT/RADAR), keşif sisi
   ve mini harita, deprem panosunun üç satırı, mağaza metinlerinin düğme anlatması,
   `₺ ← → ↓ ✔ ▼` simgeleri kutu değil.
