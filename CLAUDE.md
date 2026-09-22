# Derin Kazı — proje kuralları

Bu dosya her oturumda okunur. Kısa ve güncel tut.

## Ne bu

Yandan kesit kazı + gelişim oyunu (Godot 4.7.2). 250 m derinlikteki çekirdeğe in.
Arayüz, kod ve belgeler **Türkçe**. Değişken/fonksiyon adları da Türkçe.

## Motor ve ayarlar — değiştirme

- **GL Compatibility** renderer (tümleşik Intel UHD hedefi). `forward_plus` açma.
- Pixel art: `default_texture_filter=0` (nearest), `snap_2d_transforms_to_pixel`,
  `snap_2d_vertices_to_pixel`. Kamera yakınlaştırması **2x**, temel görüntü 640x360.
- Tüm `.gd` / `.tscn` / `.cfg` / `.md` dosyaları **BOM'suz UTF-8**.
- Ses veri yolları: `Master > Muzik`, `Master > Efekt` (`default_bus_layout.tres`).
- `Ses` autoload'u (`scripts/ses.gd`) efekt ve müziği yönetir; doğrudan
  `AudioStreamPlayer` eklemek yerine `Ses.cal("olay")` kullan. Müzik için
  `Ses.muzik_cal(ad, gecis)`: `gecis > 0` iki oyuncuyla crossfade (v0.6),
  0 anında değişim. Yeni bir parça eklersen `Ses.MUZIKLER` listesine de yaz —
  açılışta önyükleniyor ki web'de bant sınırında `load()` takılması olmasın.
- **Simge yazı tipi:** Godot'nun gömülü yazı tipinde `₺ ← ↑ → ↓ ▲ ▶ ▼ ◀ ✔ ■`
  yok; masaüstü sistem yazı tipiyle örter, **web örtmez** (kutu çıkar).
  `Ses._ready()` içindeki `Simgeler.kur()` bunu çözüyor — kaldırma.
  Yeni bir simge kullanmadan önce `assets/fonts/simgeler.ttf` kapsıyor mu bak
  (`Simgeler.eksikler()` testte tarıyor); kapsamıyorsa o simgeyi kullanma.

## Klasörler

```
scripts/ayarlar.gd        TÜM denge sabitleri — sayı değiştireceksen burası
scripts/dunya_uretici.gd  tohumdan karo üreten saf sınıf (Node değil) + fay hattı
scripts/dunya.gd          TileMapLayer, 16x16 chunk yönetimi, kazı + deprem farkı, keşif haritası
scripts/sis.gd            keşif sisi örtüsü (karo başına draw_rect; Sis.ortu saf ve testli)
scripts/deprem.gd         deprem hesabı + oyuncunun kararı (saf sınıf; uygulamak Dunya.degistir işi)
scripts/ipucu.gd          ipucu, deprem panosu ve mağaza satırları (saf sınıf; dokunmatik/masaüstü ayrımı)
scripts/tohum_kodu.gd     7 harflik paylaşılabilir tohum kodu
scripts/simgeler.gd       web'de eksik simgeler için yedek yazı tipi
scripts/durum.gd          koşu + ilerleme durumu, tüm ekonomi kuralları, istatistik sayaçları, işaret (saf sınıf)
scripts/arac.gd           hareket, kazma, hasar, aletler, animasyon kareleri (saf seçim)
scripts/oyun.gd           HUD, üs, müze, ışınlanma + işaret, tehlikeler, oyun hissi, bitiş dökümü
scripts/ses.gd            autoload: efekt/müzik (iki oyuncu, crossfade)/döngü sesi (matkap)/ayar
scripts/kayit.gd          kayıt yuvaları [oyun] · [gunluk] · [derin] (v0.6) · [oyuncu] toplamı (v0.7) ve ayarlar
scripts/ayar_panel.gd     ayarlar ekranının içeriği (menü + duraklatma ortak)
scenes/                   menu · oyun · kapak
tools/                    varlık üretimi, ekran görüntüsü ve kayıt fikstürü betikleri
tests/bot.gd              bot simülasyonu (Bot.MUKEMMEL / INSAN / INSAN_SISLI / INSAN_DERIN)
tests/veri/               gerçek eski sürüm kayıtları (kayit-v0.5.cfg) — uyumluluk testleri okur
tests/                    headless testler (çıkış kodu 0 = geçti)
yayin/                    itch sayfası, ekran görüntüleri, kapak, butler komutları
_eski/                    kullanımdan kalkmış dosyalar (silme yok, buraya taşı)
```

