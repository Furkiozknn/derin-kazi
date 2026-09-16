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

## Sonraki tur

### Oynanış
- [ ] **Gerçek insan denemesi.** Ölçüm hâlâ bot; insan benzeri bot da bir varsayım.
      Bir oturum gerçekten oynanıp tur süresi ve çekirdeğe varış kaydedilmeli
- [ ] **Dokunmatikte dinamit ve radar.** İpuçları artık düğmeleri anlatıyor ama
      telefonda dinamit atmanın ve radarı açmanın hiçbir yolu yok (F ve Q tuşları
      orada yok). Sağ üstteki düğme şeridi 640 px'e sığmadığı için bu tura
      alınmadı — düzen değişikliği gerekiyor
- [ ] **Deprem kararının insanda karşılığı.** Ölçümde bahsi bot veriyor; gerçek
      oyuncu uyarıyı görüp ne yapıyor, ikramiye "geri dön" demeye yetiyor mu
- [ ] **Derin Mod'da yeni içerik**, yalnız çarpan değil: 6. katman, yeni tehlike
      ya da eser seti
- [ ] Işınlama işareti (istasyon dışı, tek kullanımlık dönüş noktası)
- [ ] Günlük dünyada skor tablosu — çevrimdışı olduğu için yalnız kendi rekorun

### Sunum
- [ ] Yüzey karosu için ayrı "üst" görünümü (şu an toprak her yerde aynı)
- [ ] Araç animasyonuna pervane alevi ve palet dönüşü için ara kareler
- [ ] Ses: matkap döngü sesi, depreme özel gürültü (şu an patlama sesi kullanılıyor)
- [ ] Bitiş ekranına istatistik dökümü (kazılan karo, deprem sayısı, ölüm sayısı)

### Dağıtım
- [ ] Web çıktısını v0.4 ile tarayıcıda doğrula (dokunmatik ipuçları, deprem
      geri sayımı, maden zemini)
- [ ] itch.io sayfası ve yükleme — **Furki'nin onayı gerekiyor**
- [ ] GitHub deposu ve push — **Furki'nin onayı gerekiyor**

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
- **Botun BFS'i oyuncunun bilgisinden fazlasını görüyor**: mini haritada
  keşfedilmemiş alan oyuncuya kapalı, bota değil. Ölçtüğü şey "oyun
  bitirilebilir mi", "oyuncu yolu bulabilir mi" değil.
- Düşen kaya yere çarpınca yok oluyor, yeni karo bırakmıyor (bilerek).
- Web çıktısı v0.4 ile tarayıcıda denenmedi (bu oturumda sunucu kurulmadı);
  dokunmatik ipuçları headless test + sahne sınamasıyla doğrulandı.
- **Deprem yalnız ilk 15 m'nin altında tetikleniyor**, yani hiç derine inmeyen
  bir oyuncu ikramiyeyi de riski de görmez (bilerek).
