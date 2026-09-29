# Tasarım — arayüz yenilemesi (v0.8)

Hedef: oyunu açan biri **tanıtım videosundaki dünyayı** bulsun — aynı renkler,
aynı yazı karakteri, aynı hareket dili. Çekirdek mekanik (kazı döngüsü, fizik,
katmanlar, deprem, keşif sisi, tohum kodu, Derin Mod, bot ve denge ölçümleri)
**değişmedi**: `tests/test_denge.gd`, `test_insan.gd` ve fay kapısı aynı
sayıları veriyor (tur 106 sn, çekirdeğe 25 dk, 7/7 ve 12/12). Bulgular
`docs/DENETIM.md`'de.

## 1. Videodan çıkarılan stil rehberi

Kaynak: `assets/sosyal/derin-kazi-dikey.mp4` (1080×1920, 15 sn) kareleri
(ffmpeg); renkler tek piksel örneklenerek alındı (29 Eylül 2026, sıkıştırma payı
±2). Marka tabanı (yazı tipleri, düğme, etiket, hareket) diğer oyunlarla ortak;
**dünya** derin-kazi'ye özgü.

| Öğe | Videoda ölçülen | Oyunda kullanılan |
|---|---|---|
| Zemin / tünel | `#1c130d` (tüneller), `#2d2019` (kabuk, gök) | `Tema.MUREKKEP`, `Tema.ZEMIN` |
| Toprak bantları | `#896843` (yüzey), `#6d4f33` (derin) | katman 1 ve 2; sert taş `#55402c`, bazalt `#3b2b20` bu iki değerin koyulaştırılmış devamı |
| Çekirdek kabuğu | `#571d13` | katman 5 (Çekirdek Kabuğu) ve çekirdek karosunun zemini |
| Matkap gövdesi | `#f3e8d7` | araç gövdesi, metin rengi (`Tema.KAGIT`) |
| Matkap ucu | `#e2552c` | araç ucu, çekirdek karosu |
| Maden karesi / vurgu | `#f3a33d` | altın damarı, birincil düğme dolgusu, en iyi / para vurgusu (`Tema.AMBER`) |
| Tehlike | `#e94f36` (marka tabanı; videoda yalnız uç `#e2552c`) | lav, deprem yazısı, azalan yakıt/can |
| Camgöbeği / yeşil | `#7dd4e7` (marka), `#6fc38a` (videodaki "SAT" damgası) | elmas, radar; gaz |

Video dünyasında **gölge, kontur, degrade yok**: büyük düz bantlar, düz kare
madenler, mono etiketler (`01 / DERİNE`, `245 m`). Oyun aynı dille yeniden
çizildi: `tools/sprite_uret.gd` artık Endesga-32 pixel art değil düz geometri
üretiyor. Boyutlar, atlas sütunları ve 9 karelik araç düzeni **aynı** kaldı
(motor, testler ve dünya üreticisi bunlara bağlı). Toprak karolarında yalnız
1-2 küçük koyu benek var (videodaki toprak benekleri); her satırda farklı yerde,
16 px'lik tekrar görünmesin diye.

Yazı: **Instrument Sans** (gövde, başlık) + **JetBrains Mono** (etiketler,
büyük harf, `01 / TOPRAK`); ikisi de OFL, `assets/fonts/` içinde lisans metniyle.
`₺ ← → ↑ ↓ ▲ ▼ ✔` bu yazı tiplerinde yok: yedek olarak `simgeler.ttf`
bağlandı (tema üretiminde her yazı tipinin `fallbacks` listesi).

### Şekil dili

| Öğe | Şekil |
|---|---|
| Araç | Kağıt rengi yuvarlatılmış kare gövde + koyu göz + kırmızı basamaklı üçgen uç; palet karesi (koyu şerit + amber dişler) yolla kayar; uçarken iki yanda alev. |
| Toprak / kaya | Tek renk kare, katman renginde; yüzeyde 2 px açık toprak bandı ve basamaklı üst kenar. |
| Maden | Katmanın zemininde iki düz kare (büyük + küçük), maden renginde. |
| Gaz | Yeşil kareler (kazmadan görünsün). |
| Gevşek kaya | Toprak zemininde iki koyu yarık. |
| Lav | Tehlike rengi düz kare, üstte amber şerit. |
| Sandık / eser | Amber yuvarlatılmış kutu / kağıt kare + amber çekirdek. |
| Çekirdek | Kırmızı kabuk + turuncu daire + kağıt kare. |
| Arka plan | Düz gök, basamaklı tepe silueti, amber pencereli düz bloklar (kasaba); yeraltında katman renginde düz zemin. Parlama yok. |