## Deprem bir karardır

`scripts/deprem.gd` yalnız dünyayı değiştirmiyor, oyuncunun bahsini de tutuyor:
uyarı süresi derinlikle uzar (`uyari_suresi`), yüzeye çıkan ikramiye alır
(`odul`), derinde kalan hasar yer (`hasar`, tavanı 2 — **deprem tek başına
öldürmez**), `karar()` ikisini birleştirir. Hepsi saf ve testli; sayıları
değiştirirsen `tests/test_calistir.gd` → `_deprem_testleri` ve
`tests/test_insan.gd` birlikte çalıştır. Üç sıkışma güvencesi (araç/üs/istasyon
çevresi, kapanan hücre hep kazılabilir, ilk 10 m sabit) dokunulmaz.
Aralık `Deprem.aralik(derin)` / `Durum.deprem_araligi()` (5, Derin Mod 4).
`tests/test_oynanis.gd` v0.6'dan beri depremi elle tetiklemekle kalmıyor,
**beş gerçek sefer** yaptırıp uyarının kendiliğinden başlamasını ve kararın üç
ucunu (yüzeye çık / derinde kal / istasyondan ışınlan) sahnede sınıyor —
sefer sayacına ya da uyarıya dokunursan önce onu çalıştır.

## Keşif sisi (v0.5)

Keşif `Dunya.kesfedilen` (PackedByteArray, hücre başına 1 bayt) içinde; kayda
`kesif` anahtarıyla deflate+base64 yazılır (`kesif_dizi` / `diziden_kesif`).
Kayıtta `kesif` yoksa (v0.4 kaydı) `Dunya.kur` kazılmış hücrelerin çevresini
açar — bunu kaldırırsan eski kayıt kapkaranlık açılır. Örtü `scripts/sis.gd`
karo başına `draw_rect` çizer; Light2D/occluder **kullanma** (tümleşik GPU).
Işık **yakıt harcamaz**, geliştirilmez — sis bilgi kısıtı, kaynak değil
(rakip analizi: "lamba yakıtı angarya"). Sayılar `Ayarlar` → keşif sisi bloğu;
ışık yarıçapını `Durum.isik_yaricap()` verir, botun `_kesfet`'i de onu okur (aşağıda).
Mini harita (`oyun.gd → _harita_boya`) keşfedilmemiş hücreyi boyamaz; radar
sisi **geçici** seyreltir, keşif saymaz. Işık yarıçapı artık sabit değil
**`Durum.isik_yaricap()`** (ilk oyun 5, Derin Mod 3, 7. eserle +1); sahne, `Sis`
ve bot hep bunu okur — `Ayarlar.ISIK_YARICAP`'ı doğrudan kullanma.

## Derinlik ambiyansı (v0.6)

`Ayarlar.AMBIYANS` dört bant: toprak (0) → kaya (40) → bazalt (150) → çekirdek
(210). Bant = müzik parçası + arka plan tonu (`$Arkaplan/Renk`) + parçacık
(sığda toz, derinde kıvılcım; `oyun.gd → _ambiyans_yenile`). Bant sınırı katman
sınırı DEĞİL (taş + sert taş tek bant): 4 parça yeter, 5. yalnız pck'yi büyütürdü.
Müzik geçişi `Ses.muzik_cal(ad, Ayarlar.MUZIK_GECIS)` ile çaprazlanır; iki
`AudioStreamPlayer` var, geçiş sırasında ikisi birlikte çalar
(`Ses.calan_muzik_sayisi()` testte 2 → 1). Parçalar `tools/muzik_uret.gd` ile:

```powershell
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik.wav          --ruh gizemli  --tohum 3
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_derin.wav    --ruh gergin   --tohum 3   # (v0.2'den)
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_bazalt.wav   --ruh gergin   --tohum 5 --olcu 8 --bpm 160   # --bpm olmadan 140 çıkar
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_cekirdek.wav --ruh cekirdek --tohum 2 --olcu 4
```

