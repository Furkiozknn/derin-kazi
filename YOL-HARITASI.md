# Yol haritası — Derin Kazı

## Prototip turunda yapıldı (2026-09-16)

- [x] Tohumla üretilen dünya, parça parça üretim, derinliğe göre maden dağılımı
- [x] Matkaplı araç: sağ/sol/aşağı kazar, yukarı kazamaz, pervaneyle yükselir
- [x] Yakıt + yük kapasitesi, üs menüsü, 3 geliştirme, çekirdek bitiş ekranı
- [x] Ana menü, duraklatma, kayıt, klavye + gamepad
- [x] Windows ve Web dışa aktarımı

## Geliştirme turu 1 — v0.2 (2026-09-16)

### Dünya ve ilerleme
- [x] **16×16 chunk**: yalnız aracın çevresindeki 3×3 chunk `TileMapLayer`'da,
      uzaktakiler boşaltılıyor. Ölçüm: 17.408 karonun ~1.400'ü bellekte, 32 MB
- [x] **Kazı kaydı**: kırılan hücreler `Dictionary` farkı olarak kayda yazılıyor,
      oyun kapatılıp açılınca tüneller yerinde kalıyor
- [x] **5 katman** (0/40/90/150/210 m): kendi paleti, sertliği, matkap kapısı,
      madeni ve tehlikesi
- [x] **İlerleme eğrisi**: fiyat `taban × 1,35^seviye`, maden ağırlığıyla katman
      başına gelir ~×1,3; bot simülasyonu ölçüyor
- [x] İlk 10 m'de elle yerleştirilmiş bakır damarı
- [x] Denge sabitlerinin tamamı `scripts/ayarlar.gd` içinde

### Oynanış
- [x] **Yumuşak yakıt cezası**: ölüm yok, yüzeye çekilme + ücret, yükün yarısı
      olduğu yerde sandık olarak kalıyor ve geri alınabiliyor
- [x] **İstasyon / asansör**: 50 m aralıkla kurulur, yüzey ↔ istasyon anında
      yolculuk (yalnız bir duraktayken)
- [x] **Önceden uyarılan tehlikeler**: gaz cebi, düşen kaya, lav
- [x] **Araç canı** + gövde zırhı geliştirmesi, düşme hasarı
- [x] **Mağara ve gizli odalar**, **müze** (6 eser), **alet = yeni hareket**,
      **kazı zinciri**, **kaçış finali**, **mini harita**, **dokunmatik**

### Sunum
- [x] **Gerçek pixel art**, tamamı kodla üretiliyor (Endesga 32)
- [x] **Ses**: 11 olay, 3 müzik döngüsü, `Muzik`/`Efekt` veri yolları
- [x] **Ayarlar ekranı**, **oyun hissi** (parçacık, sarsıntı, esneme, kararma)

### Doğrulama ve paket
- [x] 121 birim + 31 oynanış sınaması + bot denge simülasyonu
- [x] Windows + Web dışa aktarımı, web `thread_support` kapalı
- [x] `yayin/` paketi, `CLAUDE.md`

## Geliştirme turu 2 — v0.3 "Canlı Yeraltı" (2026-09-16)

### Web hataları (bulutta Chromium'da bulundu)
- [x] **Simge yazı tipi.** `₺ ← ↑ → ↓ ▲ ▶ ▼ ◀ ✔ ■` web'de kutu çıkıyordu.
      `assets/fonts/simgeler.ttf` + `Simgeler.kur()` `Ses` autoload'unda.
      Test kodda geçen bütün simgeleri tarıyor: `Simgeler.eksikler(...) == ""`
- [x] **Menü arka planı ekranın altını doldurmuyordu.** Şehir siluetinin altındaki
      düz siyah bant (sabit konumlu `ColorRect`) yerini alta sabitlenmiş, döşenmiş
      toprak dokusuna bıraktı. 1280×720 ve 732×412 (telefon oranı) ekran
      görüntüsüyle doğrulandı — `yayin/ekran-5-menu.png`, `docs/menu-telefon.png`