### Hareket dili

| Öğe | Süre | Yumuşatma |
|---|---|---|
| Menü öğeleri girişi | 220 ms, 40 ms arayla sırayla | ease-out cubic |
| Düğme basışı | 90 ms %96'ya küçülür, 120 ms geri | ease-out |
| Ekran geçişi (menü ⇄ oyun) | sekiz aileden biri (v0.9, §7): 260 ms örter, 200 ms açar | ease-out / ease-in cubic |
| Yüzeye çekilme | 300 ms tehlike rengi flaş + kısa sarsıntı; **girdiyi kilitlemez** | ease-out |
| Menü matkabı | 250 m'yi 14 sn'de "iner" (doğrusal), dibe varınca baştan | doğrusal |
| Araç | kazma / iniş ezilmesi (mevcut), toz parçacığı (mevcut) | rehberin yaylanma istisnası |

## 2. Ekranlar

| Ekran | Sahne | İçerik |
|---|---|---|
| **Başlangıç** | `menu.tscn` | Sol şerit: videodaki gibi düz toprak bantları, amber maden kareleri, ağır ağır inen matkap. Sağda `01 / YÜZEY` etiketi, **Derin Kazı** başlığı, tek satır slogan, büyük **Oyna** (birincil, ilk odak), altında **tek satır** kontrol yardımı, altında küçük ikincil düğmeler: Günlük dünya · Derin Mod (açıldıysa) · Yeni dünya (**iki adımlı**) · Tohum kodu · Ayarlar (· Çıkış yalnız masaüstü). En altta mono bilgi: tohum, para, en derin, eser. Sağ üstte Derin Mod rozeti. |
| **Oyun içi HUD** | `oyun.tscn` | Üst şerit: `YAKIT · YÜK · CAN · ₺` (tek renk mono; yalnız azalan yakıt ve tek kalan can kırmızı, dolu yük amber), sağda büyük derinlik. Altında `01 / TOPRAK · ÇEKİRDEK 250 m` + ince ilerleme çubuğu. Sağda zincir ve radar satırı yalnız gerektiğinde. Alt ipucu şeridi yalnız yazı varken görünür. Deprem panosu koyu bir bant üstünde. |
| **Duraklatma** | `oyun.tscn` | Devam (birincil, ilk odak) · Ayarlar · Menüye dön (kaydeder), üstünde **tam tuş listesi** (menüde tek satır olduğu için buraya taşındı). `Esc`; dokunmatikte ■ düğmesi. |
| **Oyun sonu** | `oyun.tscn` | `ÇEKİRDEK ÇIKARILDI!` (amber), süre · en derin · para · eser · tohum tek satır, bu dünya ve toplam istatistik, tek düğmeyle **Tekrar — Derin Mod x(n+1)** (birincil, ilk odak) ve Menüye dön. Yüzeye çekilince (can bitince) ekran kısa süre kırmızıya flaşlar; ücret ve yükün yarısı panelde. |
| **Ayarlar** | `ayar_panel.gd` | Müzik ve efekt (kaydırıcı + anahtar), ekran sarsıntısı, tam ekran (yalnız masaüstü), **Dil** (Türkçe ⇄ English). Menüde ve duraklatmadan aynı panel. |
| Mağaza / müze / ışınlanma | `oyun.tscn` | İçerik ve mantık aynı; opak koyu panel, kalın başlık, satırlar `Kucuk` düğme (dolgu, çizgi yok). |

### Önce / sonra