`cekirdek` ruhu v0.6'da eklendi (68 bpm, frigyen, davul yerine kalp atışı, ağır
notalar) — yeraltının ikinci ruhu. Parçacık sisin altında (z 5 < 15) çizilir ki
karanlıkta o da sönsün; Light2D yine yok.

## Derin Mod kimliği (v0.6)

Derin Mod artık yalnız çarpan değil. Üç fark tek yerden okunur (`scripts/durum.gd`):
- **`isik_yaricap()`** 3 karo (`Ayarlar.ISIK_YARICAP_DERIN`), 7. eserle 4.
- **`deprem_araligi()`** 4 sefer (`Deprem.ARALIK_DERIN`), ilk oyunda 5.
- **7. eser** (`Ayarlar.ESERLER[6]`, `derin: true`) yalnız Derin Mod'da bulunur ve
  **ilk gizli odada** gelir (`Durum.sonraki_eser`); ilk oyunda müzede bile
  görünmez. Eser sayıları `eser_sayisi()` / `eser_toplanan()` — `ESERLER.size()`
  yazma. Yeni eser eklersen `derin` bayrağına karar ver.

Kayıt: Derin Mod **kendi yuvasında** (`Kayit.DERIN`, `[derin]`); ana kayıt
(çekirdeği çıkarmış dünya, tünelleri) yerinde kalır. Giriş
`Kayit.derin_mod_hazirla()`: süren tur varsa ona döner, yoksa iki yuvanın eser
birleşimiyle bir üst seviyeyi kurar. v0.5 kaydı Derin Mod'u ana yuvada taşıyor
olabilir — olduğu gibi açılır, "Başla" ile sürer. Menüde sağ üstte rozet
(`$Rozet`, `_derin_yenile`). Ölçüm: `tests/test_insan.gd` Derin Mod x1'i 7 tohumda
ilk oyunla yan yana ölçer (`Bot.INSAN_DERIN`).

## Sunum ve işaret (v0.7)

- **Yüzey karosu:** 0. satırdaki TOPRAK `yuzey.png`'den çizilir (`Dunya.YUZEY_KAYNAK`
  = ikinci atlas kaynağı, `Ayarlar.YUZEY_VARYANT` sütun, seçim `yuzey_varyant(x)`).
  Karo TÜRÜ değişmedi: üretici, kazı, deprem ve kayıt hâlâ TOPRAK görür; yalnız
  `_parca_yukle` kaynak seçer. Yeni bir yüzey görünümü eklersen atlas türü ekleme.
- **Araç kareleri:** `arac.png` 9 kare — 0 bekle · 1-2 kazma · 3-5 palet · 6-8 alev.
  Düzen ÜÇ yerde aynı olmalı: `tools/sprite_uret.gd → _arac`, `Arac.KARE_*` sabitleri,
  `scenes/oyun.tscn` `hframes`. Kare seçimi saf (`Arac.animasyon_durumu /
  faz_ilerlet / kare_sec`), palet YOLLA döner (hız × süre / `PALET_PIKSEL`), yön
  `flip_h`. Bot ve ölçümler kareyi bilmez — öyle kalsın.
- **Matkap döngü sesi:** `Arac.kazma_degisti` sinyali → `Ses.dongu_baslat("matkap") /
  dongu_durdur`. Kazı kesilince `KAZMA_KUYRUK` (0,3 sn) kadar sürer: karo arası
  düşüşte ses kesilip baştan başlamasın. Durdurma 0,12 sn sönümle; `dongu_caliyor`
  sönmekte olanı "durdu" sayar. Döngü sonu yine `get_length() × mix_rate`.
- **Deprem sesi:** `deprem.wav` (uyarı `deprem_uyari`: aynı dosya tiz/kısık). Patlama
  sesi gaz, dinamit ve çekirdek için kaldı. İki dosya `tools/ses_uret.gd` ile
  sentezleniyor, TOHUM sabit, aynı komut aynı baytları verir (testi var).
- **Bitiş istatistiği:** koşu sayaçları `Durum` (kazilan_karo, deprem, olum =
  yüzeye çekilme, satis_toplam, sure); bütün yuvaların toplamı `[oyuncu]` bölümü.
  Her `_kaydet` `Kayit.oyuncu_biriktir(durum.istatistik_farki())` çağırır — fark
  yöntemi; kayıttan yüklenen değer aktarılmış sayılır, iki kez sayılmaz. Sayaç
  eklersen `istatistik()` sözlüğüne de yaz. Bitiş metni `bitis_metni` saf, 480 px'e
  sarılır; test panelin 640×360'a sığdığını ölçüyor.
