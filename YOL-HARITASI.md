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
- [x] **Önceden uyarılan tehlikeler**: gaz cebi (parlak yeşil kabarcık), düşen
      kaya (0,5 sn titreyip düşer), lav (ısı kalkanı ister)
- [x] **Araç canı** + gövde zırhı geliştirmesi, düşme hasarı
- [x] **Mağara ve gizli odalar**: chunk başına olasılıkla sandık ya da eser odası
- [x] **Müze**: 6 eser, her biri kalıcı pasif bonus
- [x] **Alet = yeni hareket**: dinamit (3×3), maden radarı
- [x] **Kazı zinciri**: art arda aynı maden → çarpan + yükselen ses perdesi
- [x] **Final**: çekirdeğe dokununca tüm aletler açılır, yakıt sayaçlı kaçış
- [x] **Mini harita**: keşfedilmemiş alan kapalı, istasyon ve sandık işaretli
- [x] **Mobil**: ekranın sol/sağ/alt bölgesine dokunma + büyük pervane düğmesi

### Sunum
- [x] **Gerçek pixel art**, tamamı kodla üretiliyor (`tools/sprite_uret.gd`,
      Endesga 32 paleti): 17 karo, araç animasyonları, üs kasabası, 3 parallaks
      katmanı, 9 arayüz simgesi, istasyon, logo
- [x] **Ses**: 7 rFXGen ön ayarı + perde eşlemesiyle 11 olay, 3 müzik döngüsü
      (menü / sığ / derin) + bitiş jingle'ı, `Muzik` ve `Efekt` veri yolları
- [x] **Ayarlar ekranı**: müzik/efekt düzeyi ve aç-kapa, tam ekran, ekran
      sarsıntısı — `user://kayit.cfg` `[ayar]` bölümünde
- [x] **Oyun hissi**: kırılma tozu, uçan "+₺", ekran sarsıntısı, esneme-sıkışma,
      kararmalı sahne geçişi
- [x] Ortak panel stili, HUD yazılarında koyu dış hat, panel açıkken HUD gizleniyor
- [x] Kamera 2× (prototipteki "çevre görüşü dar" notu için temel görüntü 640×360)

### Doğrulama ve paket
- [x] 121 birim + 31 oynanış sınaması + bot denge simülasyonu
- [x] Yüzeyden çekirdeğe kazılabilir yol testi (BFS) — dünya her tohumda bitirilebilir
- [x] Windows + Web dışa aktarımı, web artık `thread_support` kapalı
- [x] `yayin/`: itch sayfası (EN + TR), 4 ekran görüntüsü, 630×500 kapak,
      butler komutları (çalıştırılmadı)
- [x] `CLAUDE.md`

## Sonraki tur

### Oynanış
- [ ] **İnsan denemesi.** Denge yalnız botla ölçüldü; bot en kısa yolu seçer ve
      duraksamaz. Gerçek bir oturumda tur süresi ve çekirdeğe varış ölçülmeli.
- [ ] **Canlı yeraltı** (rakip analizi): her 5 turda deprem — eski tünellerin bir
      kısmı kapanır, yeni gaz cepleri ve damarlar çıkar
- [ ] **Derin Mod**: çekirdekten sonra yeni tohum + zorlaştırıcılar, eser
      bonusları kalır
- [ ] **Günlük tohum** (tarihten türetilir) ve paylaşılabilir tohum kodu
- [ ] Eserlerin parça parça çekirdeğin hikâyesini anlatması (şu an yalnız bonus)
- [ ] Işınlama işareti (istasyon dışı, tek kullanımlık dönüş noktası)

### Sunum
- [ ] Karo çeşitliliği: aynı 16 px karo ekranda tekrarlıyor; TileSet alternatif
      karolarıyla 2-3 varyant
- [ ] Yüzey karosu için ayrı "üst" görünümü (şu an toprak her yerde aynı)
- [ ] Araç animasyonuna pervane alevi ve palet dönüşü için ara kareler
- [ ] Ses: matkap döngü sesi (şu an her karoda tek vuruş)
- [ ] Bitiş ekranına istatistik dökümü (kazılan karo, toplanan maden, ölüm sayısı)

### Dağıtım
- [ ] Web çıktısını gerçekten tarayıcıda oynayarak doğrula (statik sunucuda açılır)
- [ ] itch.io sayfası ve yükleme — **Furki'nin onayı gerekiyor**
- [ ] GitHub deposu ve push — **Furki'nin onayı gerekiyor**

## Bilinen sınırlar

- **Denge botla ölçüldü, insanla değil.** `tests/test_denge.gd` tur süresini
  60-200 sn bandında tutuyor; insanın aynı turu 1,5-2 kat uzun oynadığı
  varsayımıyla bu 2-4 dk demek. Varsayım doğrulanmadı.
- Botun çekirdeğe varış süresi yol bulmasına çok bağlı: 3 tohumun 2'sinde
  10. turda ulaşıyor, birinde 400 turda ulaşamıyor. Ölçülen şey ekonominin
  eğrisi; "çekirdeğe kaç dakikada varılır" sorusu insan denemesi ister.
- Aynı karo dokusu ekranda tekrarlıyor; uzaktan bakınca desen fark ediliyor.
- Düşen kaya yere çarpınca yok oluyor, yeni karo bırakmıyor (bilerek: kazı
  farkını ve chunk yeniden yüklemesini karmaşıklaştırıyordu).