| Önce (v0.7.2) | Sonra |
|---|---|
| ![](tasarim/once-menu.png) | ![](ekran/menu_tr.png) |
| ![](tasarim/once-yuzey.png) | ![](ekran/hud_yuzey_tr.png) |
| ![](tasarim/once-oyun.png) | ![](ekran/hud_kazi_tr.png) |
| ![](tasarim/once-derin.png) | ![](ekran/hud_deprem_tr.png) |
| ![](tasarim/once-magaza.png) | ![](ekran/magaza_tr.png) |
| ![](tasarim/once-bitis.png) | ![](ekran/bitis_tr.png) |

Yeni ekranlar (önceki yapıda karşılığı yoktu ya da ayarda dil yoktu):

![ayarlar](ekran/ayarlar_tr.png)
![duraklat](ekran/duraklat_tr.png)
![çekilme](ekran/cekildin_tr.png)

İngilizce (tarayıcı dili Türkçe değilse varsayılan):

![menü](ekran/menu_en.png)
![ayarlar](ekran/ayarlar_en.png)
![duraklat](ekran/duraklat_en.png)
![oyun sonu](ekran/bitis_en.png)

Dokunmatik düzen (732×412):

![dokunmatik](ekran/dokunmatik_en.png)

## 3. Uygulama

- **Tema**: `assets/tema.tres`, `gui/theme/custom` olarak bağlı; `tools/tema_uret.gd`
  üretiyor (`godot --headless --path . -s res://tools/tema_uret.gd`, sonra
  `--import`). Tür varyasyonları: `Baslik`, `Baslik2`, `Govde`, `Etiket`,
  `EtiketKalin`, `Vurgu` (Label); `Birincil`, `Kucuk` (Button). Kaydırıcı
  tutamağı ve anahtar simgeleri temada kodla çiziliyor.
- **Renkler**: `scripts/tema.gd` (`Tema`). Dünya renkleri iki yerde aynı değerlerle
  duruyor: `tools/sprite_uret.gd` (görseller) ve `scripts/ayarlar.gd` (katman
  arka plan tonu, parçacık, sis).
- **Sahne geçişi**: `scripts/gecis.gd` (autoload `Gecis`: `git`, `kapat`, `ac`, `acilis`, `ara`,
  `vurus`, `yanip_son`) + `assets/gecis.gdshader`; kullanım yerleri §7'de.