- **Işınlama işareti:** `Durum.isaret` (yok = `ISARET_YOK`). R / gamepad B / İŞARET
  düğmesi (dokunmatik sol şerit, üçüncü) yeraltında koyar. Işınlanma panelinde
  satır; asansör kuralı aynı (üsten ya da istasyondan), TEK kullanımlık, gidince
  silinir. Deprem işaret hücresini kapatabilir (korunmuyor): `_isaret_isinla`
  varışta hücreyi açar. Eski kayıt `isaret` anahtarı olmadan açılır. Bot bilmez;
  birim test `tests/bot.gd` içinde "isaret" geçmediğini tarıyor.

## Kayıt uyumu

Eski sürümün kaydı yeni sürümde açılmalı. Fikstür **gerçek dosya**:
`tests/veri/kayit-v0.5.cfg`, v0.5 etiketinde `tools/kayit_fikstur.gd` ile üretildi
(git worktree → eski sürüm → betik). Kayıt biçimini değiştirirsen o dosyayı
elle düzenleme; testler (`_kayit_testleri`, oynanış testinin v0.5 bölümü) onu
olduğu gibi okumalı. Yeni etiketten fikstür üretmek için:

```powershell
git worktree add ..\derin-kazi-v0X v0.X
copy tools\kayit_fikstur.gd ..\derin-kazi-v0X\tools\
godot --headless --path ..\derin-kazi-v0X --import
godot --headless --path ..\derin-kazi-v0X --script res://tools/kayit_fikstur.gd -- --cikti <bu deponun kökü>/tests/veri/kayit-v0.X.cfg
git worktree remove ..\derin-kazi-v0X
```

## Dokunmatik düzen

Tüm dokunma alanları 640x360 içinde ve **birbirine binmez**: kazı alanları
`scenes/oyun.tscn` (`$Dokunmatik/*` TouchScreenButton), düğmeler
`oyun.gd → dokunmatik_kur` (sağ üst Üs·Harita·■, sol dikey DİNAMİT·RADAR·İŞARET,
y 100'den başlar — 148'de başlasa üçüncü düğme ◀ alanına binerdi).
`tests/test_oynanis.gd` dikdörtgenleri **sahneden okuyup** çakışma/taşma arıyor;
düğme ekleyeceksen önce onu çalıştır. Dinamit/radar mantığı
`_dinamit_kullan` / `_radar_degistir` içinde — tuş da düğme de oraya bağlı,
ikisine ayrı kod yazma. Mağaza/ipucu metinleri dokunmatikte tuş anlatmaz
(`Ipucu.MAGAZA`, testi var). Telefon oranı görseli: `docs/oyun-telefon.png`.

## Denge

Bütün sayılar `scripts/ayarlar.gd` içinde. Değiştirdikten sonra **mutlaka**
`tests/test_denge.gd` çalıştır: gerçek üretici ve ekonomiyle bir bot simüle edip
tur süresini, tur başına geliştirmeyi, 10. dakikayı ve katman başına geliri ölçer.

Bilinmesi gereken bağlar:
- **Maden ağırlığı** (`MADEN_AGIRLIK`) katman başına geliri ~x1,5'te tutan ayardır.
  Yalnız `MADEN_DEGER`'i büyütürsen gelir katman başına x2'nin üstüne çıkar.
- **`BEDAVA_YAKIT_ORAN`** kilitlenme önlemi: parasız + yakıtsız oyuncu kalmasın.
  Kaldırırsan simülasyon 88 m'de takılıp 0 gelirle döner.
- **Fay hattı** (`DunyaUretici._fay_kur`) dünyanın bitirilebilirlik garantisi.
  Koridorun içinde KAYA ve LAV üretilmez. Dokunursan `test_calistir.gd`
  BFS testi 12 tohumda da kırılır.
