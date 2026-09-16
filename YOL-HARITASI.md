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

## Sonraki tur

### Oynanış
- [ ] **Gerçek insan denemesi.** Ölçüm hâlâ bot; insan benzeri bot da bir varsayım.
      Bir oturum gerçekten oynanıp tur süresi ve çekirdeğe varış kaydedilmeli
- [ ] **Botun yol bulması.** Tohum 3'te tıkanıyor: yan tarama sınırı 120 deneme
      ve galeri taraması kör. Bot aracın gerçek imkânlarını (dinamit, radar,
      mini harita) kullanmadığı için ölçüm kötümser tarafta kalıyor
- [ ] **Depremin oynanışa bağlanması.** Şu an saf bir olay: uyarı + değişim.
      "Depremden önce yüzeye çık, yoksa çekme ücreti iki katı" gibi bir bahis
      eklenirse gerilim oluşur
- [ ] **Derin Mod'da yeni içerik**, yalnız çarpan değil: 6. katman, yeni tehlike
      ya da eser seti
- [ ] Işınlama işareti (istasyon dışı, tek kullanımlık dönüş noktası)
- [ ] Günlük dünyada skor tablosu — çevrimdışı olduğu için yalnız kendi rekorun

### Sunum
- [ ] Yüzey karosu için ayrı "üst" görünümü (şu an toprak her yerde aynı)
- [ ] Maden damarlarının zemini toprakta hâlâ mavi-gri bir kare gibi duruyor;
      katmana göre yumuşak bir geçiş denenmeli
- [ ] Araç animasyonuna pervane alevi ve palet dönüşü için ara kareler
- [ ] Ses: matkap döngü sesi, depreme özel gürültü (şu an patlama sesi kullanılıyor)
- [ ] Bitiş ekranına istatistik dökümü (kazılan karo, deprem sayısı, ölüm sayısı)

### Dağıtım
- [ ] Web çıktısını v0.3 ile tarayıcıda yeniden doğrula (simgeler ve menü arka planı)
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
- **Bot depremi simüle etmiyor**, yani denge ölçümleri depremin getirdiği ek
  kazma süresini saymıyor. Gerçek tur bir miktar daha uzun.
- **Bot 12 tohumun 1'inde (tohum 3) fay hattına rağmen çekirdeğe varamıyor.**
  BFS o tohumda da yol olduğunu söylüyor, yani dünya değil botun yol bulması
  yetersiz — bot mini haritayı okumuyor, dinamit kullanmıyor, radar takip
  etmiyor. Ölçüm tohumlarında (test_denge 3, test_insan 7) böyle bir tohum yok.
- Düşen kaya yere çarpınca yok oluyor, yeni karo bırakmıyor (bilerek).
- Web çıktısı v0.3 ile tarayıcıda denenmedi (bu oturumda sunucu kurulmadı);
  simge ve menü düzeltmeleri headless test + ekran görüntüsüyle doğrulandı.