- **Menü animasyonu**: `scripts/ui.gd` (`UI.sirayla_gir`, `UI.dugmeleri_bagla`).
- **TR/EN**: `scripts/ceviri.gd` + `scripts/ceviri_en.gd`. Kaynak dil Türkçe:
  `tr("Türkçe metin")` (static metotlarda ve sabit tablolarda `Ceviri.t`);
  İngilizce tablo `CeviriEn.EN`. Varsayılan dil `OS.get_locale_language()`
  (web'de `navigator.language`): `tr` → Türkçe, değilse İngilizce. Ayarlar'da dil
  düğmesi; seçim `user://kayit.cfg` `[ayar]` bölümünde **yeni** `dil` anahtarı,
  **eski anahtarlara ve kayıt yuvalarına dokunulmaz** (`_dil_testleri` eski biçimli
  kaydı okuyup en derin / para / tohum ve ses ayarının bozulmadığını sınıyor).
  `_ceviri_testleri`: koddaki ve sahnelerdeki her metin, katman/maden/geliştirme/
  alet adları, yedi eserin adı-bonusu-hikâyesi, tuş listeleri İngilizce tabloda var
  mı, `%d %s` belirteçleri çeviride aynı mı. `tools/ceviri_tara.py` eksikleri
  komut satırından listeler.
- **Yayın görselleri / kanıt**: `tools/ekran_al.gd` (yayın), `tools/kanit_al.gd`
  (TR/EN ekran seti), `tools/tanitim_al.gd` (GIF kareleri), `tools/kayit.ps1` +
  `tools/kayit.gd` (ham oynanış klibi).

## 4. Oynanış hissi — neden, ne ölçüldü

Ölçümler `tools/his_olc.gd` ile (pencereli, gerçek zaman, bu makine). **Bot
insanı temsil etmez**: girdiyi sentetik olay olarak gönderen bu araç bir
gösterge; süreleri gerçek insanla denemedim.

| Değişiklik | Neden | Ölçü |
|---|---|---|
| **Kazı hizalama** (`Arac.KAZI_HIZALAMA`): aşağı basılıyken ve altındaki hücre boşken araç sütunun ortasına doğru kayar. | 12 px'lik gövde 16 px'lik deliğe ortalanmadan basılınca kenarı komşu karonun köşesinde asılıp düşmüyordu; "aşağı" basılıyken araç duruyordu. | Delik ortasından −5…+5 px kaymış 11 başlangıç: **3/11 → 11/11 delikten düştü** (1,6 sn aşağı basılı). |
| **Dinamit kojotu 0,12 sn ve tamponu 0,12 sn** (`YER_KOJOT`, `DINAMIT_TAMPON`): zeminden yeni ayrılmışken `F` hemen atılır; havada basılan `F`, 0,12 sn içinde inilirse iner inmez atılır. | Karo kırılınca araç her seferinde ~0,47 sn'ye kadar boşlukta (yükseklikten): `F` "zemine bas" uyarısıyla boşa gidiyordu. Aralık platform oyunlarındaki yaygın 0,08-0,15 sn. | Düşüş 0,47 sn, `F` inişten *x* ms önce: **önce** 0 ms → 1/8, 40-240 ms → 0/8; **sonra** 0-120 ms → 8/8, 160 ve 240 ms → 0/8 (pencere dışı, beklenen). Kazma **değişmedi** (havada kazılmaz kuralı bu oyunun tasarımı). |
| Girdi gecikmesi (değiştirilmedi). | Kazma, yürüme ve pervane girdisi fizik adımında okunuyor. | Tuş olayı → ilk tepki, 40 deneme, rastgele faz: matkap sinyali **16,2 ms (%95 18,5)**, yürüyüş **32,3 (33,7)**, pervane **32,4 (33,9)** (ölçüm döngüsü fizik adımına bağlı olduğu için üst sınıra yakın; olay kareye birikip sonraki fizik adımında okunuyor). `input_devices/buffering/agile_event_flushing` ve `use_accumulated_input=false` denendi: fark yok (16,1 / 32,3 / 32,4), açılmadı. |
| Menüde tek büyük **Oyna**, tek satır kontrol yardımı; tam tuş listesi duraklatmada. | Denetim: yedi eşit düğme + beş satır soluk yazı. | `_yeni_arayuz_testleri`: odak Oyna'da, yardım tek satır, ikincil düğmeler 4-5, Derin Mod kilitliyken gizli. |
| "Yeni dünya" iki adımlı ("Emin misin? Tekrar dokun", 3 sn). | Tek tıkla ilerleme siliniyordu. | Aynı test: ilk basışta kayıt yerinde. |
| Duraklatmada ilk odak **Devam**'da; oyun sonunda ilk odak **Tekrar**'da (bir üst Derin Mod turu). | Denetim: oyun sonunda tekrar yoktu, metin duvarı. | Aynı test: odak, birincil varyasyon, panel 640×360'a sığıyor. |
| Yüzeye çekilirken 300 ms tehlike flaşı + sarsıntı (girdiyi kilitlemez). | Konum bir karede değişiyordu, geri bildirim yoktu. | Görsel (`kanit/derin-kazi/video`: ham klipte 11. sn). |
| HUD'da yalnız gerekli bilgi; renk yalnız uyarıda. | Beş renk bilgi taşımıyordu. | Test: yakıt %25 altında etiket uyarı renginde, katman çubuğu 125 m'de yarıda. |
| İlk oyunda öğretme (mevcut ipuçları korundu). | Menüdeki tuş dökümü ile çakışıyordu; artık menüde tek satır, oyunda ilk 3 m'de ve ilk maden alınınca bağlamsal ipucu. | Mevcut `_ipucu_testleri`. |

**Değişmeyenler (bilerek).** Fizik (yerçekimi 420, itki 620, hız 74), matkap
süreleri, denge sabitleri: `test_denge`/`test_insan` aynı. **Ölçülüp
değiştirilmeyen bir bulgu:** matkap en üst seviyedeyken (Sv5) aşağı basılı 12 sn'de
26 m iniliyor ve zamanın **%59'u boşlukta** geçiyor (karo başına 0,46 sn; her
karodan sonra ~0,28 sn serbest düşüş). Yüksek matkap seviyesinde kazı hızı düşüşle
sınırlı: gerçek oyuncuyla denenmeli, çekirdek mekaniğe dokunmamak için bu turda
bırakıldı. **Kojot, tampon ve hizalama değerleri bir insanla denenmedi.**