- **Oturum uzunluğu** `tests/test_insan.gd` ile ölçülür (insana benzetilmiş bot:
  tepki gecikmesi, duraksama, yanlış rota; v0.5'ten beri ana sayı **sisli**
  bot, yol bulması yalnız keşfedileni biliyor). Ölçülen (v0.5): tur 106 sn,
  çekirdeğe 25 dk — sisli ve sissiz aynı, çünkü fay koridoru botu tıkamıyor ve
  7 tohumda hiç BFS rotası kurulmuyor (`BFS rotası kurulan` satırı bunu yazar).
- **Bot yol bulma** `Bot._rota` (BFS, 80 karoluk pencere) sissiz botta tur başına
  **bir kez**, sisli botta en çok **üç kez** (`Bot.ROTA_EN_COK_SISLI`)
  hesaplanır; sınırı kaldırırsan ölçüm dakikalar sürer. `Bot._uretim` üreticinin
  önbelleği — üretici saf olduğu için güvenli, kaldırma.
  Testteki bantlar hedef değil **gerileme bekçisi** — denge sabitlerini
  değiştirince ikisini birlikte çalıştır.

## Test yazarken

- `--script` ile koşan SceneTree testlerinde autoload'a **adıyla** erişme
  (`Ses.x` → "Identifier not found: Ses" derleme hatası; tests/test_oynanis.gd'de
  başımıza geldi). `var ses = root.get_node("Ses")` (dinamik tip) kullan;
  `_ready` ilk kareden sonra koşuyor, önce `await process_frame`.
- Testte hata olursa `quit()` hiç çağrılmaz ve Godot **sonsuza kadar açık kalır**
  (kilit rejimi için önemli): süreci `Stop-Process` ile kapat, çıktıyı dosyaya
  yönlendir (`grep`'e borulanan çıktı süreç bitmeden görünmez).
- Sahne testinde ışınlanacağın hücreyi **o anda** hesapla; depremler arada
  hücreleri kapatıyor, bayat bir `Vector2i` seni kayanın içine koyar
  (`is_on_floor()` hep false, dinamit atılmaz).
- Sesi duyamıyoruz: müzikle ilgili bir değişiklikte `playing` ve
  `get_playback_position()`'ı birkaç saniye örnekleyen bir sonda yaz (v0.6'da
  `loop_end = 0` hatası böyle bulundu; varlık dosyasının varlığı hiçbir şeyi kanıtlamaz).
  `Ses.gecmis` son 32 olayı tutar: "hangi ses çaldı" sorusunu sahne testi oradan okur.
