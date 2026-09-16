# Derin Kazı

Yandan kesit görünümlü kazı + gelişim oyunu: matkaplı araçla yeraltına in, maden
topla, yakıt bitmeden yüzeye dön, sat, aracını geliştir, 250 m'deki çekirdeğe ulaş.

![Oynanış](yayin/ekran-2.png)

> Durum: **v0.5 — keşif sisi.** v0.4'ün üstüne: keşfedilmemiş yeraltı karanlık
> (aracın ışığı kalıcı açar, radar geçici, mini harita yalnız gezileni gösterir,
> kayda yazılır), telefonda **tam alet seti** (DİNAMİT · RADAR düğmeleri),
> deprem kararı ekranın ortasında üç satırlık pano + kırmızı işaret.
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

Dokunmatik cihazda ekranın alt sol / alt sağ / alt orta bölgesine dokunmak o yöne
kazar, üst ortadaki alan pervanedir. Klavye olmadığı için sağ üstte üç düğme var:
**Üs** · **Harita** · **■** (duraklat); sol ortada, ◀ alanının üstünde dikey iki
alet düğmesi: **DİNAMİT n** (sayaçlı, dinamit yokken sönük) · **RADAR AÇ/KAPA**
(radar alınmamışsa sönük). Menüdeki yardım, oyun içi ipuçları ve mağaza satırları
dokunmatik cihazda kendiliğinden düğmeleri anlatır (`docs/oyun-telefon.png`).

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
- **Maden radarı** (`Q`) — en yakın madenin yönünü ve uzaklığını HUD'a yazar;
  açıkken keşif sisini 9 karo yarıçapta **geçici** seyreltir (keşif saymaz).
- **Isı kalkanı** — lav yakınında hasar almazsın.
- **Dinamit** (`F`) — 3×3 patlatır, sarf malzemesi.
- **İstasyon kiti** (`T`) — 50 m aralıkla kurulur; istasyon ile yüzey arasında
  anında yolculuk.
- **Eserler** — gizli odalarda bulunur, müzeye gider, kalıcı pasif bonus verir.
  Altı eserin her biri çekirdeğin sırrından bir parça anlatır; 1'den 6'ya doğru
  okununca tek bir hikâye çıkar.

### Keşif sisi (v0.5)

Yeraltında yalnız gördüğün yer aydınlık. Aracın ışığı 5 karo yarıçapı **kalıcı**
açar (kenarı yumuşak), gezilmiş ama ışık dışında kalan yer loş bir "hatıra",
hiç gezilmemiş yer kapkaranlık; ilk 8 m'de gün ışığı sisi eritir. Işık **yakıt
harcamaz** — sis bir kaynak yönetimi değil, bir bilgi kısıtı. Radar açıkken 9
karo yarıçap geçici seyrelir. Mini harita yalnız keşfedileni boyar; keşif kayda
sıkıştırılmış yazılır, v0.4 kaydı açılınca kazılmış tünellerin çevresi
keşfedilmiş sayılır (kapkaranlık başlamaz). Madenler ve gaz cebi deseni ışığın
içinde olduğu gibi görünür: örtü ışığın içinde sıfır.

### Canlı yeraltı (v0.3) ve depremin kararı (v0.4, pano v0.5)

Her **5 seferde** (in-çık) bir deprem olur. Yeraltındayken önce **geri sayım**
başlar — kırmızı ekran işareti + ses, sarsıntı, ekranın üst-ortasında üç satırlık
pano: `DEPREM 7.4 sn` / `W ile YÜZEYE ÇIK → +… ₺ ikramiye` / `DERİNDE KAL → …
hasar` (son 3 saniyede sayaç yanıp söner; dokunmatikte `▲ UÇ ile`) — sonra:

- eski tünellerin ~%20'si kapanır,
- kalan tünellerin duvarlarında **yeni gaz cepleri ve maden damarları** belirir.

**Uyarı bir bahis (v0.4).** Süre derinlikle uzar (4 sn + derinlik × 0,06;
100 m'de 10 sn, 250 m'de 19 sn, tavan 20 sn) — ki karar verilebilsin. Sonra:

- **yüzeye çıkarsan** (12 m'den sığ) **kabuk nöbeti ikramiyesi** alırsın:
  25 ₺ + uyarı anındaki derinliğin. 100 m'den dönene +125 ₺.
- **derinde kalırsan** hasar yersin: 1 can, 100 m'den derinde 2. Tavan 2 —
  deprem **tek başına** bir koşuyu bitiremez.
- **kurduğun bir istasyondaysan** ışınlanıp ikramiyeyi bedavaya alırsın.
  İstasyonun ikinci gerekçesi bu.

Gerekçe rakip analizinden: Dome Keeper'ı tutan şey dalga sayacının kurduğu
"bir blok daha kazayım mı?" gerilimi. v0.3'te deprem saf bir olaydı — oyuncunun
verecek bir kararı yoktu. Hesap `Deprem.karar/odul/hasar/uyari_suresi` içinde
saf tutuldu: derinlik girer, sözlük çıkar; sahne gerekmez, test doğrudan sınar.

Üç kural kodda garanti altında (`scripts/deprem.gd`, testleri var):
aracın / üssün / istasyonların çevresine dokunulmaz · kapanan hücre **her zaman**
kazılabilir taban kayasıyla dolar, asla kazılamaz kaya ya da lavla değil ·
ilk 10 m hiç değişmez. Yani deprem seni hiçbir zaman kapalı bir boşlukta
bırakmaz; en kötü ihtimalle kendini yeniden dışarı kazarsın.

### Tohum kodu, günlük dünya, Derin Mod (v0.3)

- **Tohum kodu** — menüdeki "Tohum kodu" ekranı dünyanın 7 harflik kodunu
  gösterir ve başkasının kodunu almana izin verir. Alfabede `I`, `O`, `0`, `1`
  yok (elle yazarken karışıyor) ve kodun 3 bitlik sağlaması var: yanlış yazılan
  kod sessizce başka bir dünya açmaz, "geçersiz" der (tek harf hatalarının %87'si).
- **Günlük dünya** — tohum tarihten türer, herkeste aynıdır. **Ayrı kayıt yuvası**
  kullanır (`[gunluk]`), ana ilerlemene dokunmaz. Menüde o günün en derin noktası
  yazar; gün değişince yuva sıfırlanır.
- **Derin Mod** — çekirdeği bir kez çıkardıktan sonra menüde açılır. Yeni tohum,
  sıfırlanan geliştirmeler, **korunan eser bonusları** ve her turda artan zorluk:
  kaya %15 daha sert, yakıt %12 daha hızlı biter, maden %25 daha değerli.

## Verilen kararlar

- **Oturum uzunluğu: ilk oyun ~25 dk, uzun kuyruk Derin Mod'da.** Rakip
  analizindeki "çekirdeğe 60-90 dk" hedefi v0.3'te bilerek bırakıldı. Aynı
  analizde Motherload'ın şikâyeti "çok uzun, aynı şey farklı derinlik", A Game
  About Digging A Hole'ün şikâyeti "1-2 saat ve geliştirmeler erken bitiyor".
  İnsana benzetilmiş bot 7 tohumda çekirdeğe **25 dakikada** varıyor
  (`tests/test_insan.gd`); tur süresi 106 sn (v0.4 ölçümü: deprem kararı ve
  botun BFS rotası dahil). Bir oturumda bitirilebilen bir
  oyun + tekrar oynanabilir Derin Mod, 90 dakikalık bir tırmanıştan daha iyi bir
  bahis. Sayı kaymasın diye test bant bekçisi olarak duruyor.
- **Garantili fay hattı — yolu var etmek için değil, bulunabilir kılmak için.**
  Üsten çekirdeğe inen, kıvrımlı, 3 karo genişliğinde bir koridorda **asla**
  kazılamaz kaya ya da lav üretilmiyor; içi sıradan kaya ve madenle dolu, yani
  oyuncu koridoru göremiyor. Ölçüm (`tests/test_fay_olcum.gd`) beklediğimizi
  düzeltti: **fay kapalıyken de** 12 tohumun 12'sinde yüzeyden çekirdeğe
  kazılabilir bir yol vardı (BFS). Sorun yolun yokluğu değil, "aşağı kaz,
  tıkanınca yana git" diye oynayan birinin onu bulamamasıydı: aynı 12 tohumda
  bot fay kapalıyken **8/12**, açıkken **11/12** çekirdeğe varıyor.
  Dome Keeper şikâyeti ("kötü dünya üretimi oyunu bitirilemez yapıyor") bu
  oyunda dünyanın bitirilemez olmasıyla değil, geçilemeyecek kadar dolambaçlı
  olmasıyla ortaya çıkardı.
- **Karo varyantları doku, dünya değil.** Atlasın 5 satırı var. Taban kayaları
  için satır hücrenin konumundan türer (tohumdan değil), **maden karoları için
  satır = KATMAN**: damarın zemini bulunduğu derinliğin kayasıdır. Tehlike
  karolarının varyantı yok — gazın deseni bir bakışta tanınmalı.
  Asıl kusur dokunun tekrarı değil, her karonun üstte açık altta koyu olmasıydı:
  duvar 16 px'de bir çizgileniyordu. Degradenin karşıtlığı düşürüldü ve varyantlar
  arasında **yön değiştiriyor**.
- **Simgeler için ayrı yazı tipi.** Godot'nun gömülü yazı tipinde `₺ ← ↑ → ↓ ▲ ▶
  ▼ ◀ ✔ ■` yok. Masaüstünde sistem yazı tipi örtüyor, **web'de örtmüyor** — orada
  simge yerine içinde onaltılık kod yazan kutu çıkıyordu. `assets/fonts/simgeler.ttf`
  `Ses` autoload'unda yedek yazı tipi olarak zincire ekleniyor; test kodda geçen
  bütün simgeleri tarıyor.

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
- **Maden damarının zemini bulunduğu katmanın kayası (v0.4).** v0.3'te zemin her
  katmanda aynı nötr koyu taştı — gerekçe "bakır bazaltın içinde de çıkabiliyor"
  idi, ama sonuç toprak katmanında duvara yapıştırılmış **mavi-gri bir kare**
  oldu. Çözüm tek bir zemin seçmek değil, zemini derinliğe bağlamak: atlasın
  satırı artık katman. Bakır toprakta kahverengi, bazaltta gece mavisi bir
  zeminde çıkıyor; damarın rengi değişmiyor, madeni damar tanıtıyor.
- **İpucu metni tek yerde, saf bir sınıfta (v0.4).** `scripts/ipucu.gd` aynı
  durumu masaüstünde tuşlarla ("E — Üs"), dokunmatikte düğmelerle ("Üs düğmesi")
  anlatıyor. v0.3'te telefonda oyun içi ipucu hâlâ klavye anlatıyordu; metin
  sahnenin içine gömülü olduğu için hiçbir test göremiyordu. Şimdi test bütün
  ipucu durumlarını gezip dokunmatik metinlerde tuş adı arıyor.
- **Bot mini harita/BFS ile oynuyor (v0.4).** Tıkanınca körlemesine yana gitmek
  yerine rota çıkarıyor, sert kayada dinamit atıyor, radar alıyor ve depremi
  yaşıyor; 12/12 tohumda çekirdeğe varıyor (v0.3: 11/12). Bunun ölçtüğü şey
  "oyun bitirilebilir mi".
- **Sisli bot: ölçümün "fazla bilgi" sorunu kapandı, bedeli 0 çıktı (v0.5).**
  `Bot.INSAN_SISLI` yol bulurken yalnız keşfedileni biliyor, karanlığı "o
  katmanın sade kayası" sanıyor ve yanılınca rotayı yeniden kuruyor (tur başına
  en çok 3). Ölçüm: 7 tohumun **hiçbirinde** BFS rotası kurulmadı, 12 fay
  tohumunda fay açıkken toplam **1** rota, **0** yanılma — fay koridoru botu
  tıkamadığı için sissiz ve sisli bot aynı sayıları veriyor (tur 106 sn,
  çekirdek 25 dk). Yani sis botun değil oyuncunun problemi: bot çekirdeğin
  sütununu biliyor ve dümdüz iniyor, oyuncu koridoru yumuşak kayayı izleyerek
  bulmak zorunda. "Oyuncu yolu bulabilir mi" sorusunun cevabı hâlâ gerçek bir
  denemede; sis o denemeyi daha anlamlı yaptı.
- **Işık bedava, sis bilgi kısıtı (v0.5).** Rakip analizindeki SteamWorld Dig
  şikâyeti "lamba yakıtı angarya". Işık yakıt harcamıyor, büyütülmüyor,
  satın alınmıyor; sisin tek işi "orada ne var?" sorusunu geri getirmek —
  mini harita v0.2'den beri keşfedilmemiş alanı kapalı gösteriyordu ama oyun
  ekranı göstermiyordu, iki görünüm çelişiyordu. Çizim Light2D değil karo
  başına `draw_rect` (`scripts/sis.gd`): tümleşik GPU + GL Compatibility'de
  ekrandaki ~700 karo için bedava, occluder poligonu istemiyor.
- **Dokunmatik alet şeridi dikey ve solda (v0.5).** Sağ üstteki yatay şeride
  iki düğme daha 640 px'e sığmıyordu; büyütmek yerine ◀ alanının üstüne dikey
  ikinci şerit açıldı (`docs/oyun-telefon.png`). Sağ kenar mini haritanın yeri.
  Test sahnedeki gerçek dikdörtgenleri okuyup çakışma ve taşma arıyor — düzen
  veri olarak iki yere yazılmıyor.
- **Web çıktısı `thread_support` kapalı derlendi.** Prototip turunda itch'te
  "SharedArrayBuffer" kutusu gerekiyordu; artık düz bir statik sunucuda açılıyor.

## Çalıştırma

```powershell
godot --path . --import                                           # içe aktar
godot --path .                                                    # oyna
godot --headless --path . --script res://tests/test_calistir.gd   # birim testleri
godot --headless --path . --script res://tests/test_oynanis.gd    # oynanış testi
godot --headless --path . --script res://tests/test_denge.gd      # denge simülasyonu
godot --headless --path . --script res://tests/test_insan.gd      # insan benzeri ölçüm
godot --headless --path . --script res://tests/test_fay_olcum.gd  # fay ölçümü + bot 12/12 sınaması
godot --headless --path . --script res://tools/sprite_uret.gd     # tüm pixel art
godot --path . --script res://tools/ekran_al.gd                   # yayın görselleri
godot --path . --script res://tools/tanitim_al.gd                 # tanıtım kareleri (build/tanitim)
```

Tanıtım GIF'i (kareler alındıktan sonra):

```powershell
ffmpeg -y -framerate 12 -i build/tanitim/kare-%02d.png ^
  -vf "fps=12,scale=480:-1:flags=neighbor,split[a][b];[a]palettegen=max_colors=64[p];[b][p]paletteuse=dither=none" ^
  -loop 0 yayin/tanitim.gif
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
scripts/dunya.gd          TileMapLayer, 16x16 chunk, kazı farkı, keşif haritası
scripts/sis.gd            keşif sisi örtüsü (karo başına draw_rect; Sis.ortu saf)
scripts/durum.gd          koşu durumu + tüm ekonomi kuralları (saf, test edilebilir)
scripts/arac.gd           hareket, kazma, hasar, aletler
scripts/oyun.gd           HUD, üs, müze, ışınlanma, tehlikeler, oyun hissi
scripts/deprem.gd         deprem hesabı ve oyuncunun kararı (saf sınıf)
scripts/ipucu.gd          oyun içi ipucu metni; dokunmatik/masaüstü ayrımı (saf sınıf)
scripts/tohum_kodu.gd     7 harflik paylaşılabilir tohum kodu
scripts/simgeler.gd       web'de eksik simgeler için yedek yazı tipi
scripts/kayit.gd          kayıt yuvaları ([oyun] / [gunluk]) ve ayarlar
scripts/ses.gd            autoload: efekt/müzik/ayar
tools/                    varlık üretimi (pixel art, müzik, ekran görüntüsü)
tests/bot.gd              bot simülasyonu (kusursuz · insan benzeri · sisli insan)
tests/                    headless testler (çıkış kodu 0 = geçti)
yayin/                    itch sayfası, 5 ekran görüntüsü, kapak, tanıtım GIF'i, butler komutları
```

Kayıt dosyası: `user://kayit.cfg`
(`%APPDATA%\Godot\app_userdata\Derin Kazı\kayit.cfg`) — `[oyun]` ana ilerleme,
kazılan ve depremle değişen hücreler, keşif haritası (`kesif`: 17.408 bayt,
deflate + base64) · `[gunluk]` günlük dünyanın ayrı yuvası · `[ayar]`
ses/tam ekran/sarsıntı tercihleri.

## Varlıklar

GUI aracı kullanılmadı. Tüm pixel art `tools/sprite_uret.gd` içinde Godot `Image`
API'siyle üretiliyor (palet: **Endesga 32**). Ses efektleri rFXGen ön ayarlarından,
müzik `tools/muzik_uret.gd` ile kodla üretilen chiptune.