## 5. Performans ve boyut (önce / sonra)

Ölçüm: `tools/fps.gd` (gerçek render, Intel UHD, vsync kapalı, 90 kare ısınma +
600 kare, 60 m derinlikte açık oda, aşağı/sağ kazı girdisi). Eski ve yeni yapı
**aralıklı** üçer kez koşuldu (makinede başka süreçler var); tabloda medyan.

| | Önce (`05ed385`) | Sonra |
|---|---|---|
| Kare süresi (ort. / %99), medyan | 2,56 ms / 4,48 ms (≈391 FPS) | 2,83 ms / 4,28 ms (≈353 FPS) |
| Koşular (ort. ms) | 2,95 · 2,56 · 2,53 | 2,84 · 2,83 · 2,75 |
| `index.pck` | 970.752 bayt | 1.220.160 bayt (+249.408: dört yazı tipi + tema) |
| `index.wasm` | 39.514.754 bayt | 39.514.754 bayt (motor, aynı) |
| `index.js` | 279.815 bayt | 279.815 bayt |
| Toplam (pck+wasm+js) | 40.765.321 bayt | 41.014.729 bayt (**+%0,61**) |
| Testler | 304 birim + 156 oynanış + 7 denge + 10 insan | 333 birim + 191 oynanış + 7 denge + 10 insan (v0.9: 358 + 238, §7) |

Hedef 60 FPS'nin çok üstünde. Sonrası ortalamada ~%10 yavaş; nedeni ölçülmedi
(HUD bandı, tema ile çizilen paneller ya da yeni yazı tipleri olabilir). Efektler
`intel-uhd-2d-tavani` sınırının altında: yeni parçacık ya da `Area2D` eklenmedi.

## 6. Bilinen sınırlar

- Tarayıcı denetimi masaüstü Chromium'dadır; gerçek telefon, Safari ve Firefox
  denenmedi. Tarayıcının dili Türkçe olmayan bir makinede otomatik dil seçimi
  **tarayıcıda gözle doğrulanmadı** (Godot `OS.get_locale_language()` web'de
  `navigator.language` okur; birim test bu çağrıyı taklit eder). Ayarlar'daki
  dil düğmesi menüde ve oyunda test edildi.
- Testler düğmelerin bağlı olduğunu ve odak/panel davranışını sınar; `Gecis.git`
  (bant + sahne değişimi) `--script` testinde çalıştırılmadı, yalnız tarayıcıda
  gözle doğrulandı (menü → oyun, oyunda `Esc` → duraklat).
- Eser hikâyeleri ve mağaza satırları İngilizce çevrildi ama bir anadili
  İngilizce olan biri tarafından okunmadı.
- Videodaki başlık yazı tipi (Archivo benzeri geniş grotesk) oyunda yok; marka
  tabanı (Instrument Sans) kullanıldı.
- Ham oynanış klibi bir bot kaydıdır (tepki bandı 0,14-0,30 sn); insan oyunu
  değildir. Tanıtım reel'i (`docs/reel`) profil deposunun video hattından geliyor,
  bu depoda yeniden üretilemez; **olduğu gibi bırakıldı**.
- Canlı (eski) sayfada açılışta `Attachment has zero size` WebGL uyarıları vardı;
  yeni yapıda yerel oturumda görülmedi; menü matkabındaki `Polygon2D` iki WebGL uyarısı
  veriyordu, basamaklı `ColorRect` satırlarına çevrilince kayboldu.

## 7. Günlük video imkânlarından alınanlar (v0.9)

İstek: günlük videolarda kullanılan renk ve geçiş imkânları oyunda da kullanılsın, kısıtlanmasın;
**oyunun kendi kimliği ağır bassın**. Dünya değişmedi: hâlâ düz renk, gölgesiz, koyu kahve zemin.
Videodan yalnız *hareket ve renk akışının yapısı* alındı; renklerin kendisi derin-kazi'nin
tanıtım videosundan örneklenmiş dünya renkleridir (§1).