- `_initialize` sırasında **hiçbir düğüm ağaçta değil** (autoload `_ready` bile
  çalışmamış, `Ses.ayar` boş): `AudioStreamPlayer.play()` orada "not inside tree"
  der. Oynatıcı sınamaları sahne testine (`await` var) — birim testi yalnız saf
  sentez/tablo sınar (v0.7'de böyle bulundu).
- `is_on_floor()` son fizik adımının sonucudur: `usse_don()` / `isinlan()` ile
  havaya taşınan araç için bir kare daha "yerde" der. Yere oturmayı beklemeden
  önce `await _kare(2)`, sonra döngü.
- Headless'ta `ImageTexture.get_image()` boş döner; çizilen kareyi `Image` olarak
  sakla (`oyun.gd → _harita_son`) ve testte onu oku.

## Komutlar

```powershell
godot --headless --path . --import                                # içe aktar
godot --path .                                                    # oyna
godot --headless --path . --script res://tests/test_calistir.gd   # birim testleri
godot --headless --path . --script res://tests/test_oynanis.gd    # oynanış testi
godot --headless --path . --script res://tests/test_denge.gd      # denge simülasyonu
godot --headless --path . --script res://tests/test_insan.gd      # insan benzeri ölçüm
godot --headless --path . --script res://tests/test_fay_olcum.gd  # fay ölçümü + bot 12/12 sınaması (sisli insan botu dahil)
godot --path . --script res://tools/tanitim_al.gd                 # tanıtım kareleri (build/tanitim, ffmpeg ile GIF)
godot --headless --path . --script res://tools/sprite_uret.gd     # tüm pixel art (yuzey.png, 9 kareli arac.png, isaret.png dahil)
godot --headless --path . --script res://tools/ses_uret.gd        # matkap.wav (döngü) + deprem.wav, deterministik
godot --headless --path . --script res://tools/onizleme.gd        # sprite önizleme sayfası + docs/v07-kareler.png
godot --path . --script res://tools/ekran_al.gd                   # yayın görselleri (6 ekran + kapak) + telefon/deprem denetimi (render gerekir)
godot --headless --path . --script res://tools/kayit_fikstur.gd -- --cikti <dosya>   # kayıt fikstürü (eski sürümün worktree'sinde)
mkdir build\web, build\windows -Force   # hedef klasor yoksa Godot hata verir
godot --headless --path . --export-release "Windows Masaustu"
godot --headless --path . --export-release "Web (HTML5)"
```

**`export_presets.cfg` → `exclude_filter` boş bırakılmaz.** İki ön ayarda da
`tests/*, tools/*, docs/*, yayin/*` dışarıda; yoksa oyuncuya inen pakete ekran
görüntüleri, kapak, tanıtım GIF'i, itch sayfa metni, butler komutları ve test
dosyaları giriyor (ölçüldü: web pck 1.782.396 → 968.680 bayt). `.gdignore`
kullanılmıyor: `scripts/kapak.gd` çalışma anında `yayin/kapak-fon.png` okuyor,
`.gdignore` kapak üreticisini bozar; `exclude_filter` yalnız dışa aktarımı etkiler.

Müzik (ön ayarlar: hizli/neseli/sakin/gizemli/gergin/cekirdek; dört bandın komutları
"Derinlik ambiyansı" başlığında):
```powershell
godot --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik.wav --ruh gizemli --tohum 3
```

Godot yolu: PATH'teki `godot` (winget kurulumu `%LOCALAPPDATA%\Microsoft\WinGet\Links` altina ekler).

## Godot kilidi

Aynı anda birden çok oyun oturumu çalışıyor, RAM dar. Godot çalıştırmadan önce
depoların ortak üst klasöründe `.godot-kilit` dosyasını al (varsa ve 15 dk'dan yeniyse 30 sn bekle;
yoksa oluştur, içine `derin-kazi` yaz), iş bitince sil. Açık süreç bırakma.

## Yayın

**GitHub deposu var, itch.io yüklemesi yok.** Depo 21 Eylül 2026'da GitHub'a
taşındı (`Furkiozknn/derin-kazi`, varsayılan dal `main`); `main`'e her push'ta
`.github/workflows/ci.yml` iki test kapısını koşuyor. Yayın paketi yalnız
hazırlanır (`yayin/`), yükleme kararı Furki'nin. `yayin/butler-komutlari.md`
içindeki komutlar bilerek çalıştırılmamış durumda.

## Varlık üretimi

GUI aracı kullanılamıyor. Tüm pixel art `tools/sprite_uret.gd` içinde Godot
`Image` API'siyle üretiliyor; palet **Endesga 32** ve o dosya tek kaynak.
Elle PNG düzenleme yok — görseli değiştireceksen betiği değiştir ve yeniden üret,
sonra `tools/onizleme.gd` ile çıktıyı gözle denetle.

`karolar.png` **5 satır** ve satırın iki işi var:
- **taban kayaları** için satır bir doku varyantı (seçim hücrenin konumundan),
- **maden karoları** için satır bir KATMAN: damarın zemini o derinliğin kayası
  (`Ayarlar.varyant` madende `katman(y)` döndürüyor). Toprakta bakır kahverengi
  zeminde çıkıyor; v0.3'te her zemin aynı mavi-gri taştı ve sığda yamalı duruyordu.

`Ayarlar.VARYANT_SAYISI` = `Ayarlar.KATMANLAR.size()` = 5 ve `Dunya._tileset_kur()`
ile `tools/sprite_uret.gd` buna bağlı — birini değiştirirsen dördünü birden değiştir.

Ses efektleri rFXGen ön ayarlarından (rFXGen yerel bir kurulum, depoda değil).
`--generate` aynı ön ayar için **hep aynı** dalgayı veriyor (denendi), bu yüzden
çeşitlilik `scripts/ses.gd` içindeki perde eşlemesinden geliyor. rFXGen'in
veremediği iki ses (`matkap.wav` döngüsü, `deprem.wav`) `tools/ses_uret.gd` ile
kodla sentezleniyor — elle .wav düzenleme yok, betiği değiştir ve yeniden üret.
