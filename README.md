# Derin Kazı

Yandan kesit görünümlü kazı + gelişim oyunu: matkaplı araçla yeraltına in, maden
topla, yakıt bitmeden yüzeye dön, sat, aracını geliştir, 250 m'deki çekirdeğe ulaş.

![Oynanış](yayin/ekran-2.png)

> Durum: **v0.2 — yayına hazır ilk sürüm.** Gerçek pixel art, ses, ayarlar
> ekranı, 5 katman, tehlikeler, aletler, müze ve kaçış finali var.
> Windows + Web çıktısı alınıyor; yayın paketi `yayin/` altında hazır
> (**yüklenmedi**).

## Kontroller

| Tuş | Gamepad | İş |
|---|---|---|
| `A` / `D` veya `←` / `→` | Sol çubuk, D-pad | Yürü; zemindeyken yana kaz |
| `S` veya `↓` | Aşağı | Aşağı kaz |
| `W` / `Boşluk` | A | Pervane — boş tünelde yüksel |
| `E` | X | Üs menüsü (sat, geliştir, yakıt, müze) |
| `T` | RB | Işınlanma (yüzey ↔ istasyon) |
| `Q` | LB | Maden radarı |
| `F` | Y | Dinamit (3×3) |
| `M` | Back | Mini harita |
| `Esc` | Start | Duraklat / ayarlar |

Dokunmatik cihazda ekranın sol/sağ/alt bölgesine dokunmak o yöne kazar, üstteki
büyük düğme pervanedir.

**Yukarı kazma yok.** Yükselmek için pervaneyle kendi açtığın tünelden çıkarsın —
geri dönüş yolunu düşünerek kazmak oyunun ana gerilimi.

## Oyun döngüsü

1. Üsten aşağı kaz. Her katmanın kayası bir öncekinden sert.
2. Yük dolunca ya da yakıt azalınca üsse dön, sat, geliştir.
3. Bir sonraki katmanın kapısı matkap seviyesi ister: "Matkap Sv2 gerekli".
4. 250 m'deki **çekirdeğe** dokun → tüm aletler açılır, yüzeye zamanlı kaçış.

### Beş katman

| Derinlik | Katman | Maden | Tehlike | Gereken matkap |
|---|---|---|---|---|
| 0–40 m | Toprak | Bakır (10 ₺, 1 ağırlık) | Gevşek kaya | Sv1 |
| 40–90 m | Taş | Demir (25 ₺, 2) | Gaz cebi | Sv2 |
| 90–150 m | Sert Taş | Altın (62 ₺, 4) | Gevşek kaya | Sv3 |
| 150–210 m | Bazalt | Elmas (117 ₺, 6) | Lav | Sv4 |
| 210–250 m | Çekirdek Kabuğu | Platin (240 ₺, 10) | Lav | Sv5 |

### Geliştirmeler ve aletler

- **Matkap / Yakıt deposu / Yük kasası / Gövde zırhı** — 5 seviye,
  fiyat `taban × 1,35^seviye`.
- **Maden radarı** (`Q`) — en yakın madenin yönünü ve uzaklığını HUD'a yazar.
- **Isı kalkanı** — lav yakınında hasar almazsın.
- **Dinamit** (`F`) — 3×3 patlatır, sarf malzemesi.
- **İstasyon kiti** (`T`) — 50 m aralıkla kurulur; istasyon ile yüzey arasında
  anında yolculuk.
- **Eserler** — gizli odalarda bulunur, müzeye gider, kalıcı pasif bonus verir.

## Verilen kararlar

- **Maden ağırlığı var.** Elmas bakırdan 12 kat değerli ama 6 kat ağır. Kasa
  kapasitesi ağırlık sayar. Görevdeki "katman başına gelir ~×1,5" hedefini
  tutturan ayar bu: yalnız değeri büyütseydik gelir katman başına ×2'nin üstüne
  çıkıyor ve oyun 6 turda bitiyordu (simülasyon bunu ölçtü).
- **Yakıt bitince ölüm yok.** Araç yüzeye çekilir, derinlikle artan bir çekme
  ücreti alınır, yükün yarısı olduğu yerde sandık olarak kalır ve geri alınabilir.
  Sert ceza "bir tur daha" hissini öldürüyor (rakip analizi).