### Neyi nereden aldım

| Alınan | Kaynak | Oyunda |
|---|---|---|
| Renk akışı yapısı (sırayla dönen vurgu paleti, yazı rengi kodla seçilir) | `sosyal/uret/tema.mjs` → `TEMALAR.*.akis` (`renkAkisi`, `ESIK`) | `Tema.AKIS`, `Tema.akis_rengi`, `Tema.yazi_rengi` |
| Palet 0 (toprak + kaya) | `klasik` akışı: sakin yoğunluk, 5 vurgu (sarı, camgöbeği, turuncu, mercan, krem) | derin-kazi renkleriyle: amber `#f3a33d`, elmas camgöbeği `#7dd4e7`, uç turuncusu `#e2552c`, gaz yeşili `#6fc38a`, kâğıt `#f3e8d7`; zemin `#1c130d` |
| Palet 1 (bazalt + çekirdek) | `klasik` + `harita` (sıcak turuncu / kum) ailesi | uç turuncusu, sarı `#ffc21a`, tehlike `#e94f36`, amber, kâğıt |
| Kontrast kuralı | `tema.mjs` `ESIK = 5` | **4,5:1**, kodla hesaplanıp testte sınanıyor (oyunda doku/vinyet payı yok, istek 4,5). Yazı/vurgu en düşük **4,85** (uç turuncusu üstünde koyu yazı), vurgu/koyu dünya en düşük 4,85 |
| Geçiş aileleri | `sosyal/uret/sahne.js` `GECIS` + `tema.mjs` `gecis` havuzları | `assets/gecis.gdshader`: **iris, glitch, bloklar, itme, perde, flaş, kararma, zoom** (sekizi de) |
| Havuzun sırayla gezilmesi (art arda tekrar yok) | `gecisHavuz` mantığı | `Gecis.sec(tema)` |

Alınmayanlar: `kes`, `yatay`, `tarama` (itme/perde ile aynı iş), `warp` ve `çöküş` (uzay ve CRT
temalarının imzası; bu dünyada karşılığı yok), `piksel` (bloklar zaten maden karelerini anlatıyor).
`kes` (sert kesme) zaten **Sade geçişler** kipinin kendisi.

### Havuzlar ve gerekçeleri

| Palet | Havuz (sırayla) | Neden bu oyunda |
|---|---|---|
| 0 toprak + kaya (0-149 m) | itme, bloklar, iris, perde | itme = eski amber bandın devamı; bloklar = maden kareleri; iris = matkap deliği; perde = tünel |
| 1 bazalt + çekirdek (150 m+) | glitch, zoom, flaş, kararma | derinde gerilim: yarıklar, dalış, çekirdek ışığı, karanlık |

`Tema.derinlik_temasi(d)` bandı `Ayarlar.AMBIYANS`'tan okur (bazalt bandı = 150 m).

### Kullanım yerleri

| An | Geçiş | Süre | Bekletir mi |
|---|---|---|---|
| Menü açılışı (yalnız ilk açılış) | iris | 0,5 sn | hayır |
| Menü → oyun (Oyna, Yeni dünya, Günlük, Derin Mod, tohum kodu) | zoom | 260 + 200 ms | sahne değişimi süresince (eskisiyle aynı) |
| Oyun → menü | perde | 260 + 200 ms | aynı |
| Oyun sonundan "Tekrar" | bloklar (çekirdek paleti) | 260 + 200 ms | aynı |
| Işınlanma | bloklar (varış derinliğinin paleti) | ~180 + 200 ms | ışınlanma eskiden 200 + 200 ms'ydi; girdi kilidi yok |
| Duraklatma açılışı | perde | 0,22 sn | hayır |
| Oyun sonu kartı | iris | 0,45 sn | hayır |
| Çekirdeğe dokunuş | flaş (tek vuruş) | 0,45 sn, tepe %50 | hayır |
| Deprem | glitch (tek vuruş) | 0,35 sn, tepe %50 | hayır |
| Yüzeye çekilme | tehlike renginde flaş | 0,30 sn, tepe %34 | hayır (eskiden de öyleydi) |
| Dil değişimi (ayarlar) | glitch, örtü altında metin değişir | ~0,18 + 0,20 sn | hayır; geçiş sürüyorsa değişiklik efektsiz yapılır (kaybolmaz) |
| Derinlik sayacı | her yeni 25 m'de akış rengi, 0,3 sn | 0,3 sn | hayır |
| YENİ REKOR damgası | en derin (25 m ve üstü) aşılınca; renkler 90 ms adımla döner, sonra ilk renkte durur | 2,6 sn | hayır |