- [x] **Dokunmatik yardım.** Dokunmatik algılanınca menü yardımı dokunma alanlarını
      anlatıyor; metin alta sabit, 10 px, telefon oranına sığıyor. Ayrıca oyunda
      klavye olmadığı için sağ üste **Üs · Harita · ■** düğmeleri eklendi

### Sunum
- [x] **Karo çeşitliliği.** Her taban kayasının 3 varyantı (kodla üretiliyor),
      seçim hücrenin konumundan belirlenimci. Asıl kusur dokunun tekrarı değil
      her karonun üstte açık altta koyu olmasıydı — degradenin karşıtlığı düştü
      ve varyantlar arasında yön değiştiriyor

### Oynanış
- [x] **Canlı yeraltı.** Her 5 seferde bir deprem: yeraltında 3,5 sn uyarı
      (sarsıntı + metin), sonra tünellerin ~%20'si kapanır, kalan tünellerin
      duvarlarında yeni gaz cepleri ve damarlar belirir. Üç güvence testli:
      araç/üs/istasyon çevresi korunur · kapanan hücre her zaman **kazılabilir**
      kayayla dolar · ilk 10 m değişmez
- [x] **Eser hikâyesi.** 6 eserin her biri çekirdeğin sırrından bir parça anlatıyor;
      müze ekranında numaralı ve sırayla okunuyor
- [x] **Tohum kodu.** 7 harf, karışmayan alfabe (I/O/0/1 yok), 3 bitlik sağlama.
      Menüde göster / gir
- [x] **Derin Mod.** Çekirdekten sonra açılıyor: yeni tohum, sıfırlanan geliştirme,
      korunan eser bonusları, turda %15 sert kaya / %12 yakıt / %25 maden değeri
- [x] **Günlük dünya.** Tarihten tohum, ayrı kayıt yuvası (`[gunluk]`), menüde
      günün en derin noktası. Ana ilerlemeye dokunmuyor

### Ölçüm ve dünya garantisi
- [x] **Garantili fay hattı.** Üsten çekirdeğe inen 3 karo genişliğinde koridorda
      kazılamaz kaya ve lav üretilmiyor (12 tohumda test edildi).
      Ölçüm beklentiyi düzeltti: BFS zaten fay olmadan da 12/12 geçiyordu —
      dünya bitirilemez değildi, yol **bulunamıyordu**. Aynı 12 tohumda bot
      fay kapalıyken 8/12, açıkken 11/12 çekirdeğe varıyor
      (`tests/test_fay_olcum.gd`)
- [x] **İnsan benzeri ölçüm.** `tests/bot.gd` iki ayarla çalışıyor: kusursuz bot
      (ekonominin eğrisi) ve insan benzeri bot (tepki gecikmesi ×1,30 · yön
      kararı 0,35 sn · %7 duraksama · %12 yanlış rota · üste 22 sn).
      7 tohumda ölçüldü, tablo raporda
- [x] 172 birim + 45 oynanış sınaması + iki bot ölçümü + fay etkisi ölçümü

## Geliştirme turu 3 — v0.4 "Derin Kazı'nın kararı" (2026-09-16)