- **Deponun %30'u üste dönünce bedava dolar**, üstü ücretli. Yakıt hâlâ bir
  kaynak ama parasız + yakıtsız kilitlenme yok. Bu kural denge simülasyonu
  oyuncuyu 88 m'de 0 gelirle sonsuza kadar takılı bıraktığı için eklendi.
- **Işınlanma yalnız üste ya da bir istasyona basarken çalışır.** Her yerden
  anında kaçış olsaydı yakıt gerilimi tamamen kalkardı; istasyon kurmak da
  gerçek bir yatırım olmazdı.
- **Kazılan hücreler kaydediliyor.** Dünya 16×16 chunk; yalnız aracın çevresindeki
  3×3 chunk `TileMapLayer`'da duruyor, kırılan karolar `Dictionary` farkı olarak
  tutuluyor. Oyun kapatılıp açılınca tüneller yerinde kalıyor.
  Ölçüm: 64×272 = 17.408 karonun ~1.400'ü bellekte, **32 MB statik bellek**.
- **Lav mağara boşluğunun yerine konuyor**, kayanın değil. Böylece kazılamaz
  olmasına rağmen hiçbir yolu tıkamıyor; test yüzeyden çekirdeğe kazılabilir bir
  yol olduğunu her tohumda doğruluyor.
- **Maden damarlarının zemini her katmanda aynı nötr koyu taş.** Bakır bazaltın
  içinde de çıkabiliyor; kendi katmanının kayasıyla çizilince oraya yanlışlıkla
  yapıştırılmış gibi duruyordu.
- **Web çıktısı `thread_support` kapalı derlendi.** Prototip turunda itch'te
  "SharedArrayBuffer" kutusu gerekiyordu; artık düz bir statik sunucuda açılıyor.

## Çalıştırma

```powershell
godot --path . --import                                           # içe aktar
godot --path .                                                    # oyna
godot --headless --path . --script res://tests/test_calistir.gd   # birim testleri
godot --headless --path . --script res://tests/test_oynanis.gd    # oynanış testi
godot --headless --path . --script res://tests/test_denge.gd      # denge simülasyonu
godot --headless --path . --script res://tools/sprite_uret.gd     # tüm pixel art
godot --path . --script res://tools/ekran_al.gd                   # yayın görselleri
```

Dışa aktarma:

```powershell
godot --headless --path . --export-release "Windows Masaustu"   # build/windows/derin-kazi.exe
godot --headless --path . --export-release "Web (HTML5)"        # build/web/index.html
```

Ayrıntı ve proje kuralları: **`CLAUDE.md`**.

## Düzen

```
scripts/ayarlar.gd        tüm denge sabitleri — sayı değiştireceksen burası
scripts/dunya_uretici.gd  tohumdan karo üreten saf sınıf
scripts/dunya.gd          TileMapLayer, 16x16 chunk, kazı farkı
scripts/durum.gd          koşu durumu + tüm ekonomi kuralları (saf, test edilebilir)
scripts/arac.gd           hareket, kazma, hasar, aletler
scripts/oyun.gd           HUD, üs, müze, ışınlanma, tehlikeler, oyun hissi
scripts/ses.gd            autoload: efekt/müzik/ayar
tools/                    varlık üretimi (pixel art, müzik, ekran görüntüsü)
tests/                    headless testler (çıkış kodu 0 = geçti)
yayin/                    itch sayfası, 4 ekran görüntüsü, kapak, butler komutları
```

Kayıt dosyası: `user://kayit.cfg`
(`%APPDATA%\Godot\app_userdata\Derin Kazı\kayit.cfg`) — `[oyun]` ilerleme ve
kazılan hücreler, `[ayar]` ses/tam ekran/sarsıntı tercihleri.

## Varlıklar

GUI aracı kullanılmadı. Tüm pixel art `tools/sprite_uret.gd` içinde Godot `Image`
API'siyle üretiliyor (palet: **Endesga 32**). Ses efektleri rFXGen ön ayarlarından,
müzik `tools/muzik_uret.gd` ile kodla üretilen chiptune.