Tek vuruşlar (`Gecis.vurus`) oyun akışını ve girdiyi hiç kilitlemez; başka bir geçiş sürerken yok sayılır.
Oyun içindeki eski siyah solma (`Karartma`) kaldırıldı; sahne artık `Gecis` örtüsünün altından açılıyor.

### Hareket azaltma

Ayarlarda **Sade geçişler** (`[ayar] sade_gecis`, varsayılan kapalı) ve tarayıcıda
`prefers-reduced-motion: reduce`: geçişler **anında** (efekt yok, bekleme yok), sayaç ve damga
renk akışı yok (damga tek renk). Tek vuruşlar da kapanır. Testte: sade kipte üç geçiş + vuruş + çekilme
flaşı 100 ms altında bitiyor ve kaplama hiç açılmıyor.

### Ölçüm (Intel UHD 620 sınıfı tümleşik, `tools/fps.gd`, 60 m, vsync kapalı)

| | Ort. ms | %99 ms | FPS |
|---|---|---|---|
| Önce (v0.8, geçişsiz) — üç koşu medyanı | 3,15 | 4,88 | ≈317 |
| Sonra (v0.9, geçişsiz) — üç koşu medyanı | 2,68 | 4,00 | ≈373 |
| Sonra, geçiş sürerken (`fps.gd ... gecis`, 8 ailenin hepsi, ~1000 kare) — iki koşu | 3,41-3,43 | 4,84-5,05 | ≈292 |

Önce/sonra koşuları aynı makinede ama farklı zamanlarda; makinede başka Godot süreçleri de çalışıyordu,
"sonra"nın daha hızlı çıkması gerçek hızlanma sayılmaz (fark gürültü içinde). Geçiş sürerken kare
süresi ~0,7 ms artıyor, 60 FPS hedefinin (16,7 ms) çok altında. İki koşudan birinde tek kare 139,6 ms
çıktı (ilk kullanımda bir kez; öbür koşuda en kötü kare 7,5 ms): tek seferlik, bir geçiş ilk kez
çizilirken olası bir takılma; tekrar üretilmedi, nedeni ölçülmedi. `index.pck` 1.220.160 → 1.224.432 bayt.

### Kanıt

Kareler `docs/ekran/gecis-*.png` (`tools/gecis_kanit.gd`; sekiz aile yarım örtüde, YENİ REKOR,
çekilme flaşı, deprem glitch'i), ham klip `sosyal/medya/oyunlar/derin-kazi.mp4` (19 sn, sekiz ailenin
hepsi; `tools/kayit.gd` `OLAYLAR`).

| | |
|---|---|
| ![itme](ekran/gecis-itme.png) | ![bloklar](ekran/gecis-bloklar.png) |
| ![glitch](ekran/gecis-glitch.png) | ![zoom](ekran/gecis-zoom.png) |
| ![yeni rekor](ekran/yeni-rekor-damga.png) | ![deprem](ekran/deprem-glitch.png) |

### Sınırlar

- Geçişlerin gerçek telefon, Safari ve Firefox'ta görünümü denenmedi; Chromium'da menü → oyun,
  duraklat açıldı, konsol temiz. `prefers-reduced-motion` yolu tarayıcıda emüle edilmedi (kod
  `JavaScriptBridge.eval` ile okuyor; birim testi ayar yolunu sınıyor).
- Flaş ve glitch fotosensitif kişiler için rahatsız edici olabilir: en parlak vuruş çekirdek flaşı (%50
  krem, 0,45 sn, oyunda bir kez). **Sade geçişler** bunu kapatır; ayar ayarlar ekranında görünür.
- `Gecis.git` (sahne değişimi) `--script` testinde koşmaz (SceneTree'de mevcut sahne yok); tarayıcıda
  gözle doğrulandı.