### Deprem artık bir bahis
- [x] **Uyarı derinliğe göre uzuyor**: 4 sn + derinlik × 0,06 (100 m'de 10 sn,
      250 m'de 19 sn, tavan 20 sn). HUD'ın alt satırında **geri sayım** var ve
      kararın iki ucunu birden yazıyor
- [x] **Yüzeye çıkan kazanır**: kabuk nöbeti ikramiyesi = 25 ₺ + uyarı anındaki
      derinlik (100 m'den dönene +125 ₺). **Derinde kalan öder**: 1 can, 100 m'den
      derinde 2. Hasarın tavanı 2 — deprem **tek başına öldürmez**, koşuyu
      bitiren şey hâlâ oyuncunun yakıt/can yönetimi
- [x] Hesap `Deprem.karar/odul/hasar/uyari_suresi` içinde **saf**: derinlik girer,
      sözlük çıkar. v0.3'ün üç sıkışma güvencesi aynen duruyor
- [x] Üçüncü seçenek istasyon: bir durakta ışınlanıp ikramiyeyi bedavaya almak.
      İstasyonun v0.3'te olmayan ikinci gerekçesi

### Botun yol bulması
- [x] **BFS rotası** (`Bot._rota`): tıkanınca körlemesine yana gitmek yerine mini
      harita bilgisiyle çekirdeğe (ya da penceredeki en derin noktaya) rota çıkarıp
      izliyor. Pencere 80 karo aşağı / 12 karo yukarı; önce gaz cebine girmeyen
      yol aranıyor
- [x] **Dinamit ve radar**: sert kayada (sertlik ≥ 1,2) 3×3 patlatma, para artınca
      radar alıp yandaki madeni 5 karo uzaktan görme
- [x] **Bot artık depremi yaşıyor**: uyarı süresi tırmanışa yetiyorsa (ya da
      istasyon duraktaysa) yüzeye çıkıp ikramiyeyi alıyor, yetmiyorsa hasar yiyor
- [x] **12/12 tohumda çekirdeğe varılıyor** (v0.3: 11/12; tohum 3 tıkanıyordu).
      `tests/test_fay_olcum.gd` artık ölçmekle kalmıyor, sınıyor (çıkış kodu)
- [x] İnsan benzeri ölçüm deprem kararlı hâliyle yeniden çalıştırıldı:
      tur 106 sn, çekirdeğe 25 dk, 7/7 tohum (tablo raporda)

### Sunum ve dokunmatik
- [x] **Dokunmatik ipuçları düğmelere göre**: `scripts/ipucu.gd` saf sınıfı iki
      metni de tek yerden veriyor; masaüstü metni harfi harfine aynı kaldı.
      Test bütün ipucu durumlarını gezip dokunmatik metinlerde klavye tuşu
      aramıyor mu diye tarıyor
- [x] **Maden damarının zemini artık katmanın kayası**: atlas 5 satır, satır =
      katman (`Ayarlar.varyant` madende `katman(y)` döndürüyor). Toprakta bakır
      kahverengi zeminde, bazaltta gece mavisi zeminde çıkıyor —
      v0.3'teki "yapıştırılmış mavi-gri kare" gitti (`yayin/ekran-2.png`)
- [x] **Tanıtım GIF'i** `yayin/tanitim.gif` (480×270, 12 fps, 4 sn): kazı → maden
      → deprem uyarısı → deprem. Kareler gerçek oyundan (`tools/tanitim_al.gd`),
      GIF ffmpeg ile

### Doğrulama
- [x] 191 birim + 50 oynanış sınaması, denge ve insan ölçümleri, fay/bot sınaması
- [x] Windows + Web dışa aktarımı, 5 ekran görüntüsü + kapak yenilendi

## Geliştirme turu 4 — v0.5 "Keşif sisi" (2026-09-16)

### Dokunmatikte tam alet seti
- [x] **DİNAMİT · RADAR düğmeleri**: sol ortada, ◀ alanının üstünde dikey şerit;
      dinamit sayaçlı ve yokken sönük, radar AÇ/KAPA ve alınmamışsa sönük.
      Sağ üstteki Üs · Harita · ■ şeridi yerinde. Tuş ve düğme aynı iki
      fonksiyona bağlı (`_dinamit_kullan`, `_radar_degistir`)
- [x] **Mağaza satırları dokunmatikte düğmeyi anlatıyor** (`Ipucu.MAGAZA`):
      "F ile" → "DİNAMİT düğmesi ile", "Q —" → "RADAR düğmesi —", "T ile" →
      "Üs düğmesi ile"; test tuş adı arıyor
- [x] **Çakışma testi**: oynanış testi sahnedeki 4 kazı alanı + 5 düğmenin
      dikdörtgenlerini okuyup 640×360'a sığdıklarını ve birbirine binmediklerini
      sınıyor; düğmelere basınca dinamit atıldığı / radar açıldığı da sınanıyor.
      `docs/oyun-telefon.png` (telefon oranı) ile gözle doğrulandı

### Keşif sisi
- [x] **Keşfedilmemiş karo karanlık**, aracın 5 karo ışığı kalıcı açar (kenarı
      yumuşak), gezilmiş yer loş hatıra, ilk 8 m gün ışığı. Işık yakıt harcamaz
- [x] **Radar sisi geçici açar** (9 karo, keşif saymaz); mini harita yalnız
      keşfedileni boyar; istasyon/sandık işaretleri de keşfedilmemişse gizli
- [x] **Kayıtla uyumlu**: keşif haritası deflate+base64 (`kesif`, ~100-4000
      karakter); v0.4 kaydı açılınca kazılmış tünellerin çevresi keşfedilmiş sayılır
- [x] **Çizim karo başına `draw_rect`** (`scripts/sis.gd`), Light2D yok;
      `Sis.ortu` saf ve 13 sınamayla testli. Madenler ve gaz deseni ışığın
      içinde olduğu gibi (`yayin/ekran-2.png`, `ekran-4.png`)
- [x] **Bot varyantı `Bot.INSAN_SISLI`**: yol bulma yalnız keşfedileni biliyor,
      karanlığı sade kaya sanıyor, yanılınca rotayı yeniden kuruyor (≤ 3/tur).
      Ölçüm 7 tohumda yenilendi: **sisli = sissiz** (tur 106 sn, çekirdek 25 dk),
      çünkü 7 tohumun hiçbirinde BFS rotası kurulmuyor; 12 fay tohumunda fay
      açıkken toplam 1 rota, 0 yanılma, 12/12 varış. `test_fay_olcum.gd` artık
      sisli insan botunun da 12/12 varmasını sınıyor

### Deprem okunurluğu
- [x] **Üç satırlık pano** ekranın üst-ortasında: `DEPREM 7.3 sn` /
      `W ile YÜZEYE ÇIK → +196 ₺ ikramiye` / `DERİNDE KAL → 2 hasar`
      (dokunmatikte `▲ UÇ ile`); son 3 sn'de sayaç yanıp sönüyor
- [x] **Uyarı başlarken kırmızı ekran işareti** (0,5 sn sönen örtü) + iki katmanlı
      ses + sarsıntı. `yayin/ekran-4.png` ve `docs/deprem-telefon.png` ile doğrulandı

### Doğrulama ve paket
- [x] 220 birim + 68 oynanış sınaması, denge/insan/fay ölçümleri yeşil
- [x] Windows + Web dışa aktarımı, 5 ekran görüntüsü + kapak + GIF yenilendi
      (GIF sisle 1,6 MB → 0,9 MB), `yayin/` sürüm 0.5.0

## Geliştirme turu 5 — v0.6 "Derinliğin sesi, Derin Mod'un yüzü" (2026-09-21)

### Deprem seferi sahnede baştan sona
- [x] **Beş gerçek sefer** (12 m'den derine in, üsse dön) sayacı dolduruyor; uyarı
      yeraltına inince kendiliğinden başlıyor, pano ikramiyeyi yazıyor, geri sayım
      gerçekten akıyor (322 kare). Üç ayrı senaryo: **(a)** pervaneyle yüzeye çık →
      +49 ₺, hasar yok · **(b)** derinde kal → −1 can, ikramiye yok · **(c)**
      istasyondan ışınlan → +49 ₺, hasar yok, yalnız 5 yakıt
- [x] **(c) gerçek bir hata buldu:** üsse ışınlanan/çekilen araç (520, −24)'e
      konup kendi şaftına düşüyordu (v0.2'den beri; mağaza açılamıyor, deprem
      hasarı yiyor). `Arac.yuzey_konumu()` şaftın yanındaki ilk dolu sütuna iniyor

### Derinlik ambiyansı
- [x] **Dört bant** (`Ayarlar.AMBIYANS`): toprak → kaya → bazalt → çekirdek;
      bant = müzik + arka plan tonu + parçacık (toz / kıvılcım, araca bağlı,
      sisin altında). Kaya dokusu katman sınırında artık yumuşak geçiyor
- [x] **Müzik üreticiye 2. yeraltı ruhu `cekirdek`**: 68 bpm, frigyen, davul
      yerine kalp atışı, iki kat uzun notalar, dron bas. `muzik_bazalt` (gergin,
      160 bpm) ve `muzik_cekirdek` üretildi; toplam 4 bant parçası
- [x] **Crossfade**: `Ses` iki `AudioStreamPlayer`; `muzik_cal(ad, 1.6)` yeni
      parçayı ötekinde başlatıp ikisini çaprazlıyor, sınırda gidip gelince
      baştan başlamıyor; parçalar açılışta önyükleniyor (web'de takılma yok).
      Sahne testi geçiş sırasında 2, sonunda 1 oyuncu çaldığını sınıyor
- [x] **Müzik v0.2'den beri hiç ilerlemiyordu**: `loop_end = 0` ile oyuncu ilk
      karede duruyordu (sondayla ölçüldü: 6 sn `playing=false, pos=0.000`). Döngü
      sonu açıkça son örnek; artık akıyor

### Derin Mod kimliği
- [x] **Işık 3 karo** (`ISIK_YARICAP_DERIN`), **deprem 4 seferde bir**
      (`Deprem.ARALIK_DERIN`), **7. eser** "Uyanmış Kabuk Parçası" (ışık +1)
      yalnız Derin Mod'da ve ilk gizli odada; ilk oyunda müzede bile görünmez.
      Üçü `Durum.isik_yaricap / deprem_araligi / sonraki_eser` — sahne ve bot
      aynı yerden okuyor
- [x] **Kendi kayıt yuvası** `[derin]` (`Kayit.derin_mod_hazirla`): süren tur devam,
      biten tur x+1 yeni tohumla; ana dünya silinmiyor. Menüde sağ üstte rozet
      (`▼ DERİN MOD x1 ▼  7. eser yalnız burada / bulundu`), düğme "devam et"
      ya da "x2 — yeni tohum"
- [x] **Derin Mod x1 ölçümü** (`Bot.INSAN_DERIN`, 7 tohum, altı eserle): tur
      122 sn (ilk oyun 106), 10. dk 94 m, çekirdek 24 dk (ilk oyun 25), 7/7 varış,
      18 deprem; bant bekçileri eklendi

### Kayıt uyumu
- [x] **Gerçek v0.5 fikstürü** `tests/veri/kayit-v0.5.cfg`: v0.5 etiketi git
      worktree'de açılıp `tools/kayit_fikstur.gd` ile o sürümün kendisi yazdı.
      Birim testi Durum/Dunya'ya, oynanış testi gerçek sahneye yüklüyor:
      tüneller, keşif, para yerinde; ışık 5, deprem 5, 7. eser yok

### Doğrulama ve paket
- [x] 249 birim + 120 oynanış sınaması, denge/insan (Derin Mod dahil)/fay yeşil
- [x] Windows + Web dışa aktarımı, 6 ekran görüntüsü (yeni: Derin Mod dar ışık)
      + kapak, `yayin/` sürüm 0.6.0

## Geliştirme turu 6 — v0.7 "Yüzey, ara kareler, iki yeni ses, istatistik, işaret" (2026-09-21)

### Sunum
- [x] **Yüzey karosu**: 0. satırın toprağı ayrı atlastan (`yuzey.png`, 4 varyant,
      `Dunya.YUZEY_KAYNAK`): çimen bandı, kum sınırı, gökyüzüne açılan yaprak ve
      çukurlar — birleşim artık düz çizgi değil. Karo türü değişmedi (üretici,
      kazı, deprem, kayıt TOPRAK görür). `yayin/ekran-1.png`
- [x] **Araç ara kareleri**: `arac.png` 4 → 9 kare (bekle · 2 kazma · 3 palet · 3
      alev). Palet yolla döner (hız × süre / 3 px), yön `flip_h`; alev 12 kare/sn.
      Seçim saf (`Arac.animasyon_durumu / faz_ilerlet / kare_sec`), bot kareyi
      bilmez. Birim test zamanlayıcıyı (1 sn'de 12 / 14 / 24 değişim) ve kare
      aralıklarını, sahne testi yürürken/kazarken/uçarken gerçek kareyi sınıyor
- [x] **Matkap döngü sesi** (`matkap.wav`, 0,6 sn dikişsiz; `Ses.dongu_*`,
      `Arac.kazma_degisti`, 0,3 sn kuyruk) ve **depreme özel gürültü**
      (`deprem.wav`: vuruş + 15-60 Hz sarsıntı + çatırtı; uyarıda tiz/kısık) —
      patlama sesi artık yalnız gaz/dinamit/çekirdek. `tools/ses_uret.gd`
      deterministik (aynı tohum aynı baytlar, testli)
- [x] **Bitiş istatistiği**: kazılan karo, deprem, yüzeye çekilme, satış toplamı,
      süre — bu dünya + bütün dünyaların `[oyuncu]` toplamı (fark yöntemi, iki kez
      sayma yok). Panel 480 px'e sarılır, 536×296 (test 640×360'ı ölçüyor).
      `docs/bitis.png`
- [x] Dokunmatikte alet şeridi ve kazı alanı yazıları panel açıkken gizleniyor

### Oynanış
- [x] **Işınlama işareti**: `R` / gamepad B / İŞARET düğmesi (sol şeritte üçüncü,
      şerit y 100'e alındı) yeraltında tek kullanımlık dönüş noktası koyar;
      ışınlanma panelinde satır, asansör kuralı aynı (üsten/istasyondan), gidince
      silinir; deprem kapatmışsa varışta hücre açılır; mini haritada pembe. Eski
      kayıt işaretsiz açılır (v0.5 fikstürü). Bot bilmez — ölçüm v0.6 ile birebir
      (tur 106 sn, çekirdek 25 dk, Derin Mod 122 sn / 24 dk, fay 12/12)

### Doğrulama ve paket
- [x] 304 birim + 156 oynanış sınaması, denge/insan/fay yeşil ve değişmedi
- [x] Windows + Web dışa aktarımı (pck 1,83 MB), 6 ekran görüntüsü + kapak yenilendi
      (ekran-4: işaret + alev + pano), `docs/v07-kareler.png`, `yayin/` sürüm 0.7.0
- [x] Web çıktısı Playwright ile tarayıcıda açıldı (menü, konsol hatası yok) —
      ses ve oynanış tarayıcıda dinlenmedi (bkz. `yayin/butler-komutlari.md`)

## Sonraki tur

### Oynanış
- [ ] **Gerçek insan denemesi.** Ölçüm hâlâ bot; insan benzeri bot da bir varsayım.
      Sisle birlikte bu deneme daha da anlamlı: bot çekirdeğin sütununu biliyor,
      oyuncu koridoru karanlıkta bulmak zorunda. Bir oturum gerçekten oynanıp tur
      süresi ve çekirdeğe varış kaydedilmeli
- [ ] **Deprem kararının insanda karşılığı.** Pano artık okunuyor; gerçek oyuncu
      uyarıyı görüp ne yapıyor, ikramiye "geri dön" demeye yetiyor mu
- [ ] **Sisin oyuncuya bedeli.** Bot ölçümünde 0 çıktı (rota kurulmuyor); insan
      denemesinde "yolu bulamadım" olup olmadığı asıl soru. Gerekirse radar
      menzili ya da hatıra örtüsü (`SIS_HATIRA`) ayarlanır
- [x] **Derin Mod'da yeni içerik**, yalnız çarpan değil (v0.6: dar ışık, sık
      deprem, 7. eser, ayrı yuva). Sıradaki: 6. katman ya da Derin Mod'a özel
      tehlike
- [ ] **Müzik ve yeni sesler gerçekten dinlenmeli.** Döngü/crossfade ve v0.7'nin
      matkap döngüsü + deprem gürültüsü ölçümle doğrulandı (sonda, RMS, alçak
      frekans enerjisi) ama kulakla hiç dinlenmedi; matkap sesi 25 dk boyunca
      yormuyor mu, deprem gürültüsü patlamadan ayrışıyor mu — tohum ve karışım
      düzeyi `tools/ses_uret.gd` / `Ses.DONGU` içinde tek satır
- [x] Işınlama işareti (v0.7: tek kullanımlık, üsten/istasyondan, bot bilmez)
- [ ] **İşaretin insanda karşılığı.** Bot kullanmadığı için ölçümü yok: oyuncu
      işareti sandığa dönmek için mi, derin damara dönmek için mi kullanıyor, tur
      süresini kısaltıyor mu — insan denemesinde sor
- [ ] Günlük dünyada skor tablosu — çevrimdışı olduğu için yalnız kendi rekorun;
      `[oyuncu]` sayaçları artık var, günlük rekor aynı yöntemle eklenebilir

### Sunum
- [x] Yüzey karosu için ayrı "üst" görünümü (v0.7)
- [x] Araç animasyonuna pervane alevi ve palet dönüşü için ara kareler (v0.7)
- [x] Ses: matkap döngü sesi, depreme özel gürültü (v0.7)
- [x] Bitiş ekranına istatistik dökümü (v0.7; `[oyuncu]` toplamıyla)
- [ ] Yüzeyde araç için ayrı "yürüme tozu" ve pervane rüzgârı parçacığı (palet
      artık dönüyor, altındaki toprak hâlâ hareketsiz)
- [ ] Menüde `[oyuncu]` toplamı (bitiş ekranı dışında da görünsün)

### Dağıtım
- [x] Web çıktısı v0.4 ile tarayıcıda doğrulandı (yönetici: menü, kazı, dokunmatik
      ipucu, konsolda hata yok)
- [x] Web çıktısı v0.5 ile tarayıcıda doğrulandı (yönetici: sis, alet düğmeleri,
      deprem panosu; deprem 5. sefere kadar beklenmedi — v0.6 sahne testi kapattı)
- [x] Web çıktısı v0.6 ile tarayıcıda doğrulandı (yönetici, bulut: menü, kazı,
      derinlik bandı, duraklatma, telefon emülasyonu; ses ölçülmedi)
- [x] Web çıktısı v0.7 Playwright ile açıldı (bu oturum: menü, konsol hatası yok)
- [ ] Web çıktısını v0.7 ile tarayıcıda **sesi açık** doğrula: matkap döngüsü
      kazarken çalıp durunca sönüyor mu (web'de loop), deprem gürültüsü, R/İŞARET
      akışı, bitiş paneli, eski tarayıcı kaydı — `yayin/butler-komutlari.md`
- [ ] itch.io sayfası ve yükleme — **Furki'nin onayı gerekiyor**
- [x] GitHub deposu ve push (21 Eylül 2026: `Furkiozknn/derin-kazi`, public, `main`,
      MIT lisans, her push'ta CI, v0.7.2 Release)

## v0.8 adayları (dondurulan tur dosyasından taşındı)

- [ ] **Derin Mod'a özel tehlike — gaz cebi:** yalnız Derin Mod'da, 3. bandın altında
      kazınca açılan cep; 2 sn içinde uzaklaşılmazsa 1 can, radar gösterir, dinamit patlatır
- [ ] **Sisli bot koridoru kendi bulsun:** `cekirdek_x` bilgisi kaldırılsın, 7 tohumda varış
      süresi ve "yolu bulamadı" sayısı ölçülsün (sisin ölçüme bedeli bugün 0)
- [ ] Yüzeyde araç için palet tozu ve pervane rüzgârı parçacığı
- [ ] Menüde `[oyuncu]` toplamı (kazılan karo / deprem / satış)
- [ ] Günlük dünyada günlük rekor (bitiş panelinde "bugünün rekoru")

## Bitti — v0.7.1 / v0.7.2: depo hijyeni ve yayın paketi (2026-09-21/22)

- [x] MIT `LICENSE`
- [x] GitHub deposu **public** (`Furkiozknn/derin-kazi`, dal `main`), `v0.7.2` etiketi ve Release
- [x] GitHub Actions: 304 birim + 156 oynanış testi her `main` push'unda ve her PR'da (Godot 4.7.2 sabit,
      Git LFS çekilerek); README'de rozet
- [x] `*.gif` Git LFS'e alındı (`.gitattributes` kuralı artık gerçekten tutuyor)
- [x] Makineye özel yollar belgelerden ve betiklerden çıkarıldı
- [x] İki tur bağımsız belge denetimi: bazalt müziğinin üretim komutu (`--bpm 160`), deprem oranı %22,
      sisli botun BFS hakkı, fay ölçümü 12/12, istasyonun 40 m sınırı; kazı zinciri,
      sandık ödülleri ve düşme hasarı ilk kez belgelendi
- [x] **Yayın paketi %46 küçüldü**: `exclude_filter` boştu, oyuncuya inen pakete `yayin/`,
      `docs/`, `tests/`, `tools/` ve `_eski/` giriyordu. Web pck 1.782.396 → 968.680 bayt;
      paket dosya tablosu okunarak doğrulandı
- [x] `LISANS-simgeler.txt` README'de atıf alıyor

## Bilinen sınırlar

- **Ölçüm hâlâ bot.** İnsan benzeri bot duraksama ve yanlış rota ekliyor ama
  ölmüyor, yüzeye çekilmiyor, düşen kayadan kaçınmıyor, müzeyi okumuyor,
  depremi beklemiyor. Gerçek oyuncu bu sayılardan yavaş oynar.
- **Oturum uzunluğu rakip analizindeki hedefin altında** (23 dk ≠ 60-90 dk).
  Bu bilerek verilmiş bir karar, README "Verilen kararlar" başlığında gerekçesi var.
- **Deprem yalnız yeraltındayken tetikleniyor** (15 m'den derinde). Üste dönüp
  hiç inmeyen bir oyuncu depremi hiç görmez — bilerek: uyarının anlamı yeraltında.
- **Bot artık depremi yaşıyor ama mükemmel karar veriyor**: tırmanış süresini
  tam biliyor, uyarıyı kaçırmıyor. Gerçek oyuncu bazen geç fark eder.
- **Sisli bot yol bulurken yalnız keşfedileni biliyor ama çekirdeğin sütununu
  (`cekirdek_x`) hâlâ biliyor** ve 238 m'den sonra ona yanaşıyor. Oyuncu bunu
  koridorun yumuşak kayasını izleyerek bulur; bot için bu bilgi olmasa ölçüm
  "koridoru bulma" becerisini de ölçerdi — bir sonraki turun sorusu.
- **Sisin bot ölçümüne bedeli 0**: 7 tohumda BFS rotası hiç kurulmuyor. Yani sis
  botun oynayışını değiştirmiyor; oyuncununkini değiştirip değiştirmediği insan
  denemesine kaldı.
- Düşen kaya yere çarpınca yok oluyor, yeni karo bırakmıyor (bilerek).

